// H6 acceptance on a device with the real engine and platform codecs. Run in
// airplane mode:
//
//   fvm flutter test integration_test/h6_test.dart --flavor dev
//
// The phase 1 comparison needs the engine fixtures in the app's files folder
// (tool/push_fixtures.sh copies them with run-as); without them it is skipped.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fileflow/app/app.dart';
import 'package:fileflow/app/providers.dart';
import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/core/domain/scanner.dart';
import 'package:fileflow/data/pdf/engine_pdf_service.dart';
import 'package:fileflow/data/scanner/ml_kit_scanner_gateway.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_engine/pdf_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:platform_files/platform_files.dart';

import 'support.dart';

const _mb = 1024 * 1024;

/// Stands in for ML Kit's UI (it cannot be driven from a test): «scans» by
/// copying a prepared PDF, as the plugin copies the scanner's output.
class _PreparedScanner implements ScannerGateway {
  late String source;
  late int pages;

  @override
  Future<ScannerReadiness> readiness() async => ScannerReadiness.ready;

  @override
  Future<void> prepare() async {}

  @override
  Future<Result<int?>> scan({required int maxPages, required String destPath}) async {
    await File(source).copy(destPath);
    return Ok(pages);
  }
}

/// Lowest PSNR over the pages, rendered at 100 dpi, of [reduced] against [original].
Future<double> worstPsnr(String original, String reduced) async {
  const engine = DeviceEnv.engine;
  final a = (await engine.open(original) as EngineOk<DocHandle>).value;
  final b = (await engine.open(reduced) as EngineOk<DocHandle>).value;
  var worst = 99.0;
  try {
    for (var page = 0; page < a.pageCount; page++) {
      final ra = (await engine.render(a, page, dpi: 100) as EngineOk<RenderedPage>).value.pixels
          .materialize()
          .asUint8List();
      final rb = (await engine.render(b, page, dpi: 100) as EngineOk<RenderedPage>).value.pixels
          .materialize()
          .asUint8List();
      var sum = 0.0;
      for (var i = 0; i < ra.length; i += 4) {
        for (var c = 0; c < 3; c++) {
          final d = ra[i + c] - rb[i + c];
          sum += d * d;
        }
      }
      final mse = sum / (ra.length / 4 * 3);
      worst = math.min(worst, mse == 0 ? 99 : 10 * math.log(255 * 255 / mse) / math.ln10);
    }
  } finally {
    await engine.close(a);
    await engine.close(b);
  }
  return worst;
}

