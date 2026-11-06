import 'package:platform_files/platform_files.dart';

import '../../core/domain/failures.dart';
import '../../core/domain/result.dart';
import '../../core/domain/scanner.dart';

/// [ScannerGateway] on ML Kit's document scanner through platform_files.
class MlKitScannerGateway implements ScannerGateway {
  const MlKitScannerGateway(this._api);

  final PlatformFilesApi _api;

  @override
  Future<ScannerReadiness> readiness() async {
    try {
      return switch (await _api.scannerStatus()) {
        'ready' => ScannerReadiness.ready,
        'unsupported' => ScannerReadiness.unsupported,
        'offline' => ScannerReadiness.offline,
        _ => ScannerReadiness.needsDownload,
      };
    } on PlatformFilesException {
      return ScannerReadiness.unsupported;
    }
  }

  @override
  Future<void> prepare() async {
    try {
      await _api.prepareScanner();
    } on PlatformFilesException {
      // Best effort: the scanner reports the problem when it is opened.
    }
  }

  @override
  Future<Result<int?>> scan({required int maxPages, required String destPath}) async {
    // Offline without the module, Google Play services would only show its
    // own «Can't reach the Internet» screen: say it ourselves (E-SCAN-01).
    switch (await readiness()) {
      case ScannerReadiness.offline:
        return const Err(ScannerUnavailable(ScannerIssue.moduleNotDownloaded));
      case ScannerReadiness.unsupported:
        return const Err(ScannerUnavailable(ScannerIssue.deviceNotSupported));
      case ScannerReadiness.ready || ScannerReadiness.needsDownload:
        break;
    }
    try {
      return Ok(await _api.scanDocument(maxPages: maxPages, destPath: destPath));
    } on PlatformFilesException catch (e) {
      return Err(switch (e.code) {
        PlatformFilesException.scannerModuleMissing => const ScannerUnavailable(ScannerIssue.moduleNotDownloaded),
        PlatformFilesException.scannerUnsupported ||
        PlatformFilesException.notImplemented => const ScannerUnavailable(ScannerIssue.deviceNotSupported),
        PlatformFilesException.noSpace => const InsufficientStorage(0),
        _ => Unexpected('scanner:${e.code}'),
      });
    }
  }
}
