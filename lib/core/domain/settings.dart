import 'pdf.dart';

/// User preferences that live in the domain (no Flutter types here).
enum ThemePreference { system, light, dark }

/// How long results stay in Recientes (PRD RN-06). [period] is null for
/// «hasta que yo los borre».
enum RecentsRetention {
  oneDay(Duration(days: 1)),
  sevenDays(Duration(days: 7)),
  thirtyDays(Duration(days: 30)),
  untilDeleted(null);

  const RecentsRetention(this.period);

  final Duration? period;
}

abstract interface class SettingsRepository {
  ThemePreference get theme;
  Future<void> setTheme(ThemePreference value);

  RecentsRetention get retention;
  Future<void> setRetention(RecentsRetention value);

  /// App language as a tag («es», «es_ES», «en», «pt»); null follows the
  /// phone (and Android 13's per-app language setting).
  String? get language;
  Future<void> setLanguage(String? tag);

  /// Completed tasks in total (RN-09 counts them).
  int get completedTasks;
  Future<void> setCompletedTasks(int value);

  /// Task count and time of the last interstitial.
  int? get interstitialAtTask;
  Future<void> setInterstitialAtTask(int? value);
  DateTime? get interstitialAt;
  Future<void> setInterstitialAt(DateTime value);

  /// Page size Fotos a PDF starts with.
  PagePreset get defaultPage;
  Future<void> setDefaultPage(PagePreset value);
}
