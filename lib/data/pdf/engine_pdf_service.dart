import 'dart:io';

import 'package:pdf_engine/pdf_engine.dart';

import '../../core/domain/failures.dart';
import '../../core/domain/files.dart';
import '../../core/domain/pdf.dart';
import '../../core/domain/result.dart';
import '../../core/jobs/jobs.dart';

/// [PdfService] on the pdf_engine package. Translates [EngineFailure]s into
/// [AppFailure]s (PRD error catalog) and keeps every operation cancellable
/// between engine tasks.
class EnginePdfService implements PdfService {
  const EnginePdfService(this._engine, this._codec);

  final PdfEngine _engine;
  final ImageCodec _codec;

  /// Pages imported per engine task in [compose]: small enough to report
  /// progress and cancel on big documents, big enough to stay fast.
  static const _chunk = 50;

  /// JPEG quality of exported images: sharp text, half the size of PNG.
  static const _jpegQuality = 90;

  /// PRD H6: wider images risk running out of memory on 2 GB phones.
  static const _maxImageWidth = 4000;

  static AppFailure toAppFailure(EngineFailure f) => switch (f.code) {
    EngineErrorCode.damaged => const PdfDamaged(),
    EngineErrorCode.passwordRequired || EngineErrorCode.unsupportedSecurity => const PdfPasswordRequired(),
    EngineErrorCode.io => const SourceAccessLost(),
    EngineErrorCode.writeFailed => const InsufficientStorage(0),
    EngineErrorCode.pageUnreadable => const PageUnreadable(0),
    _ => Unexpected('engine:${f.code.name}'),
  };

  @override
  Future<Result<PdfSummary>> inspect(String path) async => switch (await _engine.inspect(path)) {
    EngineOk(:final value) => Ok(PdfSummary(pageCount: value.pageCount, looksTextOnly: value.looksTextOnly)),
    EngineErr(:final failure) => Err(toAppFailure(failure)),
  };

  @override
  Future<Result<int>> merge(
    List<String> inputs,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    final total = inputs.length + 1;
    final DocHandle dest;
    switch (await _engine.createEmpty()) {
      case EngineOk(:final value):
        dest = value;
      case EngineErr(:final failure):
        return Err(toAppFailure(failure));
    }
    // Sources stay open until the copy is saved: imported pages may still read
    // stream data from them.
    final sources = <DocHandle>[];
    final part = '$output.part';
    try {
      var pages = 0;
      for (final input in inputs) {
        if (token?.isCancelled ?? false) return const Err(Cancelled());
        final DocHandle src;
        switch (await _engine.open(input)) {
          case EngineOk(:final value):
            src = value;
          case EngineErr(:final failure):
            return Err(toAppFailure(failure));
        }
        sources.add(src);
        switch (await _engine.importPages(dest, src, at: pages)) {
          case EngineOk(:final value):
            pages = value;
          case EngineErr(:final failure):
            return Err(toAppFailure(failure));
        }
        onProgress?.call(sources.length, total);
      }
      if (token?.isCancelled ?? false) return const Err(Cancelled());
      if (await _engine.save(dest, part) case EngineErr(:final failure)) return Err(toAppFailure(failure));
      await File(part).rename(output);
      onProgress?.call(total, total);
      return Ok(pages);
    } finally {
      for (final s in sources) {
        await _engine.close(s);
      }
      await _engine.close(dest);
      final leftover = File(part);
      if (await leftover.exists()) await leftover.delete();
    }
  }

  Future<Result<DocHandle>> _open(String path) async => switch (await _engine.open(path)) {
    EngineOk(:final value) => Ok(value),
    EngineErr(:final failure) => Err(toAppFailure(failure)),
  };

  @override
  Future<Result<int>> compose(
    String input,
    List<PageRef> pages,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    final chunks = (pages.length / _chunk).ceil();
    final total = chunks + 1;
    final DocHandle src;
    switch (await _open(input)) {
      case Ok(:final value):
        src = value;
      case Err(:final failure):
        return Err(failure);
    }
    DocHandle? dest;
    final part = '$output.part';
    try {
      switch (await _engine.createEmpty()) {
        case EngineOk(:final value):
          dest = value;
        case EngineErr(:final failure):
          return Err(toAppFailure(failure));
      }
      for (var c = 0; c < chunks; c++) {
        if (token?.isCancelled ?? false) return const Err(Cancelled());
        final slice = pages.sublist(c * _chunk, ((c + 1) * _chunk).clamp(0, pages.length));
        final at = c * _chunk;
        final imported = await _engine.importPages(dest, src, pages: [for (final p in slice) p.index], at: at);
        if (imported case EngineErr(:final failure)) return Err(toAppFailure(failure));
        for (final (i, p) in slice.indexed) {
          if (p.quarterTurns % 4 == 0) continue;
          final rotated = await _engine.rotatePage(dest, at + i, p.quarterTurns % 4);
          if (rotated case EngineErr(:final failure)) return Err(toAppFailure(failure));
        }
        onProgress?.call(c + 1, total);
      }
      if (token?.isCancelled ?? false) return const Err(Cancelled());
      if (await _engine.save(dest, part) case EngineErr(:final failure)) return Err(toAppFailure(failure));
      await File(part).rename(output);
      onProgress?.call(total, total);
      return Ok(pages.length);
    } finally {
      await _engine.close(src);
      if (dest != null) await _engine.close(dest);
      final leftover = File(part);
      if (await leftover.exists()) await leftover.delete();
    }
  }

  @override
  Future<Result<int>> exportImages(
    String input,
    List<int> pages,
    List<String> outputs, {
    required ImageFormat format,
    required int dpi,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    assert(pages.length == outputs.length);
    final DocHandle src;
    switch (await _open(input)) {
      case Ok(:final value):
        src = value;
      case Err(:final failure):
        return Err(failure);
    }
    try {
      var bytes = 0;
      for (final (i, page) in pages.indexed) {
        if (token?.isCancelled ?? false) return const Err(Cancelled());
        final RenderedPage rendered;
        switch (await _engine.render(src, page, dpi: dpi.toDouble(), maxWidthPx: _maxImageWidth, rgba: true)) {
          case EngineOk(:final value):
            rendered = value;
          case EngineErr(:final failure):
            return Err(toAppFailure(failure));
        }
        final written = await _codec.writeImage(
          rgba: rendered.pixels.materialize().asUint8List(),
          width: rendered.width,
          height: rendered.height,
          format: format,
          quality: _jpegQuality,
          path: outputs[i],
        );
        switch (written) {
          case Ok(:final value):
            bytes += value;
          case Err(:final failure):
            return Err(failure);
        }
        onProgress?.call(i + 1, pages.length);
      }
      return Ok(bytes);
    } finally {
      await _engine.close(src);
    }
  }
}
