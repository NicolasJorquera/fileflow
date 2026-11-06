import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/features/tools/scan/domain/scan_document.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeScanner scanner;
  late MemoryRecents recents;
  late ScanDocument scan;

  setUp(() {
    scanner = FakeScanner();
    recents = MemoryRecents();
    scan = ScanDocument(scanner: scanner, recents: recents);
  });

  test('a scan goes straight into Recientes', () async {
    final item = (await scan(name: 'Escaneo 2026-11-03 19.23.pdf')).valueOrNull!;
    expect((item.kind, item.pages, item.name), (ResultKind.scanned, 2, 'Escaneo 2026-11-03 19.23.pdf'));
    expect(scanner.scannedTo.single, item.path);
  });

  test('closing the scanner leaves nothing and says nothing', () async {
    scanner.nextScan = const Ok(null);
    expect((await scan(name: 'x.pdf')).valueOrNull, isNull);
    expect(recents.current, isEmpty);
    expect(recents.discarded, hasLength(1));
  });

  test('E-SCAN-01 comes back as is', () async {
    scanner.nextScan = const Err(ScannerUnavailable(ScannerIssue.moduleNotDownloaded));
    final result = await scan(name: 'x.pdf');
    expect(result, isA<Err<RecentItem?>>());
    expect(recents.discarded, hasLength(1));
  });
}
