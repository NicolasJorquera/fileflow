// H4 acceptance on a device: «unir 3 → guardar» with the real engine, storage
// and UI; only the system pickers are replaced (they cannot be driven from a
// test). Run with the device in airplane mode:
//
//   fvm flutter test integration_test/merge_test.dart --flavor dev
import 'dart:io';

import 'package:fileflow/features/shared/result_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();

  final env = DeviceEnv();

  setUpAll(env.setUp);
  tearDownAll(env.tearDown);

  testWidgets('unir 3 → guardar, sin conexión: orden, texto, originales intactos', (tester) async {
    final inputs = [
      await textPdf(env.sources.path, 'A', 2),
      await textPdf(env.sources.path, 'B', 3),
      await textPdf(env.sources.path, 'C', 1),
    ];
    final damaged = File('${env.sources.path}/dañado.pdf')..writeAsStringSync('%PDF-1.7 truncated');
    final originals = [for (final p in inputs) File(p).readAsBytesSync()];

    await env.pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    env.gateway.nextPick = [inputs[0], damaged.path, inputs[1], inputs[2]];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('3 archivos · 6 páginas'));
    expect(find.text('No pudimos abrir este archivo. Puede estar dañado o no ser un PDF.'), findsOneWidget);

    await tester.tap(find.text('Unir 3 archivos'));
    await waitFor(tester, find.byType(ResultScreen));

    final item = env.recents.current.single;
    expect(item.pages, 6);
    expect(await pageTexts(item.path), [
      'A pagina 1',
      'A pagina 2',
      'B pagina 1',
      'B pagina 2',
      'B pagina 3',
      'C pagina 1',
    ]);
    for (final (i, p) in inputs.indexed) {
      expect(File(p).readAsBytesSync(), originals[i], reason: 'original ${i + 1} changed');
    }

    await tester.tap(find.text('Guardar en…'));
    await tester.pumpAndSettle();
    expect(find.text('Guardado'), findsOneWidget);
    expect(File(env.gateway.saved.single).readAsBytesSync(), File(item.path).readAsBytesSync());

    // Back on Inicio the job folder is gone and the result is listed.
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text(item.name), findsOneWidget);
    expect(Directory('${(await getTemporaryDirectory()).path}/jobs').listSync(), isEmpty);
  });

  testWidgets('cancelar no deja archivos', (tester) async {
    final big = await scanPdf(env.sources.path, 'escaneo.pdf', 60, env.real, DeviceEnv.engine);
    await env.recents.clear();
    await env.pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    env.gateway.nextPick = [big, big, big, big];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('4 archivos · 240 páginas'));

    await tester.tap(find.text('Unir 4 archivos'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Cancelar'));
    await waitFor(tester, find.text('Unir 4 archivos'));
    // Let the engine reach its next cancellation check and clean up.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));

    expect(env.recents.current, isEmpty);
    expect(Directory(await env.workspace.resultsDir()).listSync(), isEmpty);
  });

  testWidgets('rendimiento: 360 páginas escaneadas', (tester) async {
    final part = await scanPdf(env.sources.path, 'parte.pdf', 120, env.real, DeviceEnv.engine);
    final mb = File(part).lengthSync() * 3 / (1024 * 1024);

    await env.recents.clear();
    await env.pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    env.gateway.nextPick = [part, part, part];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('3 archivos · 360 páginas'));

    final clock = Stopwatch()..start();
    await tester.tap(find.text('Unir 3 archivos'));
    await waitFor(tester, find.byType(ResultScreen));
    clock.stop();

    // ignore: avoid_print
    print('H4 perf: 360 pages, ${mb.toStringAsFixed(1)} MB, tap to Resultado in ${clock.elapsedMilliseconds} ms');
    expect(env.recents.current.single.pages, 360);
  });
}
