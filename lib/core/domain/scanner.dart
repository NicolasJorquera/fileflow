import 'result.dart';

/// [offline]: the scanner module is not on the phone and there is no
/// connection to fetch it (E-SCAN-01).
enum ScannerReadiness { ready, needsDownload, offline, unsupported }

/// The system document scanner (PRD H1): edge detection, crop and pages all
/// happen in its own UI; the app receives one PDF.
abstract interface class ScannerGateway {
  Future<ScannerReadiness> readiness();

  /// Lets the platform download what the scanner needs while there is a
  /// connection, so it later works offline. Safe to call at every start.
  Future<void> prepare();

  /// Opens the scanner and writes the scanned PDF to [destPath]. Ok(page
  /// count), Ok(null) when the user cancels, or ScannerUnavailable.
  Future<Result<int?>> scan({required int maxPages, required String destPath});
}
