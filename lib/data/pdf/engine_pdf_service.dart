import 'dart:io';
import 'dart:isolate';

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
  const EnginePdfService(this._engine, this._codec, {this.lanes = 2});

  final PdfEngine _engine;
  final ImageCodec _codec;

  /// Pages reduced in parallel: the native encoder works on one while the
  /// engine extracts the next (spike S7). One on phones with little RAM.
  final int lanes;

  /// Pages measured by [estimateReduce].
  static const _samplePages = 6;

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

  @override
  Future<Result<ReduceStats>> reduce(
    String input,
    String output, {
    required ReduceLevel level,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    final DocHandle doc;
    switch (await _open(input)) {
      case Ok(:final value):
        doc = value;
      case Err(:final failure):
        return Err(failure);
    }
    final part = '$output.part';
    try {
      final total = doc.pageCount + 1;
      var next = 0, done = 0, images = 0;
      AppFailure? failure;
      Future<void> lane() async {
        while (failure == null && next < doc.pageCount) {
          if (token?.isCancelled ?? false) {
            failure = const Cancelled();
            return;
          }
          final page = next++;
          switch (await _reducePage(doc, page, level)) {
            case Ok(:final value):
              images += value;
            case Err(failure: final f):
              failure = f;
              return;
          }
          onProgress?.call(++done, total);
        }
      }

      await Future.wait([for (var i = 0; i < lanes; i++) lane()]);
      if (failure case final f?) return Err(f);
      if (token?.isCancelled ?? false) return const Err(Cancelled());
      if (await _engine.save(doc, part) case EngineErr(:final failure)) return Err(toAppFailure(failure));
      await File(part).rename(output);
      onProgress?.call(total, total);
      return Ok(ReduceStats(pages: doc.pageCount, imagesChanged: images, outputBytes: await File(output).length()));
    } finally {
      await _engine.close(doc);
      final leftover = File(part);
      if (await leftover.exists()) await leftover.delete();
    }
  }

  /// Recompresses the images of one page that are above the level's dpi or
  /// not JPEG; returns how many changed. A page whose images cannot be read
  /// stays as it was (PRD E-PDF-03): only storage problems stop the job.
  Future<Result<int>> _reducePage(DocHandle doc, int page, ReduceLevel level) async {
    final slots = switch (await _engine.imagesOnPage(doc, page)) {
      EngineOk(:final value) => value,
      EngineErr() => const <ImageSlot>[],
    };
    var changed = 0;
    try {
      for (final slot in slots) {
        final resample = slot.effectiveDpi > level.dpi * 1.1;
        if (slot.hasTransparency || (!resample && slot.isJpeg)) continue;
        final scale = resample ? level.dpi / slot.effectiveDpi : 1.0;
        final extracted = await _engine.extractImage(doc, page, slot.objectIndex, scale);
        if (extracted is! EngineOk<RgbaImage>) continue;
        final rgba = extracted.value;
        final jpeg = await _codec.encodeJpeg(
          rgba: rgba.pixels.materialize().asUint8List(),
          width: rgba.width,
          height: rgba.height,
          targetWidth: rgba.targetWidth,
          targetHeight: rgba.targetHeight,
          quality: level.quality,
        );
        final bytes = jpeg.valueOrNull;
        if (bytes == null) continue;
        final replaced = await _engine.replaceImageWithJpeg(
          doc,
          page,
          slot.objectIndex,
          TransferableTypedData.fromList([bytes]),
        );
        if (replaced is EngineOk) changed++;
      }
      return Ok(changed);
    } finally {
      await _engine.finishPage(doc, page, changed: changed > 0);
    }
  }

  @override
  Future<Result<Map<ReduceLevel, double>>> estimateReduce(
    String input,
    List<ReduceLevel> levels, {
    CancelToken? token,
  }) async {
    final int pageCount;
    switch (await _engine.inspect(input, maxPagesToScan: 0)) {
      case EngineOk(:final value):
        pageCount = value.pageCount;
      case EngineErr(:final failure):
        return Err(toAppFailure(failure));
    }
    final count = pageCount < _samplePages ? pageCount : _samplePages;
    final pages = [for (var i = 0; i < count; i++) PageRef(i * pageCount ~/ count)];
    final dir = await Directory.systemTemp.createTemp('reduce_sample');
    try {
      final sample = '${dir.path}/sample.pdf';
      if (await compose(input, pages, sample, token: token) case Err(:final failure)) return Err(failure);
      final sampleBytes = await File(sample).length();
      final ratios = <ReduceLevel, double>{};
      for (final level in levels) {
        final out = '${dir.path}/${level.name}.pdf';
        switch (await reduce(sample, out, level: level, token: token)) {
          case Ok(:final value):
            ratios[level] = value.outputBytes / sampleBytes;
          case Err(:final failure):
            return Err(failure);
        }
        await File(out).delete();
      }
      return Ok(ratios);
    } finally {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<Result<PhotosWritten>> photosToPdf(
    List<PhotoInput> photos,
    String output, {
    required PhotoPageSpec spec,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    final DocHandle doc;
    switch (await _engine.createEmpty()) {
      case EngineOk(:final value):
        doc = value;
      case EngineErr(:final failure):
        return Err(toAppFailure(failure));
    }
    final part = '$output.part', photo = '$output.photo.jpg';
    final side = maxPhotoSide(spec);
    try {
      var pages = 0, unreadable = 0;
      for (final (i, input) in photos.indexed) {
        if (token?.isCancelled ?? false) return const Err(Cancelled());
        final prepared = await _codec.preparePhoto(
          src: input.path,
          dest: photo,
          maxWidth: side,
          maxHeight: side,
          quality: spec.quality,
          quarterTurns: input.quarterTurns,
        );
        switch (prepared) {
          case Err(failure: ImagesUnreadable()):
            unreadable++;
          case Err(:final failure):
            return Err(failure);
          case Ok(value: (final w, final h)):
            final box = pageBoxFor(spec, w, h);
            final added = await _engine.addJpegPage(
              doc,
              TransferableTypedData.fromList([await File(photo).readAsBytes()]),
              PageLayout(pageWidth: box.width, pageHeight: box.height, margin: box.margin),
            );
            if (added case EngineErr(:final failure)) return Err(toAppFailure(failure));
            pages++;
        }
        onProgress?.call(i + 1, photos.length + 1);
      }
      if (pages == 0) return Err(ImagesUnreadable(unreadable));
      if (await _engine.save(doc, part) case EngineErr(:final failure)) return Err(toAppFailure(failure));
      await File(part).rename(output);
      onProgress?.call(photos.length + 1, photos.length + 1);
      return Ok(PhotosWritten(pages: pages, unreadable: unreadable));
    } finally {
      await _engine.close(doc);
      for (final path in [part, photo]) {
        final leftover = File(path);
        if (await leftover.exists()) await leftover.delete();
      }
    }
  }
}
