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
  String recentsNote(String period) {
    return 'It stays in Recent for $period. Use “Save to…” to keep it on your phone.';
  }

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

  @override
  String get toolOrganizeTitle => 'Organize pages';

  @override
  String get toolOrganizeSubtitle => 'Split, extract, rotate';

  @override
  String get toolToImageTitle => 'PDF to image';

  @override
  String get toolToImageSubtitle => 'JPG or PNG';

  @override
  String get nextToImage => 'Convert to image';

  @override
  String get choosePdf => 'Choose a PDF';

  @override
  String get chooseToolTitle => 'What do you want to do?';

  @override
  String get change => 'Change';

  @override
  String get save => 'Save';

  @override
  String get select => 'Select';

  @override
  String get delete => 'Delete';

  @override
  String get more => 'More';

  @override
  String moreFor(String name) {
    return 'More options for $name';
  }

  @override
  String get rotate => 'Rotate';

  @override
  String get extract => 'Extract';

  @override
  String get selectAll => 'Select all';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count selected', one: '1 selected');
    return '$_temp0';
  }

  @override
  String get moveBefore => 'Move before';

  @override
  String get moveAfter => 'Move after';

  @override
  String pageLabel(int position) {
    return 'Page $position';
  }

  @override
  String pageLabelRotated(int position, int degrees) {
    return 'Page $position, rotated $degrees°';
  }

  @override
  String sourceMeta(String name, int pages) {
    String _temp0 = intl.Intl.pluralLogic(pages, locale: localeName, other: '$pages pages', one: '1 page');
    return '$name · $_temp0';
  }

  @override
  String get organizeEmpty => 'Choose the PDF whose pages you want to reorder, rotate, extract or split.';

  @override
  String get organizeHint => 'Tap pages to select them. Press and hold to move them.';

  @override
  String get organizeLong => 'That is a lot of pages: thumbnails may take a while to appear.';

  @override
  String get organizeKeepOne => 'At least one page must remain.';

  @override
  String organizeDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages deleted',
      one: '1 page deleted',
    );
    return '$_temp0';
  }

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'Your original file does not change.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get splitMenu => 'Split…';

  @override
  String get selectRangeMenu => 'Select a range';

  @override
  String get splitTitle => 'Split into several PDFs';

  @override
  String get splitEvery => 'Every few pages';

  @override
  String get splitEveryLabel => 'Pages per file';

  @override
  String get splitRanges => 'By ranges';

  @override
  String get splitEachPage => 'One page per file';

  @override
  String splitButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split into $count files',
      one: 'Split into 1 file',
    );
    return '$_temp0';
  }

  @override
  String get splitButtonIdle => 'Split';

  @override
  String get rangeLabel => 'Pages';

  @override
  String get rangeHint => '1-3, 5, 8-10';

  @override
  String rangeHelper(int count) {
    return 'From 1 to $count';
  }

  @override
  String get rangeEmpty => 'Type pages, for example 1-3, 5.';

  @override
  String rangeNotANumber(String token) {
    return '“$token” is not a page or a range.';
  }

  @override
  String rangeOutOfRange(String token, int count) {
    return '“$token” is outside the document (1 to $count).';
  }

  @override
  String rangeReversed(String token) {
    return 'In “$token” the first number must be the smaller one.';
  }

  @override
  String nameEdited(String stem) {
    return '$stem (edited)';
  }

  @override
  String namePages(String stem, String pages) {
    return '$stem (pages $pages)';
  }

  @override
  String namePage(String stem, String page) {
    return '$stem (page $page)';
  }

  @override
  String nameSplit(String stem) {
    return '$stem (split)';
  }

  @override
  String nameImages(String stem) {
    return '$stem (images)';
  }

  @override
  String get processingSave => 'Saving…';

  @override
  String get processingExtract => 'Extracting…';

  @override
  String get processingSplit => 'Splitting…';

  @override
  String get processingConvert => 'Converting…';

  @override
  String get toImageEmpty => 'Choose the PDF you want to turn into images.';

  @override
  String get formatLabel => 'Format';

  @override
  String get formatJpg => 'JPG · smaller';

  @override
  String get formatPng => 'PNG · lossless';

  @override
  String get resolutionLabel => 'Resolution';

  @override
  String dpiValue(int dpi) {
    return '$dpi dpi';
  }

  @override
  String get resolutionHelp => '150 dpi: looks good on screen and in WhatsApp. 300 dpi: for printing.';

  @override
  String get pagesLabel => 'Pages';

  @override
  String pagesAll(int count) {
    return 'All ($count)';
  }

  @override
  String get pagesChoose => 'Choose pages';

  @override
  String pagesChosen(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pages', one: '1 page');
    return '$_temp0: $list';
  }

  @override
  String usePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use $count pages',
      one: 'Use 1 page',
      zero: 'Choose pages',
    );
    return '$_temp0';
  }

  @override
  String toImageEstimate(int count, String format, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $format images',
      one: '1 $format image',
    );
    return '$_temp0 · about $size in total';
  }

  @override
  String toImageTooMany(int max) {
    return 'You can convert up to $max pages at a time. Choose fewer pages.';
  }

  @override
  String convertButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convert $count pages',
      one: 'Convert 1 page',
    );
    return '$_temp0';
  }

  @override
  String get resultEdited => 'Changes saved in a new PDF';

  @override
  String resultExtracted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages extracted',
      one: 'Page extracted',
    );
    return '$_temp0';
  }

  @override
  String resultSplit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split into $count files',
      one: 'Split into 1 file',
    );
    return '$_temp0';
  }

  @override
  String resultImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images ready',
      one: '1 image ready',
    );
    return '$_temp0';
  }

  @override
  String filesMeta(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count files', one: '1 file');
    return '$_temp0 · $size';
  }

  @override
  String andMore(int count) {
    return 'and $count more';
  }

  @override
  String get shareAll => 'Share all';

  @override
  String get saveToFolder => 'Save to folder…';

  @override
  String savedFolderSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count files saved', one: '1 file saved');
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get recentsNoteForever => 'It stays in Recent until you delete it.';

  @override
  String recentsNotice(String period) {
    return 'Results delete themselves after $period. You can change this in Settings.';
  }

  @override
  String get recentsNoticeForever => 'Results stay here until you delete them. You can change this in Settings.';

  @override
  String get groupToday => 'Today';

  @override
  String get groupWeek => 'This week';

  @override
  String get groupOlder => 'Earlier';

  @override
  String get tagMerged => 'Merged';

  @override
  String get tagEdited => 'Edited';

  @override
  String get tagExtracted => 'Extracted';

  @override
  String get tagSplit => 'Split';

  @override
  String get tagImages => 'Images';

  @override
  String expiresInDays(String size, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return '$size · deleted in $_temp0';
  }

  @override
  String expiresToday(String size) {
    return '$size · deleted today';
  }

  @override
  String get useInTool => 'Use in another tool';

  @override
  String get clearAll => 'Delete all';

  @override
  String get clearAllTitle => 'Delete all?';

  @override
  String clearAllBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count results', one: '1 result');
    return '$_temp0 ($size) will be deleted. What you saved in other folders does not change.';
  }

  @override
  String get clearAllConfirm => 'Delete';

  @override
  String get recentsEmptyTitle => 'What you create shows up here';

  @override
  String get recentsEmptyBody =>
      'The PDFs and images you create with FileFlow stay here for a while so you can share them again.';

  @override
  String get settingsRecents => 'Recent';

  @override
  String get retentionLabel => 'Delete results automatically';

  @override
  String retentionAfter(String period) {
    return 'After $period';
  }

  @override
  String get retentionNever => 'Never: I delete them';

  @override
  String get retentionShortenTitle => 'Change the period?';

  @override
  String retentionShortenBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count results', one: '1 result');
    return 'With this period $_temp0 ($size) will be deleted now.';
  }

  @override
  String errTooManyPages(int pages, int max) {
    return 'That is $pages pages. The maximum is $max.';
  }

  @override
  String get add => 'Add';

  @override
  String get before => 'Before';

  @override
  String get after => 'Now';

  @override
  String beforeAfter(String before, String after, int percent) {
    return '$before → $after · $percent% smaller';
  }

  @override
  String get alreadyOptimizedTitle => 'This PDF is already optimized';

  @override
  String get alreadyOptimizedBody =>
      'Reducing it would not make it smaller, so we did not create a new file. Your original is fine as it is.';

  @override
  String get choosePhotos => 'Choose photos';

  @override
  String createPdfButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create PDF · $count pages',
      one: 'Create PDF · 1 page',
      zero: 'Create PDF',
    );
    return '$_temp0';
  }

  @override
  String get levelHigh => 'High';

  @override
  String get levelHighHelp => 'For printing or zooming in. Reduces less.';

  @override
  String get levelBalanced => 'Balanced';

  @override
  String get levelBalancedHelp => 'Reads well on screen and in print.';

  @override
  String get levelMinimal => 'Smallest';

  @override
  String get levelMinimalHelp => 'The smallest file; photos lose detail.';

  @override
  String get margins => 'Margins';

  @override
  String get marginNone => 'None';

  @override
  String get marginSmall => 'Small';

  @override
  String namePhotos(String stamp) {
    return 'Photos $stamp';
  }

  @override
  String nameReduced(String stem) {
    return '$stem (reduced)';
  }

  @override
  String nameScan(String stamp) {
    return 'Scan $stamp';
  }

  @override
  String get nextReduce => 'Adjust size';

  @override
  String get originalUnchanged => 'Your original file does not change.';

  @override
  String get pageSize => 'Page size';

  @override
  String get pageAuto => 'Automatic';

  @override
  String pageAutoNamed(String name) {
    return 'Automatic ($name)';
  }

  @override
  String pageAutoShort(String name) {
    return '$name · automatic';
  }

  @override
  String get pageLetter => 'Letter';

  @override
  String get pageOficio => 'Legal-size oficio (216 × 330 mm)';

  @override
  String get pageFitImage => 'Fit to photo';

  @override
  String get pageFitImageHelp => 'Each page is the size of its photo';

  @override
  String get photoQuality => 'Quality';

  @override
  String photoLabel(int position, int count) {
    return 'Photo $position of $count';
  }

  @override
  String photoLabelUnreadable(int position, int count) {
    return 'Photo $position of $count, could not be read';
  }

  @override
  String photoRemoved(int position) {
    return 'Photo $position removed';
  }

  @override
  String get photoUnreadable => 'Could not be read';

  @override
  String rotatePhoto(int position) {
    return 'Rotate photo $position';
  }

  @override
  String removePhoto(int position) {
    return 'Remove photo $position';
  }

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count photos', one: '1 photo');
    return '$_temp0 · press and hold a photo to move it';
  }

  @override
  String get photosEmpty => 'Choose the photos you want to put in a PDF.';

  @override
  String photosEstimate(String size) {
    return 'Estimated size: about $size';
  }

  @override
  String photosSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos that could not be read are left out.',
      one: '1 photo that could not be read is left out.',
    );
    return '$_temp0';
  }

  @override
  String photosTooMany(int max) {
    return 'You can put up to $max photos in one PDF.';
  }

  @override
  String processingFit(String size) {
    return 'Fitting to $size…';
  }

  @override
  String get processingReduce => 'Reducing…';

  @override
  String get processingPhotos => 'Creating the PDF…';

  @override
  String get reduceEmpty => 'Choose the PDF you want to make smaller.';

  @override
  String get reduceHasImages => 'It has images: it can get much smaller';

  @override
  String get reduceTextOnly => 'This PDF is almost all text: it will barely shrink';

  @override
  String get reduceBig => 'It is a big file: it may take a few minutes.';

  @override
  String reduceTooBig(int pages, String size) {
    return 'This PDF is over the limit ($pages pages or $size). Split it and reduce each part.';
  }

  @override
  String get reduceSplitInstead => 'Split into parts';

  @override
  String get reduceHow => 'How do you want to reduce it?';

  @override
  String get reduceModeSize => 'Maximum size';

  @override
  String get reduceModeQuality => 'Quality';

  @override
  String get reduceSizeHelp => 'The limit the website or email asks for';

  @override
  String get reduceOther => 'Other…';

  @override
  String get reduceOtherTitle => 'Maximum size';

  @override
  String get reduceOtherLabel => 'Megabytes';

  @override
  String reduceSizeExplain(String size) {
    return 'We look for the best quality that fits in $size. If it cannot be done, we show you the closest result and tell you.';
  }

  @override
  String get reduceExpected => 'Result';

  @override
  String get reduceExpectedSize => 'Size';

  @override
  String reduceExpectedUnder(String before, String target) {
    return '$before → at most $target';
  }

  @override
  String get reduceSelectableText => 'Selectable text';

  @override
  String get reduceKept => 'Kept';

  @override
  String reduceToButton(String size) {
    return 'Reduce to $size';
  }

  @override
  String get reduceButton => 'Reduce';

  @override
  String resultReduced(int percent) {
    return '$percent% smaller';
  }

  @override
  String resultUnder(String target) {
    return 'It is under $target';
  }

  @override
  String resultMissed(String size, String target) {
    return 'It is $size: it did not reach $target';
  }

  @override
  String get resultMissedHint =>
      'This is as small as it gets without damaging the text. Split the document and reduce each part.';

  @override
  String get resultScanned => 'Scan ready';

  @override
  String resultPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PDF created from $count photos',
      one: 'PDF created from 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get scanTitle => 'Scan document';

  @override
  String get scanSubtitle => 'Auto crop and multiple pages';

  @override
  String get scanButton => 'Scan';

  @override
  String get scanOfflineTitle => 'The scanner needs a connection the first time';

  @override
  String get scanOfflineBody =>
      'Your phone downloads the scanner only once. After that it works offline. Meanwhile, you can create a PDF from photos you already have.';

  @override
  String get scanUnsupportedTitle => 'The scanner is not available on this phone';

  @override
  String get scanUnsupportedBody =>
      'It needs Google Play services and at least 1.7 GB of memory. You can take photos with the camera and create a PDF from them.';

  @override
  String get scanUsePhotos => 'Create a PDF from photos';

  @override
  String get understood => 'Got it';

  @override
  String get tagReduced => 'Reduced';

  @override
  String get tagScanned => 'Scan';

  @override
  String get tagPhotos => 'Photos to PDF';

  @override
  String get toolReduceTitle => 'Reduce size';

  @override
  String get toolReduceSubtitle => 'Get your PDF under 1, 2 or 10 MB to upload it wherever it’s required';

  @override
  String get toolPhotosTitle => 'Photos to PDF';

  @override
  String get toolPhotosSubtitle => 'JPG, PNG, HEIC';

  @override
  String errImagesUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'We couldn’t read $count photos. They may be damaged or in a format the phone can’t open.',
      one: 'We couldn’t read that photo. It may be damaged or in a format the phone can’t open.',
    );
    return '$_temp0';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Same as the phone';

  @override
  String get settingsDocuments => 'Documents';

  @override
  String get defaultPageLabel => 'Page size for photos';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get privacyTitle => 'How we handle your files';

  @override
  String get privacyLocal => 'Everything is processed on your phone. Your documents and photos are never uploaded.';

  @override
  String get privacyNoAccount =>
      'There are no accounts or servers: we don’t ask for your email or keep anything off your phone.';

  @override
  String get privacyRecents => 'Results stay in Recent for as long as you choose and are left out of Google’s backup.';

  @override
  String get privacyScanner =>
      'The scanner is Google Play services’ own and works on the phone: what you scan stays on it.';

  @override
  String get privacyAds =>
      'The app is paid for by ads when there is a connection. Ads never see your documents or appear on screens that show them.';

  @override
  String get aboutTitle => 'About FileFlow';

  @override
  String aboutVersion(String version) {
    return 'Version $version · open source licenses';
  }

  @override
  String get showFirstPage => 'Show first page';

  @override
  String get hideFirstPage => 'Hide first page';

  @override
  String get adsOptionsTitle => 'Ad options';

  @override
  String get adsOptionsBody => 'Consent and personalised ads';
}
