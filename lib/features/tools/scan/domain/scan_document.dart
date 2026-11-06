import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/scanner.dart';
import '../../../../core/domain/tools.dart';

/// Escanear (PRD H1): the system scanner writes straight into a new result.
/// Not a queued job: the scanner is a screen of its own.
class ScanDocument {
  ScanDocument({required this._scanner, required this._recents});

  final ScannerGateway _scanner;
  final RecentsRepository _recents;

  /// Ok(null) when the user closes the scanner without scanning.
  Future<Result<RecentItem?>> call({required String name}) async {
    final slot = await _recents.reserve(name);
    final scanned = await _scanner.scan(maxPages: ScanLimits.maxPages, destPath: slot.path);
    switch (scanned) {
      case Ok(value: final pages?):
        return Ok(await _recents.add(slot, kind: ResultKind.scanned, pages: pages));
      case Ok():
        await _recents.discard(slot);
        return const Ok(null);
      case Err(:final failure):
        await _recents.discard(slot);
        return Err(failure);
    }
  }
}
