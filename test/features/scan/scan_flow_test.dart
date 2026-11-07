import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/core/domain/scanner.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/photos/presentation/photos_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

void main() {
  late FakeScanner scanner;
  late MemoryRecents recents;

  setUp(() {
    scanner = FakeScanner();
    recents = MemoryRecents();
  });

  testWidgets('Inicio: la tarjeta Escanear y las 5 herramientas en el orden del lienzo', (tester) async {
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    expect(find.text('Escanear documento'), findsOneWidget);
    final titles = [
      for (final t in ['Reducir tamaño', 'Unir en uno solo', 'Fotos a PDF', 'Organizar páginas', 'PDF a imagen'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(titles, [...titles]..sort(), reason: 'top to bottom in that order');
  });

  testWidgets('escanear abre Resultado con el escaneo', (tester) async {
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Escaneo listo'), findsOneWidget);
    expect(recents.current.single.name, startsWith('Escaneo '));
    await tester.scrollUntilVisible(
      find.text('Ajustar tamaño'),
      200,
      scrollable: find.descendant(of: find.byType(ResultScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Ajustar tamaño'), findsOneWidget, reason: 'next step');
  });

  testWidgets('cerrar el escáner vuelve a Inicio sin mensaje', (tester) async {
    scanner.nextScan = const Ok(null);
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsNothing);
    expect(recents.current, isEmpty);
  });

  testWidgets('E-SCAN-01: sin módulo y sin conexión ofrece Fotos a PDF', (tester) async {
    scanner.nextScan = const Err(ScannerUnavailable(ScannerIssue.moduleNotDownloaded));
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('El escáner necesita conexión la primera vez'), findsOneWidget);
    await tester.tap(find.text('Crear PDF con fotos'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotosScreen), findsOneWidget);
  });

  testWidgets('E-SCAN-01 sin abrir el escáner cuando ya se sabe que no hay conexión', (tester) async {
    scanner.readiness_ = ScannerReadiness.offline;
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('El escáner necesita conexión la primera vez'), findsOneWidget);
    expect(scanner.scannedTo, isEmpty);
  });

  testWidgets('E-SCAN-02: equipo no compatible, sin abrir el escáner', (tester) async {
    scanner.readiness_ = ScannerReadiness.unsupported;
    await pumpApp(tester, fakeOverrides(scanner: scanner, recents: recents));
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('El escáner no está disponible en este teléfono'), findsOneWidget);
    expect(scanner.scannedTo, isEmpty);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('El escáner no está disponible en este teléfono'), findsNothing);
  });
}
