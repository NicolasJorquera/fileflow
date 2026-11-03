import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/domain/settings.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fakes.dart';

void main() {
  late MemoryRecents recents;
  late MemorySettings settings;

  setUp(() {
    settings = MemorySettings();
    recents = MemoryRecents([
      sampleRecent(id: 'a', name: 'Documento unido.pdf', createdAt: testNow.subtract(const Duration(hours: 1))),
      sampleRecent(
        id: 'b',
        name: 'contrato (separado)',
        kind: ResultKind.split,
        files: ['contrato (págs. 1-5).pdf', 'contrato (págs. 6-9).pdf'],
        createdAt: testNow.subtract(const Duration(days: 3)),
      ),
      sampleRecent(id: 'c', name: 'viejo.pdf', createdAt: testNow.subtract(const Duration(days: 7))),
    ]);
  });

  testWidgets('grupos, etiqueta de herramienta, días restantes; lo vencido no aparece', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );

    expect(find.text('Los resultados se borran solos a los 7 días. Puedes cambiarlo en Ajustes.'), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('ESTA SEMANA'), findsOneWidget);
    expect(find.text('Unido'), findsOneWidget);
    expect(find.text('Separado'), findsOneWidget);
    expect(find.text('7,6 MB · se borra en 7 días'), findsOneWidget);
    expect(find.text('7,6 MB · se borra en 4 días'), findsOneWidget);
    expect(find.text('viejo.pdf'), findsNothing, reason: 'created exactly 7 days ago: expired');
    expect(recents.current.map((i) => i.id), ['a', 'b'], reason: 'opening Recientes purges');
  });

  testWidgets('tocar un resultado abre Resultado', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );
    await tester.tap(find.text('contrato (separado)'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Separado en 2 archivos'), findsOneWidget);
  });

  testWidgets('eliminar desde el menú se puede deshacer', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );
    await tester.tap(find.byTooltip('Más opciones para Documento unido.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Documento unido.pdf'), findsNothing);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Documento unido.pdf'), findsOneWidget);
    expect(recents.current.length, 2);
  });

  testWidgets('«Borrar todo» confirma con cantidad y MB, y deja el estado vacío', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );
    await tester.tap(find.text('Borrar todo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Se borrarán 2 resultados (15,2 MB). Lo que guardaste en otras carpetas no cambia.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(recents.current, isEmpty);
    expect(find.text('Aquí verás lo que crees'), findsOneWidget);
    expect(find.text('Elegir un PDF'), findsOneWidget);
  });

  testWidgets('acortar el plazo en Ajustes avisa y borra lo vencido', (tester) async {
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.settings,
    );
    await tester.scrollUntilVisible(find.text('Después de 1 día'), 100);
    await tester.tap(find.text('Después de 1 día'));
    await tester.pumpAndSettle();
    expect(find.text('Con este plazo se borran ahora 2 resultados (15,2 MB).'), findsOneWidget);
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(settings.retention, RecentsRetention.oneDay);
    expect(recents.current.map((i) => i.id), ['a']);
  });

  testWidgets('«Nunca» deja los resultados y lo dice', (tester) async {
    settings.retention = RecentsRetention.untilDeleted;
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );
    expect(find.text('viejo.pdf'), findsOneWidget);
    expect(find.text('Los resultados quedan aquí hasta que los borres. Puedes cambiarlo en Ajustes.'), findsOneWidget);
  });

  testWidgets('Recientes cumple las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      fakeOverrides(recents: recents, settings: settings),
      at: Routes.recents,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
