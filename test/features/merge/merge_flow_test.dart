import 'dart:async';

import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/home/presentation/home_screen.dart';
import 'package:fileflow/features/shared/processing_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _mb = 1024 * 1024;

PickedFile _picked(String name, {int mb = 1}) => PickedFile(ref: 'content://$name', name: name, sizeBytes: mb * _mb);

/// The real app shell (router, theme, Spanish) over fake ports.
Future<void> _pumpApp(WidgetTester tester, List<Override> overrides, {String at = Routes.home}) async {
  final router = buildRouter(initialLocation: at);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: buildTheme(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeFileGateway files;
  late FakePdfService pdf;
  late MemoryRecents recents;
  late FakeWorkspace workspace;

  setUp(() {
    files = FakeFileGateway();
    pdf = FakePdfService(
      pages: {'carnet.pdf': 2, 'certificado.pdf': 1, 'liquidaciones.pdf': 11},
      failures: {'firmado.pdf': const PdfPasswordRequired()},
    );
    recents = MemoryRecents();
    workspace = FakeWorkspace();
  });

  List<Override> overrides() => fakeOverrides(files: files, pdf: pdf, recents: recents, workspace: workspace);

  testWidgets('Inicio → Unir 3 (uno con contraseña) → Resultado en Recientes', (tester) async {
    await _pumpApp(tester, overrides());
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos 2 PDF para unirlos en uno solo.'), findsOneWidget);

    files.nextPick = [_picked('carnet.pdf', mb: 3), _picked('firmado.pdf'), _picked('liquidaciones.pdf', mb: 4)];
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('1. carnet.pdf'), findsOneWidget);
    expect(find.text('Este PDF tiene contraseña. Esta versión todavía no puede abrirlo.'), findsOneWidget);
    expect(find.text('2 archivos · 13 páginas'), findsOneWidget);
    expect(find.text('Se omite 1 archivo con problemas.'), findsOneWidget);

    await tester.tap(find.text('Unir 2 archivos'));
    await tester.pumpAndSettle();

    expect(pdf.merges.single, ['/in/carnet.pdf', '/in/liquidaciones.pdf']);
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Unido en un solo PDF'), findsOneWidget);
    expect(find.text('13 páginas · 1,0 MB'), findsOneWidget);
    expect(recents.current.single.name, startsWith('Documento unido '));

    // Leaving the result lands on Inicio, which lists it; the job folder is gone.
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text(recents.current.single.name), 200);
    expect(find.text(recents.current.single.name), findsOneWidget);
    expect(workspace.deleted, [workspace.created.single.id]);
  });

  testWidgets('con un solo PDF el botón pide otro', (tester) async {
    await _pumpApp(tester, overrides(), at: Routes.merge);
    files.nextPick = [_picked('carnet.pdf')];
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Agrega al menos 2 PDF'));
    expect(button.onPressed, isNull);
  });

  testWidgets('quitar sin confirmar y deshacer lo devuelve a su lugar', (tester) async {
    await _pumpApp(tester, overrides(), at: Routes.merge);
    files.nextPick = [_picked('carnet.pdf'), _picked('certificado.pdf'), _picked('liquidaciones.pdf')];
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quitar certificado.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('2. liquidaciones.pdf'), findsOneWidget);
    expect(find.text('Se quitó certificado.pdf'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('2. certificado.pdf'), findsOneWidget);
  });

  testWidgets('«Mover abajo» cambia el orden sin arrastrar', (tester) async {
    await _pumpApp(tester, overrides(), at: Routes.merge);
    files.nextPick = [_picked('carnet.pdf'), _picked('certificado.pdf')];
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mover carnet.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover abajo'));
    await tester.pumpAndSettle();

    expect(find.text('1. certificado.pdf'), findsOneWidget);
    expect(find.text('2. carnet.pdf'), findsOneWidget);
  });

  testWidgets('más de 20 archivos: entran 20 y se avisa', (tester) async {
    await _pumpApp(tester, overrides(), at: Routes.merge);
    files.nextPick = [for (var i = 0; i < 22; i++) _picked('f$i.pdf')];
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Puedes unir hasta 20 archivos a la vez.'), findsOneWidget);
    expect(find.text('20 archivos · 20 páginas'), findsOneWidget);
  });

  testWidgets('Resultado: compartir, guardar, abrir sin app y renombrar', (tester) async {
    recents = MemoryRecents([sampleRecent()]);
    files.openFailure = const NoAppAvailable();
    await _pumpApp(tester, overrides(), at: Routes.result('r1'));

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    expect(files.shared.single.single.name, 'Documento unido 2026-11-03.pdf');

    await tester.tap(find.text('Guardar en…'));
    await tester.pumpAndSettle();
    expect(files.savedAs, ['Documento unido 2026-11-03.pdf']);
    expect(find.text('Guardado'), findsOneWidget);

    await tester.tap(find.text('Abrir con otra app'));
    await tester.pumpAndSettle();
    expect(find.text('No hay una app para abrir este archivo.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Postulación beca');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(recents.current.single.name, 'Postulación beca.pdf');
  });

  group('Procesando', () {
    late StreamController<JobEvent> events;
    late Job job;

    Future<void> pumpProcessing(WidgetTester tester) async {
      events = StreamController<JobEvent>();
      job = JobRunner().enqueue((_) => events.stream);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProcessingScreen(
              args: ProcessingArgs(job: job, title: 'Uniendo…'),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra porcentaje y paso', (tester) async {
      await pumpProcessing(tester);
      events.add(const JobProgress(2, 4));
      await tester.pump();
      expect(find.text('50 %'), findsOneWidget);
      expect(find.text('Paso 2 de 4'), findsOneWidget);
      await events.close();
    });

    testWidgets('un error muestra la causa y «Reintentar»', (tester) async {
      await pumpProcessing(tester);
      events.add(const JobFailed(InsufficientStorage(300 * _mb)));
      await tester.pump();
      expect(find.text('No hay espacio suficiente. Necesitas unos 300 MB libres.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      await events.close();
    });

    testWidgets('cancelar antes de 10 s no pregunta y cancela el trabajo', (tester) async {
      late CancelToken token;
      events = StreamController<JobEvent>();
      job = JobRunner().enqueue((t) {
        token = t;
        return events.stream;
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(
            locale: const Locale('es'),
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProcessingScreen(
                      args: ProcessingArgs(job: job, title: 'Uniendo…'),
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      // The bar is indeterminate until the first progress: pump, don't settle.
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('¿Cancelar?'), findsNothing);
      expect(find.byType(ProcessingScreen), findsNothing);
      expect(token.isCancelled, isTrue);
      await events.close();
    });
  });

  testWidgets('el aviso de operación interrumpida se cierra y no vuelve', (tester) async {
    await _pumpApp(tester, fakeOverrides(interrupted: 1));
    expect(find.text('La operación anterior se interrumpió. Tus archivos originales no cambiaron.'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('se interrumpió'), findsNothing);
  });

  testWidgets('Unir y Resultado cumplen las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    files.nextPick = [_picked('carnet.pdf'), _picked('firmado.pdf'), _picked('certificado.pdf')];
    await _pumpApp(tester, overrides(), at: Routes.merge);
    await tester.tap(find.text('Agregar PDF'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Unir 2 archivos'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
