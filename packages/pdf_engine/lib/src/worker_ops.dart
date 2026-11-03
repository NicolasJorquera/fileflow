// Code that runs inside pdfrx's worker isolate. Every PDFium call happens here,
// serialized with pdfrx's own rendering. Documents and loaded pages live in a
// registry between tasks; only ids cross isolates.
//
// Rules: functions are synchronous, short (one page or one image) and report
// expected problems by throwing [EngineException], which [guard] turns into
// data before the result leaves the worker.
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart' as fp;
import 'package:pdfrx_engine/pdfrx_engine.dart';

import 'engine_result.dart';
import 'models.dart';

class EngineException implements Exception {
  EngineException(this.code, [this.message = '']);

  final EngineErrorCode code;
  final String message;
}

/// Envelope sent back from the worker: ([value], -1, '') on success or
/// (null, code index, message) on failure.
typedef Guarded<T> = (T?, int, String);

Guarded<T> guard<M, T>(T Function(M message) op, M message) {
  try {
    return (op(message), -1, '');
  } on EngineException catch (e) {
    return (null, e.code.index, e.message);
  } catch (e) {
    return (null, EngineErrorCode.internal.index, e.runtimeType.toString());
  }
}

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

fp.PDFium? _bindings;
fp.PDFium get _pdfium => _bindings ??= fp.getPdfium(modulePath: Pdfrx.pdfiumModulePath);

final _docs = <int, fp.FPDF_DOCUMENT>{};
final _pages = <(int, int), fp.FPDF_PAGE>{};
var _nextId = 1;

fp.FPDF_DOCUMENT _doc(int id) => _docs[id] ?? (throw EngineException(EngineErrorCode.invalidHandle, 'doc $id'));

fp.FPDF_PAGE _page(int doc, int index) {
  final cached = _pages[(doc, index)];
  if (cached != null) return cached;
  final page = _pdfium.FPDF_LoadPage(_doc(doc), index);
  if (page == nullptr) throw EngineException(EngineErrorCode.pageUnreadable, 'page $index');
  return _pages[(doc, index)] = page;
}

void _unloadPage(int doc, int index) {
  final page = _pages.remove((doc, index));
  if (page != null) _pdfium.FPDF_ClosePage(page);
}

/// Number of documents and pages currently open; used by tests to detect leaks.
(int, int) wOpenCounts(void _) => (_docs.length, _pages.length);

// ---------------------------------------------------------------------------
// Documents
// ---------------------------------------------------------------------------

DocHandle wOpen(String path) {
  final doc = using((arena) {
    final d = _pdfium.FPDF_LoadDocument(path.toNativeUtf8(allocator: arena).cast(), nullptr);
    if (d == nullptr) throw _openError(_pdfium.FPDF_GetLastError());
    return d;
  });
  final id = _nextId++;
  _docs[id] = doc;
  return DocHandle(id, _pdfium.FPDF_GetPageCount(doc));
}

EngineException _openError(int code) => switch (code) {
  fp.FPDF_ERR_FILE => EngineException(EngineErrorCode.io),
  fp.FPDF_ERR_PASSWORD => EngineException(EngineErrorCode.passwordRequired),
  fp.FPDF_ERR_SECURITY => EngineException(EngineErrorCode.unsupportedSecurity),
  _ => EngineException(EngineErrorCode.damaged, 'FPDF_ERR $code'),
};

DocHandle wCreateEmpty(void _) {
  final id = _nextId++;
  _docs[id] = _pdfium.FPDF_CreateNewDocument();
  return DocHandle(id, 0);
}

void wClose(int doc) {
  for (final key in _pages.keys.where((k) => k.$1 == doc).toList()) {
    _unloadPage(key.$1, key.$2);
  }
  final handle = _docs.remove(doc);
  if (handle != null) _pdfium.FPDF_CloseDocument(handle);
}

PdfInfo wInspect((String, int) args) {
  final (path, maxPages) = args;
  final handle = wOpen(path);
  try {
    final scan = handle.pageCount < maxPages ? handle.pageCount : maxPages;
    var images = 0;
    for (var i = 0; i < scan; i++) {
      final page = _page(handle.id, i);
      final count = _pdfium.FPDFPage_CountObjects(page);
      for (var k = 0; k < count; k++) {
        if (_pdfium.FPDFPageObj_GetType(_pdfium.FPDFPage_GetObject(page, k)) == fp.FPDF_PAGEOBJ_IMAGE) images++;
      }
      _unloadPage(handle.id, i);
    }
    return PdfInfo(pageCount: handle.pageCount, pagesScanned: scan, imagesOnScannedPages: images);
  } finally {
    wClose(handle.id);
  }
}

