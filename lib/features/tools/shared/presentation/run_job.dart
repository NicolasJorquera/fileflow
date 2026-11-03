import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/jobs/jobs.dart';

/// Queues [body] and keeps the calling controller alive until the job ends:
/// its job folder holds the job's inputs and is deleted when it is disposed.
Job runKeepingAlive(Ref ref, JobBody body) {
  final link = ref.keepAlive();
  return ref.read(jobRunnerProvider).enqueue((token) async* {
    try {
      yield* body(token);
    } finally {
      link.close();
    }
  });
}
