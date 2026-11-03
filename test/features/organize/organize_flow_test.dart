import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/organize/presentation/organize_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

const _contract = LocalFile(path: '/results/r9/contrato.pdf', name: 'contrato.pdf', sizeBytes: 1000);

void main() {
  late FakePdfService pdf;
  late MemoryRecents recents;
  late FakeFileGateway files;

  setUp(() {
    pdf = FakePdfService(pages: {'contrato.pdf': 9, 'libro.pdf': 120});
    recents = MemoryRecents();
    files = FakeFileGateway();
  });

  Future<void> openOrganize(WidgetTester tester, {LocalFile file = _contract}) async {
    final router = await pumpApp(tester, fakeOverrides(pdf: pdf, recents: recents, files: files));
    router.push(Routes.organize, extra: ToolArgs(local: [file]));
    await tester.pumpAndSettle();
  }

  Future<void> tapPage(WidgetTester tester, int position) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Página $position(,|\$)')));
    await tester.pump();
  }

  testWidgets('seleccionar, rotar y guardar crea «nombre (editado).pdf» sin tocar el original', (tester) async {
    await openOrganize(tester);
    expect(find.text('contrato.pdf · 9 págs.'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Guardar')).onPressed, isNull);

    await tapPage(tester, 2);
    await tapPage(tester, 3);
    expect(find.text('2 seleccionadas'), findsOneWidget);
    await tester.tap(find.text('Rotar'));
    await tester.pump();
    expect(find.bySemanticsLabel('Página 2, girada 90°'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Cambios guardados en un PDF nuevo'), findsOneWidget);
    final (input, pages, output) = pdf.composed.single;
    expect(input, _contract.path, reason: 'reads the source, never writes it');
    expect(pages, [const PageRef(0), const PageRef(1, 1), const PageRef(2, 1), for (var i = 3; i < 9; i++) PageRef(i)]);
    expect(output, endsWith('/contrato (editado).pdf'));
  });

  testWidgets('extraer la selección nombra el archivo con sus páginas', (tester) async {
    await openOrganize(tester);
    for (final p in [3, 4, 5, 8]) {
      await tapPage(tester, p);
    }
    await tester.tap(find.text('Extraer'));
    await tester.pumpAndSettle();
    expect(pdf.composed.single.$3, endsWith('/contrato (págs. 3-5, 8).pdf'));
    expect(find.text('4 páginas extraídas'), findsOneWidget);
  });

  testWidgets('eliminar se deshace, y no se puede dejar el documento vacío', (tester) async {
    await openOrganize(tester);
    await tapPage(tester, 1);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('contrato.pdf · 8 págs.'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('contrato.pdf · 9 págs.'), findsOneWidget);

    await tester.tap(find.text('Seleccionar todo'));
    await tester.pump();
    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    expect(find.text('Debe quedar al menos una página.'), findsOneWidget);
    expect(find.text('contrato.pdf · 9 págs.'), findsOneWidget);
  });

  testWidgets('salir con cambios pide confirmar', (tester) async {
    await openOrganize(tester);
    await tapPage(tester, 1);
    await tester.tap(find.text('Rotar'));
    await tester.pump();
    // The system back button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(OrganizeScreen), findsNothing);
  });

  testWidgets('reordenar sin arrastrar con las acciones de TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await openOrganize(tester);
    tester.semantics.customAction(
      find.semantics.byLabel('Página 1'),
      const CustomSemanticsAction(label: 'Mover después'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(pdf.composed.single.$2.take(3), const [PageRef(1), PageRef(0), PageRef(2)]);
    handle.dispose();
  });

  testWidgets('«Mover antes» desde Más mueve la selección', (tester) async {
    await openOrganize(tester);
    await tapPage(tester, 4);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover antes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect([for (final p in pdf.composed.single.$2.take(4)) p.index], [0, 1, 3, 2]);
  });

  testWidgets('seleccionar rango muestra el error en línea y selecciona al corregir', (tester) async {
    await openOrganize(tester);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar rango'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2-12');
    await tester.pump();
    expect(find.text('«2-12» está fuera del documento (1 a 9).'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Seleccionar')).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '2-4, 7');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Seleccionar'));
    await tester.pumpAndSettle();
    expect(find.text('4 seleccionadas'), findsOneWidget);
  });

  testWidgets('separar 120 páginas cada 10 genera 12 archivos con sus nombres, juntos', (tester) async {
    await openOrganize(
      tester,
      file: const LocalFile(path: '/in/libro.pdf', name: 'libro.pdf', sizeBytes: 9),
    );
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Separar…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Separar en 12 archivos'));
    await tester.pumpAndSettle();

    expect(find.text('Separado en 12 archivos'), findsOneWidget);
    final outputs = [for (final c in pdf.composed) c.$3];
    expect(outputs.length, 12);
    expect(outputs.first, '/results/r0/libro (págs. 1-10).pdf');
    expect(outputs.last, '/results/r0/libro (págs. 111-120).pdf');
    expect(pdf.composed[1].$2.first, const PageRef(10));
    final item = recents.current.single;
    expect((item.name, item.files.length), ('libro (separado)', 12));
    expect(find.text('Guardar en carpeta…'), findsOneWidget);

    await tester.tap(find.text('Guardar en carpeta…'));
    await tester.pumpAndSettle();
    expect(find.text('Se guardaron 12 archivos'), findsOneWidget);
  });

  testWidgets('más de 1.000 páginas no se abre', (tester) async {
    pdf = FakePdfService(pages: {'enorme.pdf': 1200});
    await openOrganize(
      tester,
      file: const LocalFile(path: '/in/enorme.pdf', name: 'enorme.pdf', sizeBytes: 9),
    );
    expect(find.text('Son 1200 páginas. El máximo es 1000.'), findsOneWidget);
  });

  testWidgets('Organizar cumple las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    await openOrganize(tester);
    await tapPage(tester, 2);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
