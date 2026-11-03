import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

import 'engine_result.dart';
import 'models.dart';
import 'pdf_engine.dart';
import 'worker_ops.dart';

/// [PdfEngine] on PDFium through pdfrx's worker isolate.
///
/// The host initializes pdfrx first: `pdfrxFlutterInitialize()` in the app,
/// [initializeForDart] in tests and tools.
class PdfiumEngine implements PdfEngine {
  const PdfiumEngine();

  /// Initializes pdfrx for pure-Dart use (tests, CLI tools).
  static Future<void> initializeForDart() => pdfrxInitialize();

  Future<EngineResult<T>> _run<M, T>(T Function(M message) op, M message) async {
    final (value, code, text) = await PdfrxEntryFunctions.instance.compute((M m) => guard(op, m), message);
    if (code < 0) return EngineOk(value as T);
    return EngineErr(EngineFailure(EngineErrorCode.values[code], text));
  }

  @override
  Future<EngineResult<PdfInfo>> inspect(String path, {int maxPagesToScan = 30}) =>
      _run(wInspect, (path, maxPagesToScan));

  @override
  Future<EngineResult<DocHandle>> open(String path) => _run(wOpen, path);

  @override
  Future<EngineResult<DocHandle>> createEmpty() => _run(wCreateEmpty, null);

  @override
  Future<void> close(DocHandle doc) => _run(wClose, doc.id);

  @override
  Future<EngineResult<int>> importPages(DocHandle dest, DocHandle src, {List<int>? pages, required int at}) =>
      _run(wImportPages, (dest.id, src.id, pages, at));

  @override
  Future<EngineResult<void>> rotatePage(DocHandle doc, int page, int quarterTurns) =>
      _run(wRotatePage, (doc.id, page, quarterTurns));

  @override
  Future<EngineResult<void>> deletePage(DocHandle doc, int page) => _run(wDeletePage, (doc.id, page));

  @override
  Future<EngineResult<void>> addJpegPage(DocHandle doc, TransferableTypedData jpeg, PageLayout layout) =>
      _run(wAddJpegPage, (doc.id, jpeg, layout.pageWidth, layout.pageHeight, layout.margin));

  @override
  Future<EngineResult<List<ImageSlot>>> imagesOnPage(DocHandle doc, int page) => _run(wImagesOnPage, (doc.id, page));

  @override
  Future<EngineResult<RgbaImage>> extractImage(DocHandle doc, int page, int objectIndex, double scale) =>
      _run(wExtractImage, (doc.id, page, objectIndex, scale));

  @override
  Future<EngineResult<void>> replaceImageWithJpeg(
    DocHandle doc,
    int page,
    int objectIndex,
    TransferableTypedData jpeg,
  ) async {
    final result = await _run(wReplaceImage, (doc.id, page, objectIndex, jpeg));
    return switch (result) {
      EngineOk(value: true) => const EngineOk(null),
      EngineOk() => const EngineErr(EngineFailure(EngineErrorCode.imageUnsupported, 'jpeg rejected')),
      EngineErr(:final failure) => EngineErr(failure),
    };
  }

  @override
  Future<void> finishPage(DocHandle doc, int page, {required bool changed}) =>
      _run(wFinishPage, (doc.id, page, changed));

  @override
  Future<EngineResult<void>> save(DocHandle doc, String outPath) => _run(wSave, (doc.id, outPath));

  @override
  Future<EngineResult<RenderedPage>> render(DocHandle doc, int page, {required int widthPx}) =>
      _run(wRender, (doc.id, page, widthPx));

  /// Documents and pages open in the worker (leak checks in tests).
  @visibleForTesting
  Future<(int, int)> openCounts() async => (await _run(wOpenCounts, null)).valueOrThrow;

  /// Throws a non-engine error inside the worker (robustness tests).
  @visibleForTesting
  Future<EngineResult<void>> debugThrowInWorker() => _run(wDebugThrow, null);
}
