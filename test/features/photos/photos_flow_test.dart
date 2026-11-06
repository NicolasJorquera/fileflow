import 'package:fileflow/app/app.dart';
import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

PickedFile _photo(String name) => PickedFile(ref: 'content://media/$name', name: name, sizeBytes: 3000000);

void main() {
  late FakePdfService pdf;
  late FakeFileGateway files;
  late MemoryRecents recents;

  setUp(() {
    pdf = FakePdfService();
    files = FakeFileGateway()..nextImages = [_photo('a.jpg'), _photo('dañada.heic'), _photo('c.png')];
    recents = MemoryRecents();
  });

  testWidgets('3 fotos, una ilegible: se avisa, se omite y el PDF sale con 2 páginas', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(pdf: pdf, files: files, recents: recents),
      at: Routes.photos,
    );

    expect(find.text('3 fotos · mantén presionada una foto para moverla'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto 2 de 3, no se pudo leer'), findsOneWidget);
    expect(find.text('Se omite 1 foto que no se pudo leer.'), findsOneWidget);
    expect(find.text('Carta · automático'), findsOneWidget, reason: 'region CL');

    await tester.tap(find.byTooltip('Girar foto 3'));
    await tester.pump();
    await tester.tap(find.text('Crear PDF · 2 páginas'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('PDF creado con 2 fotos'), findsOneWidget);
    final (photos, spec) = pdf.photoRuns.single;
    expect([for (final p in photos) (p.path.split('/').last, p.quarterTurns)], [('a.jpg', 0), ('c.png', 1)]);
    expect((spec.preset, spec.margin, spec.dpi, spec.quality), (PagePreset.letter, false, 200, 80));
    expect(recents.current.single.name, startsWith('Fotos '));
  });

  testWidgets('tamaño de página, márgenes y calidad llegan al PDF', (tester) async {
    files.nextImages = [_photo('a.jpg')];
    await pumpApp(
      tester,
      fakeOverrides(pdf: pdf, files: files, recents: recents, region: 'ES'),
      at: Routes.photos,
    );
    expect(find.text('A4 · automático'), findsOneWidget);

    await tester.tap(find.text('Tamaño de página'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oficio (216 × 330 mm)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pequeño'));
    await tester.tap(find.text('Alta'));
    await tester.pump();
    await tester.tap(find.text('Crear PDF · 1 página'));
    await tester.pumpAndSettle();

    final spec = pdf.photoRuns.single.$2;
    expect((spec.preset, spec.margin, spec.dpi, spec.quality), (PagePreset.oficio, true, 300, 90));
  });

  testWidgets('quitar una foto se deshace', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(pdf: pdf, files: files, recents: recents),
      at: Routes.photos,
    );
    await tester.tap(find.byTooltip('Quitar foto 1'));
    await tester.pumpAndSettle();
    expect(find.text('2 fotos · mantén presionada una foto para moverla'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('3 fotos · mantén presionada una foto para moverla'), findsOneWidget);
  });

  /// The real app: «Compartir» is handled by FileFlowApp itself.
  Future<void> pumpFileFlow(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeOverrides(pdf: pdf, files: files, recents: recents),
        child: const FileFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fotos compartidas desde otra app abren Fotos a PDF', (tester) async {
    await pumpFileFlow(tester);
    files.incoming.add([
      const PickedFile(ref: 'content://x/1', name: 'boleta.jpg', mime: 'image/jpeg'),
      const PickedFile(ref: 'content://x/2', name: 'boleta2.jpg', mime: 'image/jpeg'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('2 fotos · mantén presionada una foto para moverla'), findsOneWidget);
  });

  testWidgets('un PDF compartido pregunta qué hacer; varios abren Unir', (tester) async {
    await pumpFileFlow(tester);
    files.incoming.add([const PickedFile(ref: 'content://x/1', name: 'cartola.pdf', mime: 'application/pdf')]);
    await tester.pumpAndSettle();
    expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('Fotos a PDF')),
      findsNothing,
      reason: 'only tools that take a PDF',
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    files.incoming.add([
      const PickedFile(ref: 'content://x/1', name: 'a.pdf', mime: 'application/pdf'),
      const PickedFile(ref: 'content://x/2', name: 'b.pdf', mime: 'application/pdf'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Unir 2 archivos'), findsOneWidget);
  });

  testWidgets('Fotos a PDF cumple las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      fakeOverrides(pdf: pdf, files: files, recents: recents),
      at: Routes.photos,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
