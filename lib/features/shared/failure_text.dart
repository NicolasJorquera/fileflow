import '../../core/domain/failures.dart';
import '../../core/format/sizes.dart';
import '../../l10n/app_localizations.dart';

/// The message people read for each [AppFailure] (PRD error catalog). It says
/// what happened and what to do, never a code or a path. [Cancelled] has no
/// message: cancelling is not an error.
extension FailureText on AppLocalizations {
  String failureText(AppFailure failure) => switch (failure) {
    PdfDamaged() || PageUnreadable() => errDamaged,
    PdfPasswordRequired() => errPassword,
    SourceAccessLost() => errAccessLost,
    InsufficientStorage(:final requiredBytes) when requiredBytes > 0 => errNoSpace(
      formatBytes(requiredBytes, localeName),
    ),
    InsufficientStorage() => errNoSpaceGeneric,
    LimitExceeded(limit: Limit.pages, :final actual, :final max) => errTooManyPages(actual, max),
    LimitExceeded(limit: Limit.files, :final max) => mergeTooManyFiles(max),
    NoAppAvailable() => errNoApp,
    ImagesUnreadable(:final count) => errImagesUnreadable(count),
    ScannerUnavailable(reason: ScannerIssue.moduleNotDownloaded) => scanOfflineBody,
    ScannerUnavailable(reason: ScannerIssue.deviceNotSupported) => scanUnsupportedBody,
    AlreadyOptimized() => alreadyOptimizedTitle,
    Cancelled() => '',
    LimitExceeded() || Unexpected() => errGeneric,
  };
}