int wImportPages((int, int, List<int>?, int) args) {
  final (dest, src, pages, at) = args;
  return using((arena) {
    Pointer<Int> indices = nullptr;
    if (pages != null) {
      indices = arena<Int>(pages.length);
      for (var i = 0; i < pages.length; i++) {
        indices[i] = pages[i];
      }
    }
    if (_pdfium.FPDF_ImportPagesByIndex(_doc(dest), _doc(src), indices, pages?.length ?? 0, at) == 0) {
      throw EngineException(EngineErrorCode.damaged, 'import failed');
    }
    return _pdfium.FPDF_GetPageCount(_doc(dest));
  });
}

void wRotatePage((int, int, int) args) {
  final (doc, index, quarterTurns) = args;
  final page = _page(doc, index);
  _pdfium.FPDFPage_SetRotation(page, (_pdfium.FPDFPage_GetRotation(page) + quarterTurns) % 4);
  _unloadPage(doc, index);
}

void wDeletePage((int, int) args) {
  final (doc, index) = args;
  _unloadPage(doc, index);
  _pdfium.FPDFPage_Delete(_doc(doc), index);
}

void wAddJpegPage((int, TransferableTypedData, double, double, double) args) {
  final (doc, data, pageW, pageH, margin) = args;
  final jpeg = data.materialize().asUint8List();
  final size = _jpegSize(jpeg) ?? (throw EngineException(EngineErrorCode.imageUnsupported, 'not a JPEG'));
  final d = _doc(doc);
  final index = _pdfium.FPDF_GetPageCount(d);
  final page = _pdfium.FPDFPage_New(d, index, pageW, pageH);
  try {
    using((arena) {
      final image = _pdfium.FPDFPageObj_NewImageObj(d);
      final pages = arena<fp.FPDF_PAGE>()..value = page;
      if (!_loadJpegInline(pages, image, jpeg, arena)) {
        _pdfium.FPDFPageObj_Destroy(image);
        throw EngineException(EngineErrorCode.imageUnsupported, 'jpeg load failed');
      }
      final boxW = pageW - 2 * margin, boxH = pageH - 2 * margin;
      final fit = (boxW / size.$1) < (boxH / size.$2) ? boxW / size.$1 : boxH / size.$2;
      final w = size.$1 * fit, h = size.$2 * fit;
      _pdfium.FPDFImageObj_SetMatrix(image, w, 0, 0, h, (pageW - w) / 2, (pageH - h) / 2);
      _pdfium.FPDFPage_InsertObject(page, image);
      _pdfium.FPDFPage_GenerateContent(page);
    });
  } finally {
    _pdfium.FPDF_ClosePage(page);
  }
}

/// Width and height from a JPEG's SOF marker, or null if it is not a JPEG.
(int, int)? _jpegSize(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
  var i = 2;
  while (i + 9 < b.length) {
    if (b[i] != 0xFF) return null;
    final marker = b[i + 1];
    final len = (b[i + 2] << 8) | b[i + 3];
    if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
      return ((b[i + 7] << 8) | b[i + 8], (b[i + 5] << 8) | b[i + 6]);
    }
    i += 2 + len;
  }
  return null;
}

void wSave((int, String) args) {
  final (doc, outPath) = args;
  final file = File(outPath);
  final RandomAccessFile raf;
  try {
    raf = file.openSync(mode: FileMode.write);
  } on FileSystemException catch (e) {
    throw EngineException(EngineErrorCode.writeFailed, 'cannot create output (os error ${e.osError?.errorCode})');
  }
  var ioError = false;
  int writeBlock(Pointer<fp.FPDF_FILEWRITE_> self, Pointer<Void> data, int size) {
    try {
      raf.writeFromSync(data.cast<Uint8>().asTypedList(size));
      return 1;
    } catch (_) {
      ioError = true;
      return 0;
    }
  }

  final callable = NativeCallable<Int Function(Pointer<fp.FPDF_FILEWRITE_>, Pointer<Void>, UnsignedLong)>.isolateLocal(
    writeBlock,
    exceptionalReturn: 0,
  );
  var ok = false;
  try {
    ok = using((arena) {
      final fw = arena<fp.FPDF_FILEWRITE_>();
      fw.ref.version = 1;
      fw.ref.WriteBlock = callable.nativeFunction;
      const noIncremental = 2;
      return _pdfium.FPDF_SaveAsCopy(_doc(doc), fw, noIncremental) != 0;
    });
  } finally {
    callable.close();
    raf.closeSync();
    if (!ok || ioError) {
      if (file.existsSync()) file.deleteSync();
    }
  }
  if (!ok || ioError) {
    throw EngineException(EngineErrorCode.writeFailed, ioError ? 'io error while writing' : 'save failed');
  }
}

