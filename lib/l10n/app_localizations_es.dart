// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Listo PDF';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia e idioma';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get privacyNote => 'Todo se procesa en tu teléfono. Funciona sin conexión.';

  @override
  String get homeToolsPending => 'Las herramientas llegan en los próximos hitos.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count páginas', one: '1 página');
    return '$_temp0';
  }
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs() : super('es_ES');

  @override
  String get privacyNote => 'Todo se procesa en tu móvil. Funciona sin conexión.';
}
