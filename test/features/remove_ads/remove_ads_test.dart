import 'package:fileflow/app/app.dart';
import 'package:fileflow/app/providers.dart';
import 'package:fileflow/core/domain/ads.dart';
import 'package:fileflow/core/domain/purchases.dart';
import 'package:fileflow/data/billing/play_billing.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/settings/presentation/settings_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_in_app_purchase.dart';
import '../../support/fakes.dart';

/// The card in a given state.
class _FixedRemoveAds extends RemoveAdsController {
  _FixedRemoveAds(this.fixed);

  final RemoveAdsState fixed;

  @override
  RemoveAdsState build() => fixed;

  @override
  Future<void> loadProduct() async {}
}

/// The one-time purchase «Sin anuncios»: the real Play Billing adapter over a
/// fake InAppPurchase shaped like the Android plugin.
void main() {
  late FakeInAppPurchase play;

  setUp(() => play = FakeInAppPurchase());
  tearDown(() => play.close());

  final adapters = <ProviderContainer, PlayBillingGateway>{};

  /// The app is gone: it no longer hears from Play.
  void uninstall(ProviderContainer c) {
    final billing = adapters.remove(c);
    if (billing == null) return;
    billing.dispose();
    c.dispose();
  }

  /// One install: its own settings and adapter. [play] is the Google Play
  /// account, shared between installs.
  ProviderContainer install({MemorySettings? settings, FakeAds? ads}) {
    final billing = PlayBillingGateway(play);
    final c = ProviderContainer(
      overrides: fakeOverrides(settings: settings ?? MemorySettings(), ads: ads, billing: billing),
    );
    adapters[c] = billing;
    addTearDown(() => uninstall(c));
    c.listen(removeAdsProvider, (_, _) {});
    return c;
  }

  RemoveAdsState state(ProviderContainer c) => c.read(removeAdsProvider);
  RemoveAdsController ctrl(ProviderContainer c) => c.read(removeAdsProvider.notifier);
  MemorySettings settingsOf(ProviderContainer c) => c.read(settingsRepositoryProvider) as MemorySettings;

  test('buying removes every ad, is acknowledged and saved', () async {
    final ads = FakeAds();
    final c = install(settings: MemorySettings()..completedTasks = 9, ads: ads);
    expect(state(c).owned, isFalse);

    await ctrl(c).loadProduct();
    expect(state(c).price, r'US$2.99');

    await ctrl(c).buy();
    await pumpEventQueue();
    expect(state(c).owned, isTrue);
    expect(state(c).flow, PurchaseFlow.purchased);
    expect(play.completed, [removeAdsProductId]);
    expect(settingsOf(c).adsRemoved, isTrue);

    // No banner on any screen and no interstitial, even when RN-09 allows one.
    expect(c.read(adsRemovedProvider), isTrue);
    for (final placement in AdPlacement.values) {
      expect(c.read(adBannerProvider)(placement), isA<SizedBox>());
    }
    await c.read(interstitialProvider).afterSaveOrShare();
    expect(ads.requested, 0);
  });

  test('a new install restores silently at startup and with «Restaurar compra»', () async {
    play
      ..owned =
          true // bought on another phone
      ..acknowledged = true;
    final c = install();
    expect(state(c).owned, isFalse);
    await ctrl(c).verifyWithStore();
    expect(state(c).owned, isTrue);
    expect(state(c).flow, PurchaseFlow.idle);
    expect(settingsOf(c).adsRemoved, isTrue);
    expect(play.completed, isEmpty, reason: 'already acknowledged');

    final c2 = install();
    await ctrl(c2).restore();
    expect(state(c2).owned, isTrue);
    expect(state(c2).flow, PurchaseFlow.restored);
  });

  test('an unacknowledged purchase is acknowledged when restored', () async {
    play.owned = true;
    final c = install();
    await ctrl(c).verifyWithStore();
    expect(state(c).owned, isTrue);
    expect(play.completed, [removeAdsProductId]);
  });

  test('restoring without a purchase says so; Play revokes a wrong local state', () async {
    final c = install();
    await ctrl(c).restore();
    expect(state(c).owned, isFalse);
    expect(state(c).flow, PurchaseFlow.nothingToRestore);

    // A backup from another Play account (or a refund) brings ads_removed = true.
    final restored = install(settings: MemorySettings()..adsRemoved = true);
    expect(state(restored).owned, isTrue);
    await ctrl(restored).verifyWithStore();
    expect(state(restored).owned, isFalse);
    expect(settingsOf(restored).adsRemoved, isFalse);
  });

  test('offline or without Play, a buyer keeps no ads; restoring says Play is unavailable', () async {
    play.available = false;
    final offline = install(settings: MemorySettings()..adsRemoved = true);
    await ctrl(offline).verifyWithStore();
    expect(state(offline).owned, isTrue);
    await ctrl(offline).restore();
    expect(state(offline).owned, isTrue);
    expect(state(offline).flow, PurchaseFlow.unavailable);

    // Play installed but the query fails (no connection).
    play
      ..available = true
      ..failRestore = true;
    final failing = install(settings: MemorySettings()..adsRemoved = true);
    await ctrl(failing).verifyWithStore();
    expect(state(failing).owned, isTrue);
    expect(settingsOf(failing).adsRemoved, isTrue);

    // Nobody bought: buying offline does not break anything.
    play.available = false;
    final c = install();
    await ctrl(c).loadProduct();
    expect(state(c).price, isNull);
    await ctrl(c).buy();
    expect(state(c).flow, PurchaseFlow.unavailable);
    expect(state(c).owned, isFalse);
    expect(play.calls, isNot(contains('buyNonConsumable')));
  });

  test('pending purchase: ads stay until Play confirms it', () async {
    play.buyResult = FakeBuyResult.pending;
    final c = install();
    await ctrl(c).buy();
    await pumpEventQueue();
    expect(state(c).flow, PurchaseFlow.pending);
    expect(state(c).owned, isFalse);
    expect(c.read(adsRemovedProvider), isFalse);
    expect(play.completed, isEmpty, reason: 'a pending purchase is not acknowledged');

    // Restarting while pending: Play marks it «restored», but it is not owned.
    final again = install();
    await ctrl(again).verifyWithStore();
    expect(state(again).owned, isFalse);
    await ctrl(again).restore();
    expect(state(again).flow, PurchaseFlow.pending);
    expect(play.completed, isEmpty);
    uninstall(again);

    play.confirmPending();
    await pumpEventQueue();
    expect(state(c).owned, isTrue);
    expect(state(c).flow, PurchaseFlow.purchased);
    expect(play.completed, [removeAdsProductId]);
  });

  test('canceled or failed: nothing changes and the card is usable again', () async {
    play.buyResult = FakeBuyResult.canceled;
    final c = install();
    await ctrl(c).buy();
    await pumpEventQueue();
    expect(state(c).flow, PurchaseFlow.canceled);
    expect(state(c).owned, isFalse);

    play.buyResult = FakeBuyResult.error;
    await ctrl(c).buy();
    await pumpEventQueue();
    expect(state(c).flow, PurchaseFlow.error);
    expect(state(c).owned, isFalse);
    expect(settingsOf(c).adsRemoved, isFalse);
  });

  test('the product does not exist in Play Console yet: unavailable, no price', () async {
    play.productExists = false;
    final c = install();
    await ctrl(c).loadProduct();
    expect(state(c).price, isNull);
    await ctrl(c).buy();
    expect(state(c).flow, PurchaseFlow.unavailable);
    expect(play.calls, isNot(contains('buyNonConsumable')));
  });

  test('buying what the account already owns restores it', () async {
    play
      ..owned = true
      ..acknowledged = true;
    final c = install();
    await ctrl(c).buy();
    await pumpEventQueue();
    expect(state(c).owned, isTrue);
    expect(state(c).flow, PurchaseFlow.restored);
  });

  group('the app', () {
    /// The banner AdMob would show, where RN-08 allows it.
    Widget Function(AdPlacement) fakeBanner(List<AdPlacement> requested) => (placement) {
      requested.add(placement);
      return bannerAllowed(placement) ? const SizedBox(key: Key('fake-ad-banner'), height: 50) : const SizedBox();
    };

    Future<void> pumpFileFlow(
      WidgetTester tester, {
      required MemorySettings settings,
      required List<AdPlacement> banners,
      FakeAds? ads,
      FakeConsent? consent,
    }) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      // Tall enough for Inicio's banner, at the end of the list, to be built.
      tester.view
        ..physicalSize = const Size(1080, 4800)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final billing = PlayBillingGateway(play);
      addTearDown(billing.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...fakeOverrides(settings: settings, ads: ads, consent: consent, billing: billing),
            adMobBannerProvider.overrideWithValue(fakeBanner(banners)),
          ],
          child: const FileFlowApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Ajustes: buying with Play\'s price hides the banner of Inicio', (tester) async {
      final banners = <AdPlacement>[];
      final settings = MemorySettings();
      await pumpFileFlow(tester, settings: settings, banners: banners);
      expect(find.byKey(const Key('fake-ad-banner')), findsOneWidget);

      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      final buy = find.byKey(const Key('remove-ads-buy'));
      await tester.scrollUntilVisible(buy, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text(r'Quitar anuncios · US$2.99'), findsOneWidget);
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.text('Sin anuncios. ¡Gracias por apoyar FileFlow!'), findsOneWidget);
      expect(buy, findsNothing);
      expect(find.byKey(const Key('remove-ads-restore')), findsNothing);
      expect(settings.adsRemoved, isTrue);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-ad-banner')), findsNothing);
    });

    testWidgets('a buyer starts without the consent form, the ads SDK or a banner', (tester) async {
      play
        ..owned = true
        ..acknowledged = true;
      final banners = <AdPlacement>[];
      final ads = FakeAds();
      final consent = FakeConsent();
      await pumpFileFlow(
        tester,
        settings: MemorySettings()..adsRemoved = true,
        banners: banners,
        ads: ads,
        consent: consent,
      );
      expect(banners, isEmpty);
      expect(find.byKey(const Key('fake-ad-banner')), findsNothing);
      expect((consent.gathered, ads.started), (0, false));
    });

    testWidgets('without the purchase everything stays as before', (tester) async {
      final banners = <AdPlacement>[];
      final ads = FakeAds();
      final consent = FakeConsent();
      await pumpFileFlow(tester, settings: MemorySettings(), banners: banners, ads: ads, consent: consent);
      expect(banners.toSet(), {AdPlacement.home});
      expect(find.byKey(const Key('fake-ad-banner')), findsOneWidget);
      expect((consent.gathered, ads.started), (1, true));
    });

    testWidgets('Play refunded it: the banner comes back at startup', (tester) async {
      final banners = <AdPlacement>[];
      final settings = MemorySettings()..adsRemoved = true;
      await pumpFileFlow(tester, settings: settings, banners: banners);
      expect(settings.adsRemoved, isFalse);
      expect(find.byKey(const Key('fake-ad-banner')), findsOneWidget);
    });
  });

  group('the card in Ajustes', () {
    final states = {
      'with Play\'s price': const RemoveAdsState(owned: false, price: r'US$2.99'),
      'pending': const RemoveAdsState(owned: false, flow: PurchaseFlow.pending, price: r'US$2.99'),
      'unavailable': const RemoveAdsState(owned: false, flow: PurchaseFlow.unavailable),
      'bought': const RemoveAdsState(owned: true, flow: PurchaseFlow.purchased),
    };

    Future<void> pumpCard(WidgetTester tester, RemoveAdsState s, {double textScale = 1}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...fakeOverrides(), removeAdsProvider.overrideWith(() => _FixedRemoveAds(s))],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: page!,
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('remove-ads-card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    for (final MapEntry(key: name, value: s) in states.entries) {
      testWidgets('$name: text at 200 % on a narrow phone, nothing is cut', (tester) async {
        tester.view
          ..physicalSize = const Size(320, 640) * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pumpCard(tester, s, textScale: 2);
      });

      testWidgets('$name: touch targets, labels, contrast; the status is announced', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpCard(tester, s);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        final status = find.byKey(const Key('remove-ads-status'));
        if (s.flow != PurchaseFlow.idle) {
          expect(
            tester.getSemantics(status),
            isSemantics(isLiveRegion: true, label: (tester.widget(status) as Text).data),
          );
        } else {
          expect(status, findsNothing);
        }
        handle.dispose();
      });
    }
  });
}
