import 'dart:io';

import 'package:pdf_engine/pdf_engine.dart';

import '../../core/domain/failures.dart';
import '../../core/domain/pdf.dart';
import '../../core/domain/result.dart';
import '../../core/jobs/jobs.dart';

/// [PdfService] on the pdf_engine package. Translates [EngineFailure]s into
/// [AppFailure]s (PRD error catalog) and keeps every operation cancellable
/// between engine tasks.
class EnginePdfService implements PdfService {
  const EnginePdfService(this._engine);

  final PdfEngine _engine;

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
}