// ---------------------------------------------------------------------------
// Pages and images
// ---------------------------------------------------------------------------

List<ImageSlot> wImagesOnPage((int, int) args) {
  final (doc, index) = args;
  final page = _page(doc, index);
  return using((arena) {
    final pw = arena<UnsignedInt>(), ph = arena<UnsignedInt>();
    final l = arena<Float>(), b = arena<Float>(), r = arena<Float>(), t = arena<Float>();
    final slots = <ImageSlot>[];
    final count = _pdfium.FPDFPage_CountObjects(page);
    for (var k = 0; k < count; k++) {
      final obj = _pdfium.FPDFPage_GetObject(page, k);
      if (_pdfium.FPDFPageObj_GetType(obj) != fp.FPDF_PAGEOBJ_IMAGE) continue;
      if (_pdfium.FPDFImageObj_GetImagePixelSize(obj, pw, ph) == 0 ||
          _pdfium.FPDFPageObj_GetBounds(obj, l, b, r, t) == 0) {
        continue;
      }
      final inches = (r.value - l.value) / 72.0;
      if (inches <= 0) continue;
      slots.add(
        ImageSlot(
          objectIndex: k,
          pixelWidth: pw.value,
          pixelHeight: ph.value,
          effectiveDpi: pw.value / inches,
          isJpeg: _filters(obj, arena).contains('DCTDecode'),
          hasTransparency: _hasTransparency(_doc(doc), page, obj),
        ),
      );
    }
    return slots;
  });
}

void wFinishPage((int, int, bool) args) {
  final (doc, index, changed) = args;
  final page = _pages[(doc, index)];
  if (page == null) return;
  if (changed) _pdfium.FPDFPage_GenerateContent(page);
  _unloadPage(doc, index);
}

/// Reusable output buffer: one allocation for the whole job instead of one per
/// image (spike S7 measured +451 MB of transient garbage on a 2 GB device).
Uint8List _scratch = Uint8List(0);

RgbaImage wExtractImage((int, int, int, double) args) {
  final (doc, index, objectIndex, scale) = args;
  final obj = _pdfium.FPDFPage_GetObject(_page(doc, index), objectIndex);
  final bitmap = _pdfium.FPDFImageObj_GetBitmap(obj);
  if (bitmap == nullptr) throw EngineException(EngineErrorCode.imageUnsupported, 'no bitmap');
  try {
    final w = _pdfium.FPDFBitmap_GetWidth(bitmap), h = _pdfium.FPDFBitmap_GetHeight(bitmap);
    final stride = _pdfium.FPDFBitmap_GetStride(bitmap);
    final bpp = switch (_pdfium.FPDFBitmap_GetFormat(bitmap)) {
      fp.FPDFBitmap_Gray => 1,
      fp.FPDFBitmap_BGR => 3,
      fp.FPDFBitmap_BGRx || fp.FPDFBitmap_BGRA => 4,
      _ => throw EngineException(EngineErrorCode.imageUnsupported, 'bitmap format'),
    };
    final src = _pdfium.FPDFBitmap_GetBuffer(bitmap).cast<Uint8>().asTypedList(stride * h);
    final k = scale >= 1 ? 1 : (1 / scale).floor().clamp(1, 16);
    final w2 = w ~/ k, h2 = h ~/ k, area = k * k;
    final length = w2 * h2 * 4;
    if (_scratch.length < length) _scratch = Uint8List(length);
    final out = _scratch;
    var o = 0;
    for (var y2 = 0; y2 < h2; y2++) {
      final y0 = y2 * k;
      for (var x2 = 0; x2 < w2; x2++) {
        var rr = 0, gg = 0, bb = 0;
        final x0 = x2 * k * bpp;
        for (var dy = 0; dy < k; dy++) {
          var p = (y0 + dy) * stride + x0;
          for (var dx = 0; dx < k; dx++, p += bpp) {
            if (bpp == 1) {
              final v = src[p];
              rr += v;
              gg += v;
              bb += v;
            } else {
              bb += src[p];
              gg += src[p + 1];
              rr += src[p + 2];
            }
          }
        }
        out[o] = rr ~/ area;
        out[o + 1] = gg ~/ area;
        out[o + 2] = bb ~/ area;
        out[o + 3] = 255;
        o += 4;
      }
    }
    return RgbaImage(
      width: w2,
      height: h2,
      targetWidth: scale >= 1 ? w2 : (w * scale).round().clamp(1, w2),
      targetHeight: scale >= 1 ? h2 : (h * scale).round().clamp(1, h2),
      pixels: TransferableTypedData.fromList([Uint8List.sublistView(out, 0, length)]),
    );
  } finally {
    _pdfium.FPDFBitmap_Destroy(bitmap);
  }
}

