/// User preferences that live in the domain (no Flutter types here).
enum ThemePreference { system, light, dark }

abstract interface class SettingsRepository {
  ThemePreference get theme;
  Future<void> setTheme(ThemePreference value);
}
