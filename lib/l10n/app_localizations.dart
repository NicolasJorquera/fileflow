import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('es', 'ES'), Locale('pt')];

  /// Product name. Trademark search still pending (Legal).
  ///
  /// In es, this message translates to:
  /// **'FileFlow'**
  String get appName;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Section header in Settings.
  ///
  /// In es, this message translates to:
  /// **'Apariencia e idioma'**
  String get settingsAppearance;

  /// No description provided for @themeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @privacyNote.
  ///
  /// In es, this message translates to:
  /// **'Todo se procesa en tu teléfono. Funciona sin conexión.'**
  String get privacyNote;

  /// No description provided for @pageCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 página} other{{count} páginas}}'**
  String pageCount(int count);

  /// No description provided for @homeSection.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas hacer?'**
  String get homeSection;

  /// No description provided for @recentTitle.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get recentTitle;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get seeAll;

  /// No description provided for @toolMergeTitle.
  ///
  /// In es, this message translates to:
  /// **'Unir en uno solo'**
  String get toolMergeTitle;

  /// No description provided for @toolMergeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Unir PDF'**
  String get toolMergeSubtitle;

  /// No description provided for @interruptedNotice.
  ///
  /// In es, this message translates to:
  /// **'La operación anterior se interrumpió. Tus archivos originales no cambiaron.'**
  String get interruptedNotice;

  /// No description provided for @mergeHint.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para cambiar el orden. Se unen de arriba hacia abajo.'**
  String get mergeHint;

  /// No description provided for @mergeAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar PDF'**
  String get mergeAdd;

  /// No description provided for @mergeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos 2 PDF para unirlos en uno solo.'**
  String get mergeEmpty;

  /// No description provided for @mergeSummary.
  ///
  /// In es, this message translates to:
  /// **'{files, plural, one{1 archivo} other{{files} archivos}} · {pages, plural, one{1 página} other{{pages} páginas}}'**
  String mergeSummary(int files, int pages);

  /// No description provided for @mergeButton.
  ///
  /// In es, this message translates to:
  /// **'{files, plural, one{Unir 1 archivo} other{Unir {files} archivos}}'**
  String mergeButton(int files);

  /// No description provided for @mergeNeedTwo.
  ///
  /// In es, this message translates to:
  /// **'Agrega al menos 2 PDF'**
  String get mergeNeedTwo;

  /// No description provided for @mergeSkipped.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Se omite 1 archivo con problemas.} other{Se omiten {count} archivos con problemas.}}'**
  String mergeSkipped(int count);

  /// No description provided for @mergeTooManyPages.
  ///
  /// In es, this message translates to:
  /// **'Son {pages} páginas. El máximo para unir es {max}.'**
  String mergeTooManyPages(int pages, int max);

  /// No description provided for @mergeTooManyFiles.
  ///
  /// In es, this message translates to:
  /// **'Puedes unir hasta {max} archivos a la vez.'**
  String mergeTooManyFiles(int max);

  /// No description provided for @mergeBig.
  ///
  /// In es, this message translates to:
  /// **'Son muchos MB: puede tardar unos minutos.'**
  String get mergeBig;

  /// Default name of a merged PDF, without extension.
  ///
  /// In es, this message translates to:
  /// **'Documento unido {date}'**
  String mergedName(String date);

  /// No description provided for @itemPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando…'**
  String get itemPreparing;

  /// No description provided for @itemMeta.
  ///
  /// In es, this message translates to:
  /// **'{pages, plural, one{1 pág.} other{{pages} págs.}} · {size}'**
  String itemMeta(int pages, String size);

  /// No description provided for @removeItem.
  ///
  /// In es, this message translates to:
  /// **'Quitar {name}'**
  String removeItem(String name);

  /// No description provided for @moveItem.
  ///
  /// In es, this message translates to:
  /// **'Mover {name}'**
  String moveItem(String name);

  /// No description provided for @moveUp.
  ///
  /// In es, this message translates to:
  /// **'Mover arriba'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In es, this message translates to:
  /// **'Mover abajo'**
  String get moveDown;

  /// No description provided for @removedSnack.
  ///
  /// In es, this message translates to:
  /// **'Se quitó {name}'**
  String removedSnack(String name);

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @processingMerge.
  ///
  /// In es, this message translates to:
  /// **'Uniendo…'**
  String get processingMerge;

  /// No description provided for @processingStep.
  ///
  /// In es, this message translates to:
  /// **'Paso {done} de {total}'**
  String processingStep(int done, int total);

  /// No description provided for @processingHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes ir a otra pantalla: seguimos trabajando mientras la app esté abierta.'**
  String get processingHint;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @cancelConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar?'**
  String get cancelConfirmTitle;

  /// No description provided for @cancelConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se descarta lo avanzado. Tus archivos originales no cambian.'**
  String get cancelConfirmBody;

  /// No description provided for @keepGoing.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get keepGoing;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @resultTitle.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get resultTitle;

  /// No description provided for @resultMerged.
  ///
  /// In es, this message translates to:
  /// **'Unido en un solo PDF'**
  String get resultMerged;

  /// No description provided for @resultMeta.
  ///
  /// In es, this message translates to:
  /// **'{pages, plural, one{1 página} other{{pages} páginas}} · {size}'**
  String resultMeta(int pages, String size);

  /// No description provided for @fileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del archivo'**
  String get fileNameLabel;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @saveTo.
  ///
  /// In es, this message translates to:
  /// **'Guardar en…'**
  String get saveTo;

  /// No description provided for @openWith.
  ///
  /// In es, this message translates to:
  /// **'Abrir con otra app'**
  String get openWith;

  /// No description provided for @nextStep.
  ///
  /// In es, this message translates to:
  /// **'Siguiente paso'**
  String get nextStep;

  /// No description provided for @nextMergeAnother.
  ///
  /// In es, this message translates to:
  /// **'Unir con otro PDF'**
  String get nextMergeAnother;

  /// No description provided for @recentsNote.
  ///
  /// In es, this message translates to:
  /// **'Queda en Recientes por {period}. Usa «Guardar en…» para conservarlo en tu teléfono.'**
  String recentsNote(String period);

  /// No description provided for @savedSnack.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get savedSnack;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @errDamaged.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir este archivo. Puede estar dañado o no ser un PDF.'**
  String get errDamaged;

  /// No description provided for @errPassword.
  ///
  /// In es, this message translates to:
  /// **'Este PDF tiene contraseña. Esta versión todavía no puede abrirlo.'**
  String get errPassword;

  /// No description provided for @errAccessLost.
  ///
  /// In es, this message translates to:
  /// **'Ya no tenemos acceso a ese archivo. Vuelve a elegirlo.'**
  String get errAccessLost;

  /// No description provided for @errNoSpace.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio suficiente. Necesitas unos {size} libres.'**
  String errNoSpace(String size);

  /// No description provided for @errNoSpaceGeneric.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio suficiente en el teléfono.'**
  String get errNoSpaceGeneric;

  /// No description provided for @errNoApp.
  ///
  /// In es, this message translates to:
  /// **'No hay una app para abrir este archivo.'**
  String get errNoApp;

  /// No description provided for @errGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo falló al procesar el archivo. Tu original no cambió.'**
  String get errGeneric;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @processingPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent} %'**
  String processingPercent(int percent);

  /// No description provided for @toolOrganizeTitle.
  ///
  /// In es, this message translates to:
  /// **'Organizar páginas'**
  String get toolOrganizeTitle;

  /// No description provided for @toolOrganizeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Separar, extraer, rotar'**
  String get toolOrganizeSubtitle;

  /// No description provided for @toolToImageTitle.
  ///
  /// In es, this message translates to:
  /// **'PDF a imagen'**
  String get toolToImageTitle;

  /// No description provided for @toolToImageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'JPG o PNG'**
  String get toolToImageSubtitle;

  /// No description provided for @nextToImage.
  ///
  /// In es, this message translates to:
  /// **'Convertir a imagen'**
  String get nextToImage;

  /// No description provided for @choosePdf.
  ///
  /// In es, this message translates to:
  /// **'Elegir un PDF'**
  String get choosePdf;

  /// No description provided for @chooseToolTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get chooseToolTitle;

  /// No description provided for @change.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get change;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @select.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get select;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @more.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get more;

  /// No description provided for @moreFor.
  ///
  /// In es, this message translates to:
  /// **'Más opciones para {name}'**
  String moreFor(String name);

  /// No description provided for @rotate.
  ///
  /// In es, this message translates to:
  /// **'Rotar'**
  String get rotate;

  /// No description provided for @extract.
  ///
  /// In es, this message translates to:
  /// **'Extraer'**
  String get extract;

  /// No description provided for @selectAll.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar todo'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In es, this message translates to:
  /// **'Quitar selección'**
  String get clearSelection;

  /// No description provided for @selectedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 seleccionada} other{{count} seleccionadas}}'**
  String selectedCount(int count);

  /// No description provided for @moveBefore.
  ///
  /// In es, this message translates to:
  /// **'Mover antes'**
  String get moveBefore;

  /// No description provided for @moveAfter.
  ///
  /// In es, this message translates to:
  /// **'Mover después'**
  String get moveAfter;

  /// No description provided for @pageLabel.
  ///
  /// In es, this message translates to:
  /// **'Página {position}'**
  String pageLabel(int position);

  /// No description provided for @pageLabelRotated.
  ///
  /// In es, this message translates to:
  /// **'Página {position}, girada {degrees}°'**
  String pageLabelRotated(int position, int degrees);

  /// No description provided for @sourceMeta.
  ///
  /// In es, this message translates to:
  /// **'{name} · {pages, plural, one{1 pág.} other{{pages} págs.}}'**
  String sourceMeta(String name, int pages);

  /// No description provided for @organizeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elige el PDF cuyas páginas quieres ordenar, rotar, extraer o separar.'**
  String get organizeEmpty;

  /// No description provided for @organizeHint.
  ///
  /// In es, this message translates to:
  /// **'Toca las páginas para elegirlas. Mantén presionado para moverlas.'**
  String get organizeHint;

  /// No description provided for @organizeLong.
  ///
  /// In es, this message translates to:
  /// **'Son muchas páginas: las miniaturas pueden tardar en aparecer.'**
  String get organizeLong;

  /// No description provided for @organizeKeepOne.
  ///
  /// In es, this message translates to:
  /// **'Debe quedar al menos una página.'**
  String get organizeKeepOne;

  /// No description provided for @organizeDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Se eliminó 1 página} other{Se eliminaron {count} páginas}}'**
  String organizeDeleted(int count);

  /// No description provided for @discardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In es, this message translates to:
  /// **'Tu archivo original no cambia.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get keepEditing;

  /// No description provided for @splitMenu.
  ///
  /// In es, this message translates to:
  /// **'Separar…'**
  String get splitMenu;

  /// No description provided for @selectRangeMenu.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar rango'**
  String get selectRangeMenu;

  /// No description provided for @splitTitle.
  ///
  /// In es, this message translates to:
  /// **'Separar en varios PDF'**
  String get splitTitle;

  /// No description provided for @splitEvery.
  ///
  /// In es, this message translates to:
  /// **'Cada cierto número de páginas'**
  String get splitEvery;

  /// No description provided for @splitEveryLabel.
  ///
  /// In es, this message translates to:
  /// **'Páginas por archivo'**
  String get splitEveryLabel;

  /// No description provided for @splitRanges.
  ///
  /// In es, this message translates to:
  /// **'Por rangos'**
  String get splitRanges;

  /// No description provided for @splitEachPage.
  ///
  /// In es, this message translates to:
  /// **'Una página por archivo'**
  String get splitEachPage;

  /// No description provided for @splitButton.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Separar en 1 archivo} other{Separar en {count} archivos}}'**
  String splitButton(int count);

  /// No description provided for @splitButtonIdle.
  ///
  /// In es, this message translates to:
  /// **'Separar'**
  String get splitButtonIdle;

  /// No description provided for @rangeLabel.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get rangeLabel;

  /// No description provided for @rangeHint.
  ///
  /// In es, this message translates to:
  /// **'1-3, 5, 8-10'**
  String get rangeHint;

  /// No description provided for @rangeHelper.
  ///
  /// In es, this message translates to:
  /// **'Del 1 al {count}'**
  String rangeHelper(int count);

  /// No description provided for @rangeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe páginas, por ejemplo 1-3, 5.'**
  String get rangeEmpty;

  /// No description provided for @rangeNotANumber.
  ///
  /// In es, this message translates to:
  /// **'«{token}» no es una página ni un rango.'**
  String rangeNotANumber(String token);

  /// No description provided for @rangeOutOfRange.
  ///
  /// In es, this message translates to:
  /// **'«{token}» está fuera del documento (1 a {count}).'**
  String rangeOutOfRange(String token, int count);

  /// No description provided for @rangeReversed.
  ///
  /// In es, this message translates to:
  /// **'En «{token}» el primer número debe ser el menor.'**
  String rangeReversed(String token);

  /// No description provided for @nameEdited.
  ///
  /// In es, this message translates to:
  /// **'{stem} (editado)'**
  String nameEdited(String stem);

  /// No description provided for @namePages.
  ///
  /// In es, this message translates to:
  /// **'{stem} (págs. {pages})'**
  String namePages(String stem, String pages);

  /// No description provided for @namePage.
  ///
  /// In es, this message translates to:
  /// **'{stem} (pág. {page})'**
  String namePage(String stem, String page);

  /// No description provided for @nameSplit.
  ///
  /// In es, this message translates to:
  /// **'{stem} (separado)'**
  String nameSplit(String stem);

  /// No description provided for @nameImages.
  ///
  /// In es, this message translates to:
  /// **'{stem} (imágenes)'**
  String nameImages(String stem);

  /// No description provided for @processingSave.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get processingSave;

  /// No description provided for @processingExtract.
  ///
  /// In es, this message translates to:
  /// **'Extrayendo…'**
  String get processingExtract;

  /// No description provided for @processingSplit.
  ///
  /// In es, this message translates to:
  /// **'Separando…'**
  String get processingSplit;

  /// No description provided for @processingConvert.
  ///
  /// In es, this message translates to:
  /// **'Convirtiendo…'**
  String get processingConvert;

  /// No description provided for @toImageEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elige el PDF que quieres convertir en imágenes.'**
  String get toImageEmpty;

  /// No description provided for @formatLabel.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get formatLabel;

  /// No description provided for @formatJpg.
  ///
  /// In es, this message translates to:
  /// **'JPG · más liviano'**
  String get formatJpg;

  /// No description provided for @formatPng.
  ///
  /// In es, this message translates to:
  /// **'PNG · sin pérdida'**
  String get formatPng;

  /// No description provided for @resolutionLabel.
  ///
  /// In es, this message translates to:
  /// **'Resolución'**
  String get resolutionLabel;

  /// No description provided for @dpiValue.
  ///
  /// In es, this message translates to:
  /// **'{dpi} dpi'**
  String dpiValue(int dpi);

  /// No description provided for @resolutionHelp.
  ///
  /// In es, this message translates to:
  /// **'150 dpi: se ve bien en pantalla y en WhatsApp. 300 dpi: para imprimir.'**
  String get resolutionHelp;

  /// No description provided for @pagesLabel.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get pagesLabel;

  /// No description provided for @pagesAll.
  ///
  /// In es, this message translates to:
  /// **'Todas ({count})'**
  String pagesAll(int count);

  /// No description provided for @pagesChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir páginas'**
  String get pagesChoose;

  /// No description provided for @pagesChosen.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 página} other{{count} páginas}}: {list}'**
  String pagesChosen(int count, String list);

  /// No description provided for @usePages.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Elige páginas} one{Usar 1 página} other{Usar {count} páginas}}'**
  String usePages(int count);

  /// No description provided for @toImageEstimate.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 imagen {format}} other{{count} imágenes {format}}} · unos {size} en total'**
  String toImageEstimate(int count, String format, String size);

  /// No description provided for @toImageTooMany.
  ///
  /// In es, this message translates to:
  /// **'Puedes convertir hasta {max} páginas a la vez. Elige menos páginas.'**
  String toImageTooMany(int max);

  /// No description provided for @convertButton.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Convertir 1 página} other{Convertir {count} páginas}}'**
  String convertButton(int count);

  /// No description provided for @resultEdited.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados en un PDF nuevo'**
  String get resultEdited;

  /// No description provided for @resultExtracted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Página extraída} other{{count} páginas extraídas}}'**
  String resultExtracted(int count);

  /// No description provided for @resultSplit.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Separado en 1 archivo} other{Separado en {count} archivos}}'**
  String resultSplit(int count);

  /// No description provided for @resultImages.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 imagen lista} other{{count} imágenes listas}}'**
  String resultImages(int count);

  /// No description provided for @filesMeta.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 archivo} other{{count} archivos}} · {size}'**
  String filesMeta(int count, String size);

  /// No description provided for @andMore.
  ///
  /// In es, this message translates to:
  /// **'y {count} más'**
  String andMore(int count);

  /// No description provided for @shareAll.
  ///
  /// In es, this message translates to:
  /// **'Compartir todo'**
  String get shareAll;

  /// No description provided for @saveToFolder.
  ///
  /// In es, this message translates to:
  /// **'Guardar en carpeta…'**
  String get saveToFolder;

  /// No description provided for @savedFolderSnack.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Se guardó 1 archivo} other{Se guardaron {count} archivos}}'**
  String savedFolderSnack(int count);

  /// No description provided for @daysCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 día} other{{count} días}}'**
  String daysCount(int count);

  /// No description provided for @recentsNoteForever.
  ///
  /// In es, this message translates to:
  /// **'Queda en Recientes hasta que lo borres.'**
  String get recentsNoteForever;

  /// No description provided for @recentsNotice.
  ///
  /// In es, this message translates to:
  /// **'Los resultados se borran solos a los {period}. Puedes cambiarlo en Ajustes.'**
  String recentsNotice(String period);

  /// No description provided for @recentsNoticeForever.
  ///
  /// In es, this message translates to:
  /// **'Los resultados quedan aquí hasta que los borres. Puedes cambiarlo en Ajustes.'**
  String get recentsNoticeForever;

  /// No description provided for @groupToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get groupToday;

  /// No description provided for @groupWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get groupWeek;

  /// No description provided for @groupOlder.
  ///
  /// In es, this message translates to:
  /// **'Antes'**
  String get groupOlder;

  /// No description provided for @tagMerged.
  ///
  /// In es, this message translates to:
  /// **'Unido'**
  String get tagMerged;

  /// No description provided for @tagEdited.
  ///
  /// In es, this message translates to:
  /// **'Editado'**
  String get tagEdited;

  /// No description provided for @tagExtracted.
  ///
  /// In es, this message translates to:
  /// **'Extraído'**
  String get tagExtracted;

  /// No description provided for @tagSplit.
  ///
  /// In es, this message translates to:
  /// **'Separado'**
  String get tagSplit;

  /// No description provided for @tagImages.
  ///
  /// In es, this message translates to:
  /// **'Imágenes'**
  String get tagImages;

  /// No description provided for @expiresInDays.
  ///
  /// In es, this message translates to:
  /// **'{size} · se borra en {days, plural, one{1 día} other{{days} días}}'**
  String expiresInDays(String size, int days);

  /// No description provided for @expiresToday.
  ///
  /// In es, this message translates to:
  /// **'{size} · se borra hoy'**
  String expiresToday(String size);

  /// No description provided for @useInTool.
  ///
  /// In es, this message translates to:
  /// **'Usar en otra herramienta'**
  String get useInTool;

  /// No description provided for @clearAll.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get clearAll;

  /// No description provided for @clearAllTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todo?'**
  String get clearAllTitle;

  /// No description provided for @clearAllBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán {count, plural, one{1 resultado} other{{count} resultados}} ({size}). Lo que guardaste en otras carpetas no cambia.'**
  String clearAllBody(int count, String size);

  /// No description provided for @clearAllConfirm.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get clearAllConfirm;

  /// No description provided for @recentsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás lo que crees'**
  String get recentsEmptyTitle;

  /// No description provided for @recentsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Los PDF e imágenes que crees con FileFlow quedan aquí un tiempo para que puedas volver a compartirlos.'**
  String get recentsEmptyBody;

  /// No description provided for @settingsRecents.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get settingsRecents;

  /// No description provided for @retentionLabel.
  ///
  /// In es, this message translates to:
  /// **'Borrar resultados automáticamente'**
  String get retentionLabel;

  /// No description provided for @retentionAfter.
  ///
  /// In es, this message translates to:
  /// **'Después de {period}'**
  String retentionAfter(String period);

  /// No description provided for @retentionNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca: los borro yo'**
  String get retentionNever;

  /// No description provided for @retentionShortenTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cambiar el plazo?'**
  String get retentionShortenTitle;

  /// No description provided for @retentionShortenBody.
  ///
  /// In es, this message translates to:
  /// **'Con este plazo se borran ahora {count, plural, one{1 resultado} other{{count} resultados}} ({size}).'**
  String retentionShortenBody(int count, String size);

  /// No description provided for @errTooManyPages.
  ///
  /// In es, this message translates to:
  /// **'Son {pages} páginas. El máximo es {max}.'**
  String errTooManyPages(int pages, int max);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'ES':
            return AppLocalizationsEsEs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