bool wReplaceImage((int, int, int, TransferableTypedData) args) {
  final (doc, index, objectIndex, data) = args;
  final page = _page(doc, index);
  final jpeg = data.materialize().asUint8List();
  return using((arena) {
    final pages = arena<fp.FPDF_PAGE>()..value = page;
    return _loadJpegInline(pages, _pdfium.FPDFPage_GetObject(page, objectIndex), jpeg, arena);
  });
}

RenderedPage wRender((int, int, int) args) {
  final (doc, index, widthPx) = args;
  final page = _page(doc, index);
  try {
    final pw = _pdfium.FPDF_GetPageWidthF(page), ph = _pdfium.FPDF_GetPageHeightF(page);
    final heightPx = (widthPx * ph / pw).round().clamp(1, 20000);
    final bitmap = _pdfium.FPDFBitmap_CreateEx(widthPx, heightPx, fp.FPDFBitmap_BGRA, nullptr, 0);
    if (bitmap == nullptr) throw EngineException(EngineErrorCode.internal, 'bitmap alloc');
    try {
      _pdfium.FPDFBitmap_FillRect(bitmap, 0, 0, widthPx, heightPx, 0xFFFFFFFF);
      const annotations = 0x01;
      _pdfium.FPDF_RenderPageBitmap(bitmap, page, 0, 0, widthPx, heightPx, 0, annotations);
      final stride = _pdfium.FPDFBitmap_GetStride(bitmap);
      final bytes = _pdfium.FPDFBitmap_GetBuffer(bitmap).cast<Uint8>().asTypedList(stride * heightPx);
      final packed = Uint8List(widthPx * heightPx * 4);
      for (var y = 0; y < heightPx; y++) {
        packed.setRange(y * widthPx * 4, (y + 1) * widthPx * 4, bytes, y * stride);
      }
      return RenderedPage(width: widthPx, height: heightPx, pixels: TransferableTypedData.fromList([packed]));
    } finally {
      _pdfium.FPDFBitmap_Destroy(bitmap);
    }
  } finally {
    _unloadPage(doc, index);
  }
}

/// Test hook: throws a non-engine error inside the worker.
void wDebugThrow(void _) => throw StateError('debug throw inside worker');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _loadJpegInline(Pointer<fp.FPDF_PAGE> pages, fp.FPDF_PAGEOBJECT obj, Uint8List jpeg, Arena arena) {
  int getBlock(Pointer<Void> param, int position, Pointer<UnsignedChar> buf, int size) {
    buf.cast<Uint8>().asTypedList(size).setRange(0, size, jpeg, position);
    return 1;
  }

  final callable =
      NativeCallable<Int Function(Pointer<Void>, UnsignedLong, Pointer<UnsignedChar>, UnsignedLong)>.isolateLocal(
        getBlock,
        exceptionalReturn: 0,
      );
  try {
    final fa = arena<fp.FPDF_FILEACCESS>();
    fa.ref.m_FileLen = jpeg.length;
    fa.ref.m_GetBlock = callable.nativeFunction;
    fa.ref.m_Param = nullptr;
    return _pdfium.FPDFImageObj_LoadJpegFileInline(pages, 1, obj, fa) != 0;
  } finally {
    callable.close();
  }
}

List<String> _filters(fp.FPDF_PAGEOBJECT obj, Arena arena) {
  final n = _pdfium.FPDFImageObj_GetImageFilterCount(obj);
  final buf = arena<Uint8>(64);
  return [
    for (var i = 0; i < n; i++)
      String.fromCharCodes(
        buf.asTypedList(_pdfium.FPDFImageObj_GetImageFilter(obj, i, buf.cast(), 64).clamp(1, 64) - 1),
      ),
  ];
}

bool _hasTransparency(fp.FPDF_DOCUMENT doc, fp.FPDF_PAGE page, fp.FPDF_PAGEOBJECT obj) {
  final rendered = _pdfium.FPDFImageObj_GetRenderedBitmap(doc, page, obj);
  if (rendered == nullptr) return true; // be conservative: skip it
  try {
    if (_pdfium.FPDFBitmap_GetFormat(rendered) != fp.FPDFBitmap_BGRA) return false;
    final w = _pdfium.FPDFBitmap_GetWidth(rendered), h = _pdfium.FPDFBitmap_GetHeight(rendered);
    final stride = _pdfium.FPDFBitmap_GetStride(rendered);
    final px = _pdfium.FPDFBitmap_GetBuffer(rendered).cast<Uint8>().asTypedList(stride * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (px[y * stride + x * 4 + 3] != 255) return true;
      }
    }
    return false;
  } finally {
    _pdfium.FPDFBitmap_Destroy(rendered);
  }
}
