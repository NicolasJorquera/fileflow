/// Expected failures, one per code of the PRD error catalog (E-xx).
///
/// Presentation maps each case to a localized message; no platform or PDFium
/// exception ever reaches a widget.
sealed class AppFailure {
  const AppFailure();
}

/// E-PDF-01: damaged, truncated or not a PDF.
final class PdfDamaged extends AppFailure {
  const PdfDamaged();
}

/// E-PDF-02: password protected.
final class PdfPasswordRequired extends AppFailure {
  const PdfPasswordRequired();
}

/// E-PDF-03: one page could not be processed and was left as in the original.
final class PageUnreadable extends AppFailure {
  const PageUnreadable(this.page);

  final int page;
}

/// E-IMG-01: some images could not be decoded and were skipped.
final class ImagesUnreadable extends AppFailure {
  const ImagesUnreadable(this.count);

  final int count;
}

/// E-IO-01: access to the source file was lost.
final class SourceAccessLost extends AppFailure {
  const SourceAccessLost();
}

/// E-IO-02: not enough free space; [requiredBytes] is what the job needs.
final class InsufficientStorage extends AppFailure {
  const InsufficientStorage(this.requiredBytes);

  final int requiredBytes;
}

/// E-LIM-01: a hard limit of the tool was exceeded.
final class LimitExceeded extends AppFailure {
  const LimitExceeded(this.limit, this.actual);

  final Limit limit;
  final int actual;
}

enum Limit { pages, files, images, totalBytes }

/// E-SCAN-01 / E-SCAN-02.
final class ScannerUnavailable extends AppFailure {
  const ScannerUnavailable(this.reason);

  final ScannerIssue reason;
}

enum ScannerIssue { moduleNotDownloaded, deviceNotSupported }

/// The user cancelled the job; not shown as an error.
final class Cancelled extends AppFailure {
  const Cancelled();
}

/// E-GEN-01: anything unexpected. [diagnostic] goes to the local log only and
/// must never contain file names or paths.
final class Unexpected extends AppFailure {
  const Unexpected(this.diagnostic);

  final String diagnostic;
}
