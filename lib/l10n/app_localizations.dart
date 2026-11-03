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
  /// **'Queda en Recientes por 7 días. Usa «Guardar en…» para conservarlo en tu teléfono.'**
  String get recentsNote;

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
