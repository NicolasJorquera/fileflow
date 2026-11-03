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
}
