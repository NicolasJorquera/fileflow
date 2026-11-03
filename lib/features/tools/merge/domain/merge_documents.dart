import 'dart:async';

import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';

/// Unir en uno solo (PRD H4): merges PDFs in the given order into a new result
/// in Recientes. Originals are never modified (RN-05); a failed or cancelled
/// job leaves no file behind.
class MergeDocuments {
  MergeDocuments({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  JobBody call(List<LocalFile> inputs, {required String outputName}) => (token) {
    final events = StreamController<JobEvent>();
    Future<void> run() async {
      if (inputs.length < 2) {
        events.add(const JobFailed(Unexpected('merge needs two files')));
        return;
      }
      final slot = await _recents.reserve(outputName);
      final result = await _pdf.merge(
        [for (final f in inputs) f.path],
        slot.path,
        token: token,
        onProgress: (done, total) => events.add(JobProgress(done, total)),
      );
      switch (result) {
        case Ok(:final value):
          final item = await _recents.add(
            slot,
            tool: ToolId.merge,
            pages: value,
            inputBytes: inputs.fold<int>(0, (sum, f) => sum + f.sizeBytes),
          );
          events.add(JobCompleted(item));
        case Err(:final failure):
          await _recents.discard(slot);
          events.add(JobFailed(failure));
      }
    }

    run()
        .catchError((Object e) => events.add(JobFailed(Unexpected(e.runtimeType.toString()))))
        .whenComplete(events.close);
    return events.stream;
  };
}
