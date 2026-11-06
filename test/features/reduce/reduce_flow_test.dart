import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

const _mb = 1024 * 1024;

void main() {
  late FakePdfService pdf;
  late MemoryRecents recents;

  setUp(() {
    pdf = FakePdfService(pages: {'cartola.pdf': 12, 'texto.pdf': 50, 'enorme.pdf': 600})..inputBytes = 28 * _mb;
    recents = MemoryRecents();
  });

  Future<void> open(WidgetTester tester, String name, {int size = 28 * _mb}) async {
    final router = await pumpApp(tester, fakeOverrides(pdf: pdf, recents: recents));
    router.push(
      Routes.reduce,
      extra: ToolArgs(
        local: [LocalFile(path: '/in/$name', name: name, sizeBytes: size)],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ajustar a 2 MB: elige el nivel según la muestra y guarda la meta', (tester) async {
    pdf.reduceRatios = {
      ReduceLevel.high: 0.5,
      ReduceLevel.balanced: 0.2,
      ReduceLevel.minimal: 0.06,
      ReduceLevel.extra: 0.04,
    };
    await open(tester, 'cartola.pdf');
    expect(find.text('Tiene imágenes: se puede reducir bastante'), findsOneWidget);
    expect(find.text('28,0 MB → máximo 2 MB'), findsOneWidget);

    recents.nextSize = (1.7 * _mb).round();
    await tester.tap(find.text('Reducir a 2 MB'));
    await tester.pumpAndSettle();

    expect(pdf.reducedAt, [ReduceLevel.minimal]);
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Quedó bajo 2 MB'), findsOneWidget);
    expect(find.text('28,0 MB → 1,7 MB · 94 % menos'), findsOneWidget);
    expect(recents.current.single.name, 'cartola (reducido).pdf');
  });

  testWidgets('si no alcanza la meta lo dice y sugiere separar (RN-04)', (tester) async {
    await open(tester, 'cartola.pdf');
    await tester.tap(find.text('1 MB'));
    await tester.pump();
    recents.nextSize = (2.6 * _mb).round();
    await tester.tap(find.text('Reducir a 1 MB'));
    await tester.pumpAndSettle();

    expect(find.text('Quedó en 2,6 MB: no alcanzó 1 MB'), findsOneWidget);
    expect(find.textContaining('Separa el documento en partes'), findsOneWidget);
  });

  testWidgets('«Otro…» acepta un tamaño propio', (tester) async {
    await open(tester, 'cartola.pdf');
    await tester.tap(find.text('Otro…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1,5');
    await tester.pump();
    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    expect(find.text('Reducir a 1,5 MB'), findsOneWidget);
  });

  testWidgets('modo calidad: un PDF de solo texto queda «ya optimizado» sin archivo', (tester) async {
    pdf.imagesChanged = 0;
    await open(tester, 'texto.pdf', size: 120000);
    await tester.tap(find.text('Calidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reducir'));
    await tester.pumpAndSettle();

    expect(find.text('Este PDF ya está optimizado'), findsOneWidget);
    expect(recents.current, isEmpty);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Reducir'), findsOneWidget);
  });

  testWidgets('sobre el límite duro ofrece separar en lugar de reducir', (tester) async {
    await open(tester, 'enorme.pdf');
    expect(find.textContaining('Este PDF supera el máximo (500 páginas'), findsOneWidget);
    expect(find.text('Separar en partes'), findsOneWidget);
    expect(find.text('Reducir a 2 MB'), findsNothing);
  });

  testWidgets('Reducir cumple las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, 'cartola.pdf');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
