import '../../core/domain/failures.dart';
import '../../core/domain/tools.dart';
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
    LimitExceeded(limit: Limit.pages, :final actual) => mergeTooManyPages(actual, MergeLimits.maxPages),
    LimitExceeded(limit: Limit.files) => mergeTooManyFiles(MergeLimits.maxFiles),
    NoAppAvailable() => errNoApp,
    Cancelled() => '',
    ImagesUnreadable() || LimitExceeded() || ScannerUnavailable() || Unexpected() => errGeneric,
  };
}
