import 'dart:async';

import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:flutter_test/flutter_test.dart';

/// A job that reports [steps] progress events, checking the token between them.
JobBody steps(int count, {Completer<void>? gate, Duration step = Duration.zero}) => (token) async* {
  if (gate != null) await gate.future;
  for (var i = 1; i <= count; i++) {
    if (token.isCancelled) {
      yield const JobFailed(Cancelled());
      return;
    }
    await Future<void>.delayed(step);
    yield JobProgress(i, count);
  }
  yield JobCompleted(count);
};

void main() {
  test('one job at a time, in order, and the queue reports positions', () async {
    final runner = JobRunner();
    final gate = Completer<void>();
    final first = runner.enqueue(steps(2, gate: gate));
    final second = runner.enqueue(steps(1));
    final secondEvents = second.events.toList();
    final firstEvents = first.events.toList();
    gate.complete();
    expect((await firstEvents).last, isA<JobCompleted<int>>());
    final events = await secondEvents;
    expect(events.first, isA<JobQueued>().having((e) => e.ahead, 'ahead', 1));
    expect(events.last, isA<JobCompleted<int>>());
  });

  test('cancelling a queued job fails it at once and the rest still run', () async {
    final runner = JobRunner();
    final gate = Completer<void>();
    final first = runner.enqueue(steps(1, gate: gate));
    final queued = runner.enqueue(steps(1));
    final queuedEvents = queued.events.toList();
    queued.cancel();
    gate.complete();
    expect((await queuedEvents).last, isA<JobFailed>().having((e) => e.failure, 'failure', isA<Cancelled>()));
    expect((await first.events.toList()).last, isA<JobCompleted<int>>());
  });

  test('cancelling a running job stops it at the next check', () async {
    final runner = JobRunner();
    final job = runner.enqueue(steps(100, step: const Duration(milliseconds: 1)));
    final events = <JobEvent>[];
    final done = Completer<void>();
    job.events.listen((e) {
      events.add(e);
      if (e is JobProgress && e.done == 3) job.cancel();
    }, onDone: done.complete);
    await done.future;
    expect(events.whereType<JobProgress>().length, lessThan(10));
    expect(events.last, isA<JobFailed>().having((e) => e.failure, 'failure', isA<Cancelled>()));
  });

  test('an exception in a job becomes Unexpected and the next job runs', () async {
    final runner = JobRunner();
    final broken = runner.enqueue((token) async* {
      yield const JobProgress(0, 1);
      throw StateError('boom /secret/path.pdf');
    });
    final next = runner.enqueue(steps(1));
    final failure = (await broken.events.last as JobFailed).failure as Unexpected;
    expect(failure.diagnostic, 'StateError', reason: 'no message, it may contain a path');
    expect(await next.events.last, isA<JobCompleted<int>>());
  });

  test('a job that ends without a result fails instead of hanging', () async {
    final job = JobRunner().enqueue((token) async* {
      yield const JobProgress(1, 2);
    });
    expect(await job.events.last, isA<JobFailed>());
  });
}
