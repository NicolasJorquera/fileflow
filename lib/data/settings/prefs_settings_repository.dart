import 'package:shared_preferences/shared_preferences.dart';

import '../../core/domain/pdf.dart';
import '../../core/domain/settings.dart';

/// Settings stored with shared_preferences. Unlike documents, preferences may be
/// included in Android's backup (see data_extraction_rules.xml).
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  static Future<PrefsSettingsRepository> create() async =>
      PrefsSettingsRepository(await SharedPreferences.getInstance());

  static const _themeKey = 'theme';
  static const _retentionKey = 'recents_retention';
  static const _languageKey = 'language';
  static const _pageKey = 'default_page';

  final SharedPreferences _prefs;

  @override
  ThemePreference get theme =>
      ThemePreference.values.asNameMap()[_prefs.getString(_themeKey)] ?? ThemePreference.system;

  @override
  Future<void> setTheme(ThemePreference value) => _prefs.setString(_themeKey, value.name);

  @override
  RecentsRetention get retention =>
      RecentsRetention.values.asNameMap()[_prefs.getString(_retentionKey)] ?? RecentsRetention.sevenDays;

  @override
  Future<void> setRetention(RecentsRetention value) => _prefs.setString(_retentionKey, value.name);

  @override
  String? get language => _prefs.getString(_languageKey);

  @override
  Future<void> setLanguage(String? tag) =>
      tag == null ? _prefs.remove(_languageKey) : _prefs.setString(_languageKey, tag);

  @override
  PagePreset get defaultPage => PagePreset.values.asNameMap()[_prefs.getString(_pageKey)] ?? PagePreset.auto;

  @override
  Future<void> setDefaultPage(PagePreset value) => _prefs.setString(_pageKey, value.name);
}
