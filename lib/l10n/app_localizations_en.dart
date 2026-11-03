// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FileFlow';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance and language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get privacyNote => 'Everything is processed on your phone. Works offline.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pages', one: '1 page');
    return '$_temp0';
  }

  @override
  String get homeSection => 'What do you need to do?';

  @override
  String get recentTitle => 'Recent';

  @override
  String get seeAll => 'See all';

  @override
  String get toolMergeTitle => 'Merge into one';

  @override
  String get toolMergeSubtitle => 'Merge PDF';

  @override
  String get interruptedNotice => 'The previous task was interrupted. Your original files did not change.';

  @override
  String get mergeHint => 'Drag to change the order. Files are merged from top to bottom.';

  @override
  String get mergeAdd => 'Add PDF';

  @override
  String get mergeEmpty => 'Choose at least 2 PDFs to merge them into one.';

  @override
  String mergeSummary(int files, int pages) {
    String _temp0 = intl.Intl.pluralLogic(files, locale: localeName, other: '$files files', one: '1 file');
    String _temp1 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages pages', one: '1 page');
    return '$_temp0 · $_temp1';
  }

  @override
  String mergeButton(int files) {
    String _temp0 = intl.Intl.pluralLogic(files, locale: localeName, other: 'Merge $files files', one: 'Merge 1 file');
    return '$_temp0';
  }

  @override
  String get mergeNeedTwo => 'Add at least 2 PDFs';

  @override
  String mergeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files with problems are skipped.',
      one: '1 file with problems is skipped.',
    );
    return '$_temp0';
  }

  @override
  String mergeTooManyPages(int pages, int max) {
    return 'That is $pages pages. You can merge up to $max.';
  }

  @override
  String mergeTooManyFiles(int max) {
    return 'You can merge up to $max files at a time.';
  }

  @override
  String get mergeBig => 'That is a lot of MB: it may take a few minutes.';

  @override
  String mergedName(String date) {
    return 'Merged document $date';
  }

  @override
  String get itemPreparing => 'Preparing…';

  @override
  String itemMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages pages', one: '1 page');
    return '$_temp0 · $size';
  }

  @override
  String removeItem(String name) {
    return 'Remove $name';
  }

  @override
  String moveItem(String name) {
    return 'Move $name';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String removedSnack(String name) {
    return '$name removed';
  }

  @override
  String get undo => 'Undo';

  @override
  String get processingMerge => 'Merging…';

  @override
  String processingStep(int done, int total) {
    return 'Step $done of $total';
  }

  @override
  String get processingHint => 'You can go to another screen: we keep working while the app is open.';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelConfirmTitle => 'Cancel?';

  @override
  String get cancelConfirmBody => 'Progress so far is discarded. Your original files do not change.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get back => 'Back';

  @override
  String get resultTitle => 'Done';

  @override
  String get resultMerged => 'Merged into one PDF';

  @override
  String resultMeta(int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages pages', one: '1 page');
    return '$_temp0 · $size';
  }

  @override
  String get fileNameLabel => 'File name';

  @override
  String get share => 'Share';

  @override
  String get saveTo => 'Save to…';

  @override
  String get openWith => 'Open with another app';

  @override
  String get nextStep => 'Next step';

  @override
  String get nextMergeAnother => 'Merge with another PDF';

  @override
  String get recentsNote => 'It stays in Recent for 7 days. Use “Save to…” to keep it on your phone.';

  @override
  String get savedSnack => 'Saved';

  @override
  String get close => 'Close';

  @override
  String get errDamaged => 'We couldn’t open this file. It may be damaged or not a PDF.';

  @override
  String get errPassword => 'This PDF has a password. This version can’t open it yet.';

  @override
  String get errAccessLost => 'We no longer have access to that file. Choose it again.';

  @override
  String errNoSpace(String size) {
    return 'Not enough space. You need about $size free.';
  }

  @override
  String get errNoSpaceGeneric => 'Not enough space on your phone.';

  @override
  String get errNoApp => 'There is no app to open this file.';

  @override
  String get errGeneric => 'Something went wrong processing the file. Your original did not change.';

  @override
  String get retry => 'Try again';

  @override
  String processingPercent(int percent) {
    return '$percent%';
  }
}
