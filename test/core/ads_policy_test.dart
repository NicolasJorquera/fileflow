import 'package:fileflow/core/domain/ads.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  final t0 = DateTime(2026, 11, 7, 10);

  group('RN-08: where banners may appear', () {
    test('only on screens that show no document content', () {
      expect(
        {
          for (final p in AdPlacement.values)
            if (bannerAllowed(p)) p,
        },
        {AdPlacement.home, AdPlacement.result, AdPlacement.reduceOptions},
      );
    });
  });

  group('RN-09: when an interstitial may appear', () {
    bool allowed({required int completed, int? atTask, DateTime? at, DateTime? now}) =>
        InterstitialPolicy.allowed(completed: completed, atTask: atTask, at: at, now: now ?? t0);

    test('never in the first 3 completed tasks', () {
      expect([for (var n = 0; n <= 3; n++) allowed(completed: n)], everyElement(isFalse));
      expect(allowed(completed: 4), isTrue);
    });

    test('at most one every 2 completed tasks', () {
      // Shown at task 4: the next one is allowed from task 6 on.
      expect(allowed(completed: 5, atTask: 4, at: t0.subtract(const Duration(hours: 1))), isFalse);
      expect(allowed(completed: 6, atTask: 4, at: t0.subtract(const Duration(hours: 1))), isTrue);
    });

    test('and at least 3 minutes apart', () {
      expect(allowed(completed: 9, atTask: 4, at: t0.subtract(const Duration(minutes: 2))), isFalse);
      expect(allowed(completed: 9, atTask: 4, at: t0.subtract(const Duration(minutes: 3))), isTrue);
    });
  });

  group('the coordinator', () {
    test('shows, then records the task count and the time', () async {
      final settings = MemorySettings()..completedTasks = 5;
      final ads = FakeAds();
      final coordinator = InterstitialCoordinator(ads: ads, settings: settings, clock: () => t0);
      await coordinator.afterSaveOrShare();
      expect((ads.shown, settings.interstitialAtTask, settings.interstitialAt), (1, 5, t0));
    });

    test('does nothing when ads are off or nothing was shown', () async {
      final settings = MemorySettings()..completedTasks = 5;
      await InterstitialCoordinator(
        ads: FakeAds(isEnabled: false),
        settings: settings,
        clock: () => t0,
      ).afterSaveOrShare();
      final noAd = FakeAds(willShow: false);
      await InterstitialCoordinator(ads: noAd, settings: settings, clock: () => t0).afterSaveOrShare();
      expect(noAd.requested, 1);
      expect(settings.interstitialAt, isNull);
    });

    test('counts completed tasks', () async {
      final settings = MemorySettings();
      final coordinator = InterstitialCoordinator(ads: FakeAds(), settings: settings, clock: () => t0);
      await coordinator.recordCompletedTask();
      await coordinator.recordCompletedTask();
      expect(settings.completedTasks, 2);
    });
  });
}
