import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

void main() {
  late FakePdfService pdf;
  late MemoryRecents recents;

  setUp(() {
    pdf = FakePdfService(pages: {'boleta.pdf': 12, 'grande.pdf': 250});
    recents = MemoryRecents();
  });

  Future<void> open(WidgetTester tester, String name) async {
    final router = await pumpApp(tester, fakeOverrides(pdf: pdf, recents: recents));
    router.push(
      Routes.toImage,
      extra: ToolArgs(
        local: [LocalFile(path: '/in/$name', name: name, sizeBytes: 1258291)],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('12 páginas a 150 dpi en JPG por defecto', (tester) async {
    await open(tester, 'boleta.pdf');
    expect(find.text('boleta.pdf'), findsOneWidget);
    expect(find.text('12 imágenes JPG · unos 3,0 MB en total'), findsOneWidget);

    await tester.tap(find.text('Convertir 12 páginas'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('12 imágenes listas'), findsOneWidget);
    expect(find.text('boleta-p01.jpg'), findsOneWidget);
    expect(find.text('y 8 más'), findsOneWidget);
    final (pages, _, format, dpi) = pdf.exported.single;
    expect((pages.length, format, dpi), (12, ImageFormat.jpeg, 150));
  });

  testWidgets('PNG a 300 dpi con páginas elegidas', (tester) async {
    await open(tester, 'boleta.pdf');
    await tester.tap(find.text('PNG · sin pérdida'));
    await tester.tap(find.text('300 dpi'));
    await tester.tap(find.text('Elegir páginas'));
    await tester.pumpAndSettle();
    for (final p in [1, 2, 3, 7]) {
      await tester.tap(find.bySemanticsLabel('Página $p'));
    }
    await tester.pump();
    await tester.tap(find.text('Usar 4 páginas'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('4 páginas: 1-3, 7'), 100);
    expect(find.text('4 páginas: 1-3, 7'), findsOneWidget);
    await tester.tap(find.text('Convertir 4 páginas'));
    await tester.pumpAndSettle();
    final (pages, outputs, format, dpi) = pdf.exported.single;
    expect((format, dpi), (ImageFormat.png, 300));
    expect(pages, [0, 1, 2, 6]);
    expect(outputs.last, endsWith('/boleta-p07.png'));
  });

  testWidgets('más de 200 páginas pide elegir menos', (tester) async {
    await open(tester, 'grande.pdf');
    expect(find.text('Puedes convertir hasta 200 páginas a la vez. Elige menos páginas.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Convertir 250 páginas')).onPressed, isNull);
  });

  testWidgets('PDF a imagen cumple las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, 'boleta.pdf');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
