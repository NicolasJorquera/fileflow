import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/flavor.dart';
import '../../core/domain/ads.dart';

/// Ad unit IDs. Dev always uses Google's test units. Prod reads its own with
/// --dart-define and shows no ads until they are given (before H10).
class AdUnits {
  const AdUnits({this.banner, this.interstitial});

  /// Google's sample units (documented test IDs, safe to ship in dev).
  static const test = AdUnits(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
  );

  static AdUnits forFlavor(Flavor flavor) => switch (flavor) {
    Flavor.dev => test,
    Flavor.prod => AdUnits(
      banner: _nonEmpty(const String.fromEnvironment('ADMOB_BANNER')),
      interstitial: _nonEmpty(const String.fromEnvironment('ADMOB_INTERSTITIAL')),
    ),
  };

  final String? banner, interstitial;

  bool get configured => banner != null && interstitial != null;

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;
}

/// Consent with UMP. The debug geography (EEA) is only for testing in dev.
class UmpConsentGateway implements ConsentGateway {
  const UmpConsentGateway({this.debugEea = false});

  final bool debugEea;

  @override
  Future<void> gather() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        consentDebugSettings: debugEea
            ? ConsentDebugSettings(debugGeography: DebugGeography.debugGeographyEea, testIdentifiers: const [])
            : null,
      ),
      () => updated.complete(),
      (_) => updated.complete(),
    );
    await updated.future;
    // Offline the form cannot load: the app goes on without ads.
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<void> showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((_) {});
}

class AdMobAdsGateway implements AdsGateway {
  AdMobAdsGateway(this._units, this._consent);

  final AdUnits _units;
  final ConsentGateway _consent;
  bool _started = false;
  InterstitialAd? _ready;

  @override
  bool get enabled => _units.configured;

  @override
  Future<void> start() async {
    if (!enabled || _started || !await _consent.canRequestAds()) return;
    _started = true;
    await MobileAds.instance.initialize();
    _load();
  }

  void _load() {
    InterstitialAd.load(
      adUnitId: _units.interstitial!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ready = ad,
        onAdFailedToLoad: (_) => _ready = null,
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _ready;
    if (ad == null) {
      _load();
      return false;
    }
    _ready = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _load();
      },
    );
    await ad.show();
    return true;
  }
}

/// A banner that takes no space until it has loaded (offline it never does).
class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
