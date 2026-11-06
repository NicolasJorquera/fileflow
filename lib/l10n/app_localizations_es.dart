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
  String recentsNote(String period) {
    return 'Queda en Recientes por $period. Usa «Guardar en…» para conservarlo en tu teléfono.';
  }

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

  @override
  String get toolOrganizeTitle => 'Organizar páginas';

  @override
  String get toolOrganizeSubtitle => 'Separar, extraer, rotar';

  @override
  String get toolToImageTitle => 'PDF a imagen';

  @override
  String get toolToImageSubtitle => 'JPG o PNG';

  @override
  String get nextToImage => 'Convertir a imagen';

  @override
  String get choosePdf => 'Elegir un PDF';

  @override
  String get chooseToolTitle => '¿Qué quieres hacer?';

  @override
  String get change => 'Cambiar';

  @override
  String get save => 'Guardar';

  @override
  String get select => 'Seleccionar';

  @override
  String get delete => 'Eliminar';

  @override
  String get more => 'Más';

  @override
  String moreFor(String name) {
    return 'Más opciones para $name';
  }

  @override
  String get rotate => 'Rotar';

  @override
  String get extract => 'Extraer';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get clearSelection => 'Quitar selección';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '1 seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get moveBefore => 'Mover antes';

  @override
  String get moveAfter => 'Mover después';

  @override
  String pageLabel(int position) {
    return 'Página $position';
  }

  @override
  String pageLabelRotated(int position, int degrees) {
    return 'Página $position, girada $degrees°';
  }

  @override
  String sourceMeta(String name, int pages) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages págs.', one: '1 pág.');
    return '$name · $_temp0';
  }

  @override
  String get organizeEmpty => 'Elige el PDF cuyas páginas quieres ordenar, rotar, extraer o separar.';

  @override
  String get organizeHint => 'Toca las páginas para elegirlas. Mantén presionado para moverlas.';

  @override
  String get organizeLong => 'Son muchas páginas: las miniaturas pueden tardar en aparecer.';

  @override
  String get organizeKeepOne => 'Debe quedar al menos una página.';

  @override
  String organizeDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se eliminaron $count páginas',
      one: 'Se eliminó 1 página',
    );
    return '$_temp0';
  }

  @override
  String get discardTitle => '¿Descartar cambios?';

  @override
  String get discardBody => 'Tu archivo original no cambia.';

  @override
  String get discard => 'Descartar';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get splitMenu => 'Separar…';

  @override
  String get selectRangeMenu => 'Seleccionar rango';

  @override
  String get splitTitle => 'Separar en varios PDF';

  @override
  String get splitEvery => 'Cada cierto número de páginas';

  @override
  String get splitEveryLabel => 'Páginas por archivo';

  @override
  String get splitRanges => 'Por rangos';

  @override
  String get splitEachPage => 'Una página por archivo';

  @override
  String splitButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Separar en $count archivos',
      one: 'Separar en 1 archivo',
    );
    return '$_temp0';
  }

  @override
  String get splitButtonIdle => 'Separar';

  @override
  String get rangeLabel => 'Páginas';

  @override
  String get rangeHint => '1-3, 5, 8-10';

  @override
  String rangeHelper(int count) {
    return 'Del 1 al $count';
  }

  @override
  String get rangeEmpty => 'Escribe páginas, por ejemplo 1-3, 5.';

  @override
  String rangeNotANumber(String token) {
    return '«$token» no es una página ni un rango.';
  }

  @override
  String rangeOutOfRange(String token, int count) {
    return '«$token» está fuera del documento (1 a $count).';
  }

  @override
  String rangeReversed(String token) {
    return 'En «$token» el primer número debe ser el menor.';
  }

  @override
  String nameEdited(String stem) {
    return '$stem (editado)';
  }

  @override
  String namePages(String stem, String pages) {
    return '$stem (págs. $pages)';
  }

  @override
  String namePage(String stem, String page) {
    return '$stem (pág. $page)';
  }

  @override
  String nameSplit(String stem) {
    return '$stem (separado)';
  }

  @override
  String nameImages(String stem) {
    return '$stem (imágenes)';
  }

  @override
  String get processingSave => 'Guardando…';

  @override
  String get processingExtract => 'Extrayendo…';

  @override
  String get processingSplit => 'Separando…';

  @override
  String get processingConvert => 'Convirtiendo…';

  @override
  String get toImageEmpty => 'Elige el PDF que quieres convertir en imágenes.';

  @override
  String get formatLabel => 'Formato';

  @override
  String get formatJpg => 'JPG · más liviano';

  @override
  String get formatPng => 'PNG · sin pérdida';

  @override
  String get resolutionLabel => 'Resolución';

  @override
  String dpiValue(int dpi) {
    return '$dpi dpi';
  }

  @override
  String get resolutionHelp => '150 dpi: se ve bien en pantalla y en WhatsApp. 300 dpi: para imprimir.';

  @override
  String get pagesLabel => 'Páginas';

  @override
  String pagesAll(int count) {
    return 'Todas ($count)';
  }

  @override
  String get pagesChoose => 'Elegir páginas';

  @override
  String pagesChosen(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count páginas', one: '1 página');
    return '$_temp0: $list';
  }

  @override
  String usePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usar $count páginas',
      one: 'Usar 1 página',
      zero: 'Elige páginas',
    );
    return '$_temp0';
  }

  @override
  String toImageEstimate(int count, String format, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes $format',
      one: '1 imagen $format',
    );
    return '$_temp0 · unos $size en total';
  }

  @override
  String toImageTooMany(int max) {
    return 'Puedes convertir hasta $max páginas a la vez. Elige menos páginas.';
  }

  @override
  String convertButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convertir $count páginas',
      one: 'Convertir 1 página',
    );
    return '$_temp0';
  }

  @override
  String get resultEdited => 'Cambios guardados en un PDF nuevo';

  @override
  String resultExtracted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas extraídas',
      one: 'Página extraída',
    );
    return '$_temp0';
  }

  @override
  String resultSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Separado en $count archivos',
      one: 'Separado en 1 archivo',
    );
    return '$_temp0';
  }

  @override
  String resultImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes listas',
      one: '1 imagen lista',
    );
    return '$_temp0';
  }

  @override
  String filesMeta(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count archivos', one: '1 archivo');
    return '$_temp0 · $size';
  }

  @override
  String andMore(int count) {
    return 'y $count más';
  }

  @override
  String get shareAll => 'Compartir todo';

  @override
  String get saveToFolder => 'Guardar en carpeta…';

  @override
  String savedFolderSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se guardaron $count archivos',
      one: 'Se guardó 1 archivo',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count días', one: '1 día');
    return '$_temp0';
  }

  @override
  String get recentsNoteForever => 'Queda en Recientes hasta que lo borres.';

  @override
  String recentsNotice(String period) {
    return 'Los resultados se borran solos a los $period. Puedes cambiarlo en Ajustes.';
  }

  @override
  String get recentsNoticeForever => 'Los resultados quedan aquí hasta que los borres. Puedes cambiarlo en Ajustes.';

  @override
  String get groupToday => 'Hoy';

  @override
  String get groupWeek => 'Esta semana';

  @override
  String get groupOlder => 'Antes';

  @override
  String get tagMerged => 'Unido';

  @override
  String get tagEdited => 'Editado';

  @override
  String get tagExtracted => 'Extraído';

  @override
  String get tagSplit => 'Separado';

  @override
  String get tagImages => 'Imágenes';

  @override
  String expiresInDays(String size, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days días', one: '1 día');
    return '$size · se borra en $_temp0';
  }

  @override
  String expiresToday(String size) {
    return '$size · se borra hoy';
  }

  @override
  String get useInTool => 'Usar en otra herramienta';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get clearAllTitle => '¿Borrar todo?';

  @override
  String clearAllBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count resultados', one: '1 resultado');
    return 'Se borrarán $_temp0 ($size). Lo que guardaste en otras carpetas no cambia.';
  }

  @override
  String get clearAllConfirm => 'Borrar';

  @override
  String get recentsEmptyTitle => 'Aquí verás lo que crees';

  @override
  String get recentsEmptyBody =>
      'Los PDF e imágenes que crees con FileFlow quedan aquí un tiempo para que puedas volver a compartirlos.';

  @override
  String get settingsRecents => 'Recientes';

  @override
  String get retentionLabel => 'Borrar resultados automáticamente';

  @override
  String retentionAfter(String period) {
    return 'Después de $period';
  }

  @override
  String get retentionNever => 'Nunca: los borro yo';

  @override
  String get retentionShortenTitle => '¿Cambiar el plazo?';

  @override
  String retentionShortenBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count resultados', one: '1 resultado');
    return 'Con este plazo se borran ahora $_temp0 ($size).';
  }

  @override
  String errTooManyPages(int pages, int max) {
    return 'Son $pages páginas. El máximo es $max.';
  }

  @override
  String get add => 'Agregar';

  @override
  String get before => 'Antes';

  @override
  String get after => 'Ahora';

  @override
  String beforeAfter(String before, String after, int percent) {
    return '$before → $after · $percent % menos';
  }

  @override
  String get alreadyOptimizedTitle => 'Este PDF ya está optimizado';

  @override
  String get alreadyOptimizedBody =>
      'Reducirlo no lo haría más liviano, así que no creamos un archivo nuevo. Tu original sirve tal cual.';

  @override
  String get choosePhotos => 'Elegir fotos';

  @override
  String createPdfButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crear PDF · $count páginas',
      one: 'Crear PDF · 1 página',
      zero: 'Crear PDF',
    );
    return '$_temp0';
  }

  @override
  String get levelHigh => 'Alta';

  @override
  String get levelHighHelp => 'Para imprimir o ampliar. Reduce menos.';

  @override
  String get levelBalanced => 'Equilibrada';

  @override
  String get levelBalancedHelp => 'Se lee bien en pantalla y al imprimir.';

  @override
  String get levelMinimal => 'Mínima';

  @override
  String get levelMinimalHelp => 'El archivo más liviano; las fotos pierden detalle.';

  @override
  String get margins => 'Márgenes';

  @override
  String get marginNone => 'Sin margen';

  @override
  String get marginSmall => 'Pequeño';

  @override
  String namePhotos(String stamp) {
    return 'Fotos $stamp';
  }

  @override
  String nameReduced(String stem) {
    return '$stem (reducido)';
  }

  @override
  String nameScan(String stamp) {
    return 'Escaneo $stamp';
  }

  @override
  String get nextReduce => 'Ajustar tamaño';

  @override
  String get originalUnchanged => 'Tu archivo original no cambia.';

  @override
  String get pageSize => 'Tamaño de página';

  @override
  String get pageAuto => 'Automático';

  @override
  String pageAutoNamed(String name) {
    return 'Automático ($name)';
  }

  @override
  String pageAutoShort(String name) {
    return '$name · automático';
  }

  @override
  String get pageLetter => 'Carta';

  @override
  String get pageOficio => 'Oficio (216 × 330 mm)';

  @override
  String get pageFitImage => 'Ajustar a la foto';

  @override
  String get pageFitImageHelp => 'Cada página mide lo que la foto';

  @override
  String get photoQuality => 'Calidad';

  @override
  String photoLabel(int position, int count) {
    return 'Foto $position de $count';
  }

  @override
  String photoLabelUnreadable(int position, int count) {
    return 'Foto $position de $count, no se pudo leer';
  }

  @override
  String photoRemoved(int position) {
    return 'Se quitó la foto $position';
  }

  @override
  String get photoUnreadable => 'No se pudo leer';

  @override
  String rotatePhoto(int position) {
    return 'Girar foto $position';
  }

  @override
  String removePhoto(int position) {
    return 'Quitar foto $position';
  }

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fotos', one: '1 foto');
    return '$_temp0 · mantén presionada una foto para moverla';
  }

  @override
  String get photosEmpty => 'Elige las fotos que quieres juntar en un PDF.';

  @override
  String photosEstimate(String size) {
    return 'Tamaño estimado: unos $size';
  }

  @override
  String photosSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omiten $count fotos que no se pudieron leer.',
      one: 'Se omite 1 foto que no se pudo leer.',
    );
    return '$_temp0';
  }

  @override
  String photosTooMany(int max) {
    return 'Puedes juntar hasta $max fotos en un PDF.';
  }

  @override
  String processingFit(String size) {
    return 'Ajustando a $size…';
  }

  @override
  String get processingReduce => 'Reduciendo…';

  @override
  String get processingPhotos => 'Creando el PDF…';

  @override
  String get reduceEmpty => 'Elige el PDF que quieres hacer más liviano.';

  @override
  String get reduceHasImages => 'Tiene imágenes: se puede reducir bastante';

  @override
  String get reduceTextOnly => 'Este PDF es casi todo texto: la reducción será pequeña';

  @override
  String get reduceBig => 'Es un archivo grande: puede tardar unos minutos.';

  @override
  String reduceTooBig(int pages, String size) {
    return 'Este PDF supera el máximo ($pages páginas o $size). Sepáralo en partes y reduce cada una.';
  }

  @override
  String get reduceSplitInstead => 'Separar en partes';

  @override
  String get reduceHow => '¿Cómo quieres reducirlo?';

  @override
  String get reduceModeSize => 'Tamaño máximo';

  @override
  String get reduceModeQuality => 'Calidad';

  @override
  String get reduceSizeHelp => 'El límite que pide el portal o el correo';

  @override
  String get reduceOther => 'Otro…';

  @override
  String get reduceOtherTitle => 'Tamaño máximo';

  @override
  String get reduceOtherLabel => 'Megabytes';

  @override
  String reduceSizeExplain(String size) {
    return 'Buscamos la mejor calidad que quepa en $size. Si no se puede, te mostramos el resultado más cercano y te lo decimos.';
  }

  @override
  String get reduceExpected => 'Resultado';

  @override
  String get reduceExpectedSize => 'Tamaño';

  @override
  String reduceExpectedUnder(String before, String target) {
    return '$before → máximo $target';
  }

  @override
  String get reduceSelectableText => 'Texto seleccionable';

  @override
  String get reduceKept => 'Se conserva';

  @override
  String reduceToButton(String size) {
    return 'Reducir a $size';
  }

  @override
  String get reduceButton => 'Reducir';

  @override
  String resultReduced(int percent) {
    return 'Reducido un $percent %';
  }

  @override
  String resultUnder(String target) {
    return 'Quedó bajo $target';
  }

  @override
  String resultMissed(String size, String target) {
    return 'Quedó en $size: no alcanzó $target';
  }

  @override
  String get resultMissedHint =>
      'Es lo más liviano que se pudo sin dañar el texto. Separa el documento en partes y reduce cada una.';

  @override
  String get resultScanned => 'Escaneo listo';

  @override
  String resultPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PDF creado con $count fotos',
      one: 'PDF creado con 1 foto',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Escanear documento';

  @override
  String get scanSubtitle => 'Recorte automático y varias páginas';

  @override
  String get scanButton => 'Escanear';

  @override
  String get scanOfflineTitle => 'El escáner necesita conexión la primera vez';

  @override
  String get scanOfflineBody =>
      'Tu teléfono descarga el escáner una sola vez. Después funciona sin internet. Mientras tanto, puedes crear un PDF con fotos que ya tengas.';

  @override
  String get scanUnsupportedTitle => 'El escáner no está disponible en este teléfono';

  @override
  String get scanUnsupportedBody =>
      'Necesita Google Play services y al menos 1,7 GB de memoria. Puedes sacar fotos con la cámara y crear un PDF con ellas.';

  @override
  String get scanUsePhotos => 'Crear PDF con fotos';

  @override
  String get understood => 'Entendido';

  @override
  String get tagReduced => 'Reducido';

  @override
  String get tagScanned => 'Escaneo';

  @override
  String get tagPhotos => 'Fotos a PDF';

  @override
  String get toolReduceTitle => 'Reducir tamaño';

  @override
  String get toolReduceSubtitle => 'Deja tu PDF bajo 1, 2 o 10 MB para subirlo donde te lo piden';

  @override
  String get toolPhotosTitle => 'Fotos a PDF';

  @override
  String get toolPhotosSubtitle => 'JPG, PNG, HEIC';

  @override
  String errImagesUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No pudimos leer $count fotos. Pueden estar dañadas o en un formato que el teléfono no abre.',
      one: 'No pudimos leer esa foto. Puede estar dañada o en un formato que el teléfono no abre.',
    );
    return '$_temp0';
  }
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs() : super('es_ES');

  @override
  String get privacyNote => 'Todo se procesa en tu móvil. Funciona sin conexión.';

  @override
  String recentsNote(String period) {
    return 'Queda en Recientes durante $period. Usa «Guardar en…» para conservarlo en tu móvil.';
  }

  @override
  String get errNoSpaceGeneric => 'No hay espacio suficiente en el móvil.';

  @override
  String get resolutionHelp => '150 ppp: se ve bien en pantalla y en WhatsApp. 300 ppp: para imprimir.';

  @override
  String get pageOficio => 'Folio (216 × 330 mm)';

  @override
  String get scanOfflineBody =>
      'Tu móvil descarga el escáner una sola vez. Después funciona sin internet. Mientras tanto, puedes crear un PDF con fotos que ya tengas.';

  @override
  String get scanUnsupportedTitle => 'El escáner no está disponible en este móvil';
}
