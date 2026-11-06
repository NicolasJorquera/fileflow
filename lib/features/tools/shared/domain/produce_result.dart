import 'dart:async';

import '../../../../core/domain/failures.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/jobs/jobs.dart';

/// What a tool wrote into its result folder.
class Written {
  const Written({required this.pages, this.files});

  final int pages;

  /// File names inside the slot folder; null for the single file at
  /// [ResultSlot.path].
  final List<String>? files;
}

/// The common shape of every tool job: reserve a result folder in Recientes,
/// let [write] fill it while reporting progress, then register the result,
/// or delete the folder when the job fails or is cancelled. Originals are
/// never touched (RN-05) and a failed job leaves no file behind.
JobBody produceResult({
  required RecentsRepository recents,
  required String name,
  required ResultKind kind,
  int? inputBytes,
  int? targetBytes,
  required Future<Result<Written>> Function(ResultSlot slot, CancelToken token, void Function(int, int) progress) write,
}) => (token) {
  final events = StreamController<JobEvent>();
  Future<void> run() async {
    final slot = await recents.reserve(name);
    final result = await write(slot, token, (done, total) => events.add(JobProgress(done, total)));
    switch (result) {
      case Ok(:final value):
        final item = await recents.add(
          slot,
          kind: kind,
          pages: value.pages,
          inputBytes: inputBytes,
          targetBytes: targetBytes,
          files: value.files,
        );
        events.add(JobCompleted(item));
      case Err(:final failure):
        await recents.discard(slot);
        events.add(JobFailed(failure));
    }
  }

  run()
      .catchError((Object e) => events.add(JobFailed(Unexpected(e.runtimeType.toString()))))
      .whenComplete(events.close);
  return events.stream;
};
