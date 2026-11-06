import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/features/tools/reduce/domain/reduce_document.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _mb = 1024 * 1024;
const _source = LocalFile(path: '/in/cartola.pdf', name: 'cartola.pdf', sizeBytes: 10 * _mb);

void main() {
  late FakePdfService pdf;
  late MemoryRecents recents;
  late ReduceDocument reduce;

  setUp(() {
    pdf = FakePdfService()..inputBytes = 10 * _mb;
    recents = MemoryRecents();
    reduce = ReduceDocument(pdf: pdf, recents: recents);
  });

  Future<JobEvent> run(ReduceGoal goal) async =>
      (await reduce(_source, goal, name: 'cartola (reducido).pdf')(CancelToken()).toList()).last;

  group('ajustar a X MB', () {
    test('starts at the best level the sample says fits, and stops there when it does', () async {
      // 10 MB: high → 6 MB, balanced → 4 MB, minimal → 2 MB. Goal 5 MB.
      final event = await run(const FitUnder(5 * _mb));
      expect(pdf.reducedAt, [ReduceLevel.balanced]);
      final item = (event as JobCompleted<RecentItem>).output;
      expect((item.kind, item.targetBytes, item.inputBytes), (ResultKind.reduced, 5 * _mb, 10 * _mb));
    });

    test('steps down when the real result is bigger than the estimate', () async {
      pdf.estimates = {
        ReduceLevel.high: 0.25,
        ReduceLevel.balanced: 0.2,
        ReduceLevel.minimal: 0.1,
        ReduceLevel.extra: 0.05,
      };
      await run(const FitUnder(3 * _mb)); // estimate: high 2.5 MB fits; really 6 MB, 4 MB, then 2 MB
      expect(pdf.reducedAt, [ReduceLevel.high, ReduceLevel.balanced, ReduceLevel.minimal]);
    });

    test('when nothing fits it tries the extra level and delivers the best, without claiming the goal', () async {
      final event = await run(const FitUnder(_mb ~/ 2));
      expect(pdf.reducedAt, [ReduceLevel.extra]);
      final item = (event as JobCompleted<RecentItem>).output;
      recents.nextSize = _mb; // what extra produced
      expect(item.targetBytes, _mb ~/ 2);
      expect(
        RecentItem(
          id: 'x',
          name: 'x',
          dir: '/',
          files: const ['x'],
          kind: ResultKind.reduced,
          pages: 1,
          sizeBytes: _mb,
          createdAt: DateTime(2026),
          targetBytes: _mb ~/ 2,
        ).metTarget,
        isFalse,
      );
    });

    test('firstLevelToTry keeps a 5 % margin for the estimate', () {
      final ratios = {ReduceLevel.high: 0.5, ReduceLevel.balanced: 0.3};
      expect(ReduceDocument.firstLevelToTry(ratios, 10 * _mb, 5 * _mb), 1, reason: '5 MB is not ≤ 4.75 MB');
      expect(ReduceDocument.firstLevelToTry(ratios, 10 * _mb, 6 * _mb), 0);
      expect(ReduceDocument.firstLevelToTry({}, 10 * _mb, _mb), 3, reason: 'no estimate: last level');
    });
  });

  group('RN-03: never bigger', () {
    test('a result as big as the original is «ya optimizado» and leaves no file', () async {
      pdf.reduceRatios = {...pdf.reduceRatios, ReduceLevel.balanced: 1.0};
      final event = await run(const ReduceAtLevel(ReduceLevel.balanced));
      expect(event, isA<JobFailed>().having((e) => e.failure, 'failure', isA<AlreadyOptimized>()));
      expect(recents.current, isEmpty);
      expect(recents.discarded, hasLength(1));
    });

    test('a text-only PDF (no image changed) is «ya optimizado»', () async {
      pdf.imagesChanged = 0;
      final event = await run(const ReduceAtLevel(ReduceLevel.minimal));
      expect(event, isA<JobFailed>().having((e) => e.failure, 'failure', isA<AlreadyOptimized>()));
    });

    test('a smaller result at a fixed level has no goal', () async {
      final item = ((await run(const ReduceAtLevel(ReduceLevel.high))) as JobCompleted<RecentItem>).output;
      expect(item.targetBytes, isNull);
      expect(item.metTarget, isTrue);
    });
  });

  test('cancelling discards the attempt', () async {
    final token = CancelToken()..cancel();
    final events = await reduce(_source, const FitUnder(5 * _mb), name: 'x.pdf')(token).toList();
    expect(events.last, isA<JobFailed>().having((e) => e.failure, 'failure', isA<Cancelled>()));
    expect(recents.discarded, hasLength(1));
  });
}
