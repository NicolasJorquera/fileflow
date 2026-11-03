import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf_engine/pdf_engine.dart';

import '../../core/domain/files.dart';
import '../../core/domain/pdf.dart';
import '../../core/domain/result.dart';
import 'engine_pdf_service.dart';

/// [ThumbnailSource] on the PDF engine: renders small RGBA pages, encodes them
/// with the platform JPEG codec and caches the bytes in memory and on disk
/// (`<cache>/thumbs/<document key>/<page>.jpg`). The disk cache is wiped at
/// startup (see [sweep]): thumbnails show document content and must not
/// outlive the files they come from.
class EngineThumbnailSource implements ThumbnailSource {
  EngineThumbnailSource(this._engine, this._codec, {required this.cacheDir, this.widthPx = 240});

  final PdfEngine _engine;
  final ImageCodec _codec;
  final String cacheDir;

  /// Rendered width; a three-column grid on a phone is ~120 dp per tile.
  final int widthPx;

  /// Recently used thumbnails across screens, oldest first.
  final _memory = <String, Uint8List>{};
  static const _memoryEntries = 300;

  static const _jpegQuality = 70;

  /// Deletes every cached thumbnail. Called once at startup.
  Future<void> sweep() async {
    final dir = Directory('$cacheDir/thumbs');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Future<Result<Thumbnails>> open(String path) async {
    final stat = await File(path).stat();
    final key = _fnv1a('$path|${stat.size}|${stat.modified.microsecondsSinceEpoch}');
    return switch (await _engine.open(path)) {
      EngineOk(:final value) => Ok(_EngineThumbnails(this, value, key, '$cacheDir/thumbs/$key')),
      EngineErr(:final failure) => Err(EnginePdfService.toAppFailure(failure)),
    };
  }

  Uint8List? _remember(String key, [Uint8List? bytes]) {
    if (bytes != null) {
      _memory.remove(key);
      _memory[key] = bytes;
      while (_memory.length > _memoryEntries) {
        _memory.remove(_memory.keys.first);
      }
      return bytes;
    }
    final hit = _memory.remove(key);
    if (hit != null) _memory[key] = hit;
    return hit;
  }

  /// 64-bit FNV-1a: a stable, dependency-free key for a file version.
  static String _fnv1a(String s) {
    var hash = 0xcbf29ce484222325;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash *= 0x100000001b3; // wraps at 64 bits on the VM
    }
    return hash.toUnsigned(64).toRadixString(16);
  }
}

class _EngineThumbnails implements Thumbnails {
  _EngineThumbnails(this._source, this._doc, this._key, this._dir);

  final EngineThumbnailSource _source;
  final DocHandle _doc;
  final String _key;
  final String _dir;

  /// Pending requests; the last one added is rendered first.
  final _pending = <int, Completer<Uint8List?>>{};
  Future<void>? _worker;
  var _closed = false;

  @override
  int get pageCount => _doc.pageCount;

  String _memoryKey(int index) => '$_key/$index';

  @override
  Future<Uint8List?> page(int index) async {
    if (_closed) return null;
    final cached = _source._remember(_memoryKey(index));
    if (cached != null) return cached;
    final file = File('$_dir/$index.jpg');
    if (await file.exists()) return _source._remember(_memoryKey(index), await file.readAsBytes());
    final existing = _pending.remove(index);
    final completer = existing ?? Completer<Uint8List?>();
    _pending[index] = completer; // re-inserted: now the most recent
    _worker ??= _drain().whenComplete(() => _worker = null);
    return completer.future;
  }

  @override
  void cancel(int index) => _pending.remove(index)?.complete(null);

  Future<void> _drain() async {
    while (_pending.isNotEmpty && !_closed) {
      final index = _pending.keys.last;
      final completer = _pending.remove(index)!;
      completer.complete(await _render(index));
    }
  }

  Future<Uint8List?> _render(int index) async {
    final rendered = await _source._engine.render(_doc, index, widthPx: _source.widthPx, rgba: true);
    if (rendered is! EngineOk<RenderedPage>) return null;
    final page = rendered.value;
    final jpeg = await _source._codec.encodeJpeg(
      rgba: page.pixels.materialize().asUint8List(),
      width: page.width,
      height: page.height,
      targetWidth: page.width,
      targetHeight: page.height,
      quality: EngineThumbnailSource._jpegQuality,
    );
    final bytes = jpeg.valueOrNull;
    if (bytes == null) return null;
    try {
      await Directory(_dir).create(recursive: true);
      await File('$_dir/$index.jpg').writeAsBytes(bytes);
    } on FileSystemException {
      // The disk cache is an optimisation; memory still has it.
    }
    return _source._remember(_memoryKey(index), bytes);
  }

  @override
  Future<void> close() async {
    _closed = true;
    for (final c in _pending.values) {
      c.complete(null);
    }
    _pending.clear();
    await _worker;
    await _source._engine.close(_doc);
  }
}
