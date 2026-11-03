// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'FileFlow';

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
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count páginas', one: '1 página');
    return '$_temp0';
  }

  @override
  String get homeSection => '¿Qué necesitas hacer?';

  @override
  String get recentTitle => 'Recientes';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get toolMergeTitle => 'Unir en uno solo';

  @override
  String get toolMergeSubtitle => 'Unir PDF';

  @override
  String get interruptedNotice => 'La operación anterior se interrumpió. Tus archivos originales no cambiaron.';

  @override
  String get mergeHint => 'Arrastra para cambiar el orden. Se unen de arriba hacia abajo.';

  @override
  String get mergeAdd => 'Agregar PDF';

  @override
  String get mergeEmpty => 'Elige al menos 2 PDF para unirlos en uno solo.';

  @override
  String mergeSummary(int files, int pages) {
    String _temp0 = intl.Intl.pluralLogic(files, locale: localeName, other: '$files archivos', one: '1 archivo');
    String _temp1 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages páginas', one: '1 página');
    return '$_temp0 · $_temp1';
  }

  @override
  String mergeButton(int files) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: 'Unir $files archivos',
      one: 'Unir 1 archivo',
    );
    return '$_temp0';
  }

  @override
  String get mergeNeedTwo => 'Agrega al menos 2 PDF';

  @override
  String mergeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omiten $count archivos con problemas.',
      one: 'Se omite 1 archivo con problemas.',
    );
    return '$_temp0';
  }

  @override
  String mergeTooManyPages(int pages, int max) {
    return 'Son $pages páginas. El máximo para unir es $max.';
  }

  @override
  String mergeTooManyFiles(int max) {
    return 'Puedes unir hasta $max archivos a la vez.';
  }

  @override
  String get mergeBig => 'Son muchos MB: puede tardar unos minutos.';

  @override
  String mergedName(String date) {
    return 'Documento unido $date';
  }

  @override
  String get itemPreparing => 'Preparando…';

  @override
  String itemMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages págs.', one: '1 pág.');
    return '$_temp0 · $size';
  }

  @override
  String removeItem(String name) {
    return 'Quitar $name';
  }

  @override
  String moveItem(String name) {
    return 'Mover $name';
  }

  @override
  String get moveUp => 'Mover arriba';

  @override
  String get moveDown => 'Mover abajo';

  @override
  String removedSnack(String name) {
    return 'Se quitó $name';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get processingMerge => 'Uniendo…';

  @override
  String processingStep(int done, int total) {
    return 'Paso $done de $total';
  }

  @override
  String get processingHint => 'Puedes ir a otra pantalla: seguimos trabajando mientras la app esté abierta.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelConfirmTitle => '¿Cancelar?';

  @override
  String get cancelConfirmBody => 'Se descarta lo avanzado. Tus archivos originales no cambian.';

  @override
  String get keepGoing => 'Seguir';

  @override
  String get back => 'Volver';

  @override
  String get resultTitle => 'Listo';

  @override
  String get resultMerged => 'Unido en un solo PDF';

  @override
  String resultMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages páginas', one: '1 página');
    return '$_temp0 · $size';
  }

  @override
  String get fileNameLabel => 'Nombre del archivo';

  @override
  String get share => 'Compartir';

  @override
  String get saveTo => 'Guardar en…';

  @override
  String get openWith => 'Abrir con otra app';

  @override
  String get nextStep => 'Siguiente paso';

  @override
  String get nextMergeAnother => 'Unir con otro PDF';

  @override
  String get recentsNote => 'Queda en Recientes por 7 días. Usa «Guardar en…» para conservarlo en tu teléfono.';

  @override
  String get savedSnack => 'Guardado';

  @override
  String get close => 'Cerrar';

  @override
  String get errDamaged => 'No pudimos abrir este archivo. Puede estar dañado o no ser un PDF.';

  @override
  String get errPassword => 'Este PDF tiene contraseña. Esta versión todavía no puede abrirlo.';

  @override
  String get errAccessLost => 'Ya no tenemos acceso a ese archivo. Vuelve a elegirlo.';

  @override
  String errNoSpace(String size) {
    return 'No hay espacio suficiente. Necesitas unos $size libres.';
  }

  @override
  String get errNoSpaceGeneric => 'No hay espacio suficiente en el teléfono.';

  @override
  String get errNoApp => 'No hay una app para abrir este archivo.';

  @override
  String get errGeneric => 'Algo falló al procesar el archivo. Tu original no cambió.';

  @override
  String get retry => 'Reintentar';

  @override
  String processingPercent(int percent) {
    return '$percent %';
  }
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs() : super('es_ES');

  @override
  String get privacyNote => 'Todo se procesa en tu móvil. Funciona sin conexión.';

  @override
  String get recentsNote => 'Queda en Recientes durante 7 días. Usa «Guardar en…» para conservarlo en tu móvil.';

  @override
  String get errNoSpaceGeneric => 'No hay espacio suficiente en el móvil.';
}
