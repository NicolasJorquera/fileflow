import 'settings.dart';

/// Screens that can show a banner. RN-08: never on screens that show the
/// content of a document (preview, Organizar, Unir, PDF a imagen, Fotos),
/// never during processing and never where files are only listed (Recientes).
enum AdPlacement { home, result, reduceOptions, organize, merge, toImage, photos, progress, recents, scan }

bool bannerAllowed(AdPlacement placement) => switch (placement) {
  AdPlacement.home || AdPlacement.result || AdPlacement.reduceOptions => true,
  _ => false,
};

/// The Ads SDK, behind a port: presentation and domain never see it.
abstract interface class AdsGateway {
  /// False when no unit IDs are configured (prod before H10): nothing is shown.
  bool get enabled;

  /// Starts the SDK when consent allows it. Does nothing offline or without consent.
  Future<void> start();

  /// True when a full-screen ad was shown.
  Future<bool> showInterstitial();
}

/// Consent (UMP): the form when the law requires it, and the privacy options.
abstract interface class ConsentGateway {
  Future<void> gather();
  Future<bool> canRequestAds();
  Future<void> showPrivacyOptions();
}

/// RN-09: an interstitial only after a user saves or shares a result, never in
/// the first 3 completed tasks, at most one every 2 completed tasks and 3
/// minutes apart.
abstract final class InterstitialPolicy {
  static const firstFreeTasks = 3, everyTasks = 2;
  static const minGap = Duration(minutes: 3);

  static bool allowed({required int completed, required int? atTask, required DateTime? at, required DateTime now}) {
    if (completed <= firstFreeTasks) return false;
    if (atTask != null && completed - atTask < everyTasks) return false;
    if (at != null && now.difference(at) < minGap) return false;
    return true;
  }
}

class InterstitialCoordinator {
  InterstitialCoordinator({required this._ads, required this._settings, required this._clock});

  final AdsGateway _ads;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  Future<void> recordCompletedTask() => _settings.setCompletedTasks(_settings.completedTasks + 1);

  /// Called after a successful save or share of a result.
  Future<void> afterSaveOrShare() async {
    if (!_ads.enabled) return;
    final now = _clock();
    if (!InterstitialPolicy.allowed(
      completed: _settings.completedTasks,
      atTask: _settings.interstitialAtTask,
      at: _settings.interstitialAt,
      now: now,
    )) {
      return;
    }
    if (!await _ads.showInterstitial()) return;
    await _settings.setInterstitialAt(now);
    await _settings.setInterstitialAtTask(_settings.completedTasks);
  }
}
