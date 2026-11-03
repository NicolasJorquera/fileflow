import 'package:shared_preferences/shared_preferences.dart';

import '../../core/domain/settings.dart';

/// Settings stored with shared_preferences. Unlike documents, preferences may be
/// included in Android's backup (see data_extraction_rules.xml).
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  static Future<PrefsSettingsRepository> create() async =>
      PrefsSettingsRepository(await SharedPreferences.getInstance());

  static const _themeKey = 'theme';

  final SharedPreferences _prefs;

  @override
  ThemePreference get theme =>
      ThemePreference.values.asNameMap()[_prefs.getString(_themeKey)] ?? ThemePreference.system;

  @override
  Future<void> setTheme(ThemePreference value) => _prefs.setString(_themeKey, value.name);
}