Future<int> pageCount(String path) async {
  final doc = await PdfDocument.openFile(path);
  try {
    return doc.pages.length;
  } finally {
    await doc.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  final env = DeviceEnv();
  final scanner = _PreparedScanner();

  setUpAll(env.setUp);
  tearDownAll(env.tearDown);

  EnginePdfService service() => EnginePdfService(DeviceEnv.engine, env.real);

  Finder resultList() => find.descendant(of: find.byType(ResultScreen), matching: find.byType(Scrollable)).first;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(env.settings),
          jobWorkspaceProvider.overrideWithValue(env.workspace),
          fileGatewayProvider.overrideWithValue(env.gateway),
          imageCodecProvider.overrideWithValue(env.real),
          pdfServiceProvider.overrideWithValue(service()),
          recentsRepositoryProvider.overrideWithValue(env.recents),
          thumbnailSourceProvider.overrideWithValue(env.thumbnails),
          scannerGatewayProvider.overrideWithValue(scanner),
          regionProvider.overrideWithValue('CL'),
        ],
        child: const FileFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('R1: escanear → unir con otro PDF → ajustar a 2 MB → guardar', (tester) async {
    await env.recents.clear();
    // ML Kit scans land at about 200–300 dpi: generate them at 300 dpi.
    scanner
      ..source = await scanPdf(env.sources.path, 'carnet.pdf', 2, env.real, DeviceEnv.engine, width: 2480, height: 3508)
      ..pages = 2;
    final certificate = await scanPdf(
      env.sources.path,
      'certificado.pdf',
      1,
      env.real,
      DeviceEnv.engine,
      width: 2480,
      height: 3508,
    );

    await pumpApp(tester);
    await tester.tap(find.text('Escanear'));
    await waitFor(tester, find.text('Escaneo listo'));

    await tester.scrollUntilVisible(find.text('Unir con otro PDF'), 200, scrollable: resultList());
    await tester.tap(find.text('Unir con otro PDF'));
    await waitFor(tester, find.text('Agregar PDF'));
    env.gateway.nextPick = [certificate];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('Unir 2 archivos'));
    await tester.tap(find.text('Unir 2 archivos'));
    await waitFor(tester, find.text('Unido en un solo PDF'));
    final merged = env.recents.current.first;
    expect(merged.pages, 3);

    await tester.scrollUntilVisible(find.text('Ajustar tamaño'), 200, scrollable: resultList());
    await tester.tap(find.text('Ajustar tamaño'));
    await waitFor(tester, find.text('Reducir a 2 MB'));
    await tester.tap(find.text('Reducir a 2 MB'));
    await waitFor(tester, find.byType(ResultScreen), timeout: const Duration(seconds: 120));

    final reduced = env.recents.current.first;
    expect(reduced.sizeBytes, lessThanOrEqualTo(2 * _mb));
    expect(find.text('Quedó bajo 2 MB'), findsOneWidget);
    expect(await pageCount(reduced.path), 3);

    await tester.tap(find.text('Guardar en…'));
    await tester.pumpAndSettle();
    expect(File(env.gateway.saved.last).lengthSync(), reduced.sizeBytes);
    // ignore: avoid_print
    print('H6 R1: scan 2 pages + 1 → ${merged.sizeBytes ~/ 1024} KB → ${reduced.sizeBytes ~/ 1024} KB');
  });

  testWidgets('Reducir con el códec nativo reproduce la fase 1 (±5 puntos)', (tester) async {
    final fixtures = '${(await getApplicationSupportDirectory()).path}/it_fixtures';
    if (!Directory(fixtures).existsSync()) {
      markTestSkipped('no fixtures: run tool/push_fixtures.sh first');
      return;
    }
    const phase1 = {
      'scan_color_10p.pdf': {ReduceLevel.high: 70, ReduceLevel.balanced: 89, ReduceLevel.minimal: 95},
      'scan_gray_10p.pdf': {ReduceLevel.high: 72, ReduceLevel.balanced: 90, ReduceLevel.minimal: 95},
      'mixed_12p.pdf': {ReduceLevel.high: 66, ReduceLevel.balanced: 86, ReduceLevel.minimal: 92},
    };
    final lines = <String>[];
    final worse = <String>[];
    for (final MapEntry(key: name, value: expected) in phase1.entries) {
      final src = '$fixtures/$name';
      final before = File(src).lengthSync();
      for (final MapEntry(key: level, value: percent) in expected.entries) {
        final out = '${env.sources.path}/${level.name}-$name';
        final stats = (await service().reduce(src, out, level: level)).valueOrNull!;
        final saved = (1 - stats.outputBytes / before) * 100;
        final quality = await worstPsnr(src, out);
        lines.add(
          '$name ${level.name}: −${saved.toStringAsFixed(1)} % (fase 1: −$percent %), '
          'PSNR ${quality.toStringAsFixed(1)} dB',
        );
        if (saved < percent - 5) worse.add('$name ${level.name}');
        File(out).deleteSync();
      }
    }
    // ignore: avoid_print
    print('H6 phase1:\n${lines.join('\n')}');
    // The native codec may compress more than phase 1 (Dart encoder); it must
    // never reduce less. Quality is checked by the PSNR floors of the engine.
    expect(worse, isEmpty, reason: 'reduced less than phase 1 − 5 points');

    // RN-03 with the real engine: a vector text PDF does not shrink.
    final text = '$fixtures/text_50p.pdf';
    final stats = (await service().reduce(
      text,
      '${env.sources.path}/text.pdf',
      level: ReduceLevel.minimal,
    )).valueOrNull!;
    expect(stats.imagesChanged, 0);
  });

  testWidgets('Reducir 50 páginas escaneadas (tiempo de referencia)', (tester) async {
    // A 300 dpi A4 scan, as a flatbed or a phone scanner app would produce.
    final scan = await scanPdf(
      env.sources.path,
      'escaneo50.pdf',
      50,
      env.real,
      DeviceEnv.engine,
      width: 2480,
      height: 3508,
    );
    final clock = Stopwatch()..start();
    final stats = (await service().reduce(
      scan,
      '${env.sources.path}/r50.pdf',
      level: ReduceLevel.balanced,
    )).valueOrNull!;
    clock.stop();
    expect(stats.pages, 50);
    // ignore: avoid_print
    print(
      'H6 reduce: 50 pages ${File(scan).lengthSync() ~/ 1024} KB → ${stats.outputBytes ~/ 1024} KB '
      'in ${clock.elapsedMilliseconds} ms',
    );
  });

  testWidgets('Fotos a PDF: 100 fotos JPG y PNG, una dañada, sin errores de memoria', (tester) async {
    final dir = Directory('${env.sources.path}/fotos')..createSync();
    final photos = <PhotoInput>[];
    // A 12 MP camera photo stands in for the heaviest case.
    const w = 3000, h = 4000;
    final rgba = Uint8List(w * h * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba
        ..[i] = (i ~/ 4) % w * 255 ~/ w
        ..[i + 1] = (i ~/ 4) ~/ w * 255 ~/ h
        ..[i + 2] = 128
        ..[i + 3] = 255;
    }
    for (final format in [ImageFormat.jpeg, ImageFormat.png]) {
      final path = '${dir.path}/base.${format.extension}';
      await env.real.writeImage(rgba: rgba, width: w, height: h, format: format, quality: 90, path: path);
      for (var i = 0; i < 50; i++) {
        final copy = '${dir.path}/foto_${format.extension}_$i.${format.extension}';
        File(path).copySync(copy);
        photos.add(PhotoInput(copy, i % 4));
      }
    }
    final damaged = File('${dir.path}/dañada.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0x00, 1, 2, 3]);
    photos[37] = PhotoInput(damaged.path);

    final clock = Stopwatch()..start();
    final out = '${env.sources.path}/fotos.pdf';
    final written = (await service().photosToPdf(
      photos,
      out,
      spec: const PhotoPageSpec(preset: PagePreset.letter, margin: false, dpi: 200, quality: 80),
    )).valueOrNull!;
    clock.stop();

    expect((written.pages, written.unreadable), (99, 1));
    expect(await pageCount(out), 99);
    // ignore: avoid_print
    print('H6 photos: 100 photos (12 MP) → ${File(out).lengthSync() ~/ _mb} MB in ${clock.elapsedMilliseconds} ms');
  });

  testWidgets('Escanear: sin el módulo y sin conexión es E-SCAN-01, sin abrir pantallas', (tester) async {
    final gateway = MlKitScannerGateway(MethodChannelPlatformFiles());
    final readiness = await gateway.readiness();
    // ignore: avoid_print
    print('H6 scanner readiness: $readiness');
    if (readiness == ScannerReadiness.ready) {
      markTestSkipped('the scanner module is already on this device');
      return;
    }
    expect(readiness, ScannerReadiness.offline, reason: 'airplane mode, module missing');
    final result = await gateway.scan(maxPages: 1, destPath: '${env.sources.path}/scan.pdf');
    expect(
      result,
      isA<Err<int?>>().having(
        (e) => e.failure,
        'failure',
        isA<ScannerUnavailable>().having((f) => f.reason, 'reason', ScannerIssue.moduleNotDownloaded),
      ),
    );
  });
}
