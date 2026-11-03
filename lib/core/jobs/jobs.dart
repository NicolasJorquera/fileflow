import 'dart:async';
import 'dart:collection';

import '../domain/failures.dart';

/// What a running job reports. A job ends with exactly one [JobCompleted] or
/// [JobFailed]; a cancelled job fails with [Cancelled].
sealed class JobEvent {
  const JobEvent();
}

/// Waiting behind other jobs; [ahead] is how many run before this one.
final class JobQueued extends JobEvent {
  const JobQueued(this.ahead);

  final int ahead;
}

final class JobProgress extends JobEvent {
  const JobProgress(this.done, this.total);

  final int done, total;
}

final class JobCompleted<T> extends JobEvent {
  const JobCompleted(this.output);

  final T output;
}

final class JobFailed extends JobEvent {
  const JobFailed(this.failure);

  final AppFailure failure;
}

/// Checked by a job between engine tasks (each task is one page or one image).
class CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// The work of a job. It must emit progress and finish with [JobCompleted] or
/// [JobFailed]; it should return early with [JobFailed]([Cancelled]) once
/// [token] is cancelled.
typedef JobBody = Stream<JobEvent> Function(CancelToken token);

class Job {
  Job._(this.id, this.events, this._token, this._dequeue);

  final int id;
  final Stream<JobEvent> events;
  final CancelToken _token;
  final bool Function() _dequeue;

  /// Cancels a queued job immediately, or a running one at its next check.
  void cancel() {
    _token.cancel();
    _dequeue();
  }
}

/// Runs one job at a time (PRD RN-11: PDFium has a single worker).
class JobRunner {
  final _queue = Queue<_Pending>();
  _Pending? _running;
  var _nextId = 1;

  Job enqueue(JobBody body) {
    final token = CancelToken();
    final controller = StreamController<JobEvent>();
    final pending = _Pending(body, token, controller);
    final job = Job._(_nextId++, controller.stream, token, () => _removeQueued(pending));
    _queue.add(pending);
    if (_running != null) controller.add(JobQueued(_queue.length));
    _pump();
    return job;
  }

  bool _removeQueued(_Pending pending) {
    if (!_queue.remove(pending)) return false;
    pending.controller
      ..add(const JobFailed(Cancelled()))
      ..close();
    _announcePositions();
    return true;
  }

  void _announcePositions() {
    var ahead = _running == null ? 0 : 1;
    for (final p in _queue) {
      p.controller.add(JobQueued(ahead++));
    }
  }

  Future<void> _pump() async {
    if (_running != null || _queue.isEmpty) return;
    final current = _running = _queue.removeFirst();
    _announcePositions();
    var finished = false;
    try {
      await for (final event in current.body(current.token)) {
        if (finished) break;
        current.controller.add(event);
        finished = event is JobCompleted || event is JobFailed;
      }
      if (!finished) {
        current.controller.add(
          JobFailed(current.token.isCancelled ? const Cancelled() : const Unexpected('job ended without a result')),
        );
      }
    } catch (e) {
      // Diagnostic is the error type only: messages may contain paths.
      current.controller.add(JobFailed(Unexpected(e.runtimeType.toString())));
    } finally {
      await current.controller.close();
      _running = null;
      _pump();
    }
  }
}

class _Pending {
  _Pending(this.body, this.token, this.controller);

  final JobBody body;
  final CancelToken token;
  final StreamController<JobEvent> controller;
}
