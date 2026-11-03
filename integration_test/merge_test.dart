// H4 acceptance on a device: «unir 3 → guardar» with the real engine, storage
// and UI; only the system pickers are replaced (they cannot be driven from a
// test). Run with the device in airplane mode:
//
//   fvm flutter test integration_test/merge_test.dart --flavor dev
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:fileflow/app/app.dart';
import 'package:fileflow/app/providers.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/core/domain/settings.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/data/files/disk_job_workspace.dart';
import 'package:fileflow/data/files/platform_file_gateway.dart';
import 'package:fileflow/data/pdf/engine_pdf_service.dart';
import 'package:fileflow/data/recents/json_recents_repository.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_engine/pdf_engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:platform_files/platform_files.dart';

/// The real gateway, except that "picking" returns [nextPick] (file paths)
/// and importing is a plain copy, as the plugin does for content URIs.
class _PathGateway implements FileGateway {
  _PathGateway(this._real);

  final PlatformFileGateway _real;
  List<String> nextPick = const [];
  final saved = <String>[];
  late String saveDir;

  @override
  Future<Result<List<PickedFile>>> pickPdfs({bool multiple = false}) async =>
      Ok([for (final p in nextPick) PickedFile(ref: p, name: p.split('/').last, sizeBytes: File(p).lengthSync())]);

  @override
  Future<Result<LocalFile>> importToJob(PickedFile file, JobDir job, {CancelToken? token}) async {
    final dest = await File(file.ref).copy('${job.inputDir}/${file.name}');
    return Ok(LocalFile(path: dest.path, name: file.name, sizeBytes: await dest.length()));
  }

  /// Stands in for the system «Guardar en…» picker.
  @override
  Future<Result<String?>> saveAs(LocalFile file, {required String suggestedName}) async {
    final dest = await File(file.path).copy('$saveDir/$suggestedName');
    saved.add(dest.path);
    return Ok(dest.path);
  }

  @override
  Future<Result<List<PickedFile>>> pickImages({int max = 100}) => _real.pickImages(max: max);
  @override
  Future<Result<int?>> saveAllToFolder(List<LocalFile> files, {required List<String> names}) =>
      _real.saveAllToFolder(files, names: names);
  @override
  Future<Result<void>> share(List<LocalFile> files) => _real.share(files);
  @override
  Future<Result<void>> openWith(LocalFile file) => _real.openWith(file);
  @override
  Stream<List<PickedFile>> incomingShares() => _real.incomingShares();
}

/// A text PDF whose page i says "<label> página i".
Future<String> _textPdf(String dir, String label, int pages) async {
  final doc = pw.Document();
  for (var i = 1; i <= pages; i++) {
    doc.addPage(pw.Page(build: (_) => pw.Text('$label pagina $i')));
  }
  final file = File('$dir/$label.pdf');
  await file.writeAsBytes(await doc.save());
  return file.path;
}

/// A scan-like PDF of [pages] noisy photos, built with the engine and the
/// platform JPEG codec (as «Fotos a PDF» will).
Future<String> _scanPdf(String dir, String name, int pages, ImageCodec codec, PdfEngine engine) async {
  const w = 1000, h = 1414;
  final rgba = Uint8List(w * h * 4);
  final random = Random(7);
  for (var i = 0; i < rgba.length; i += 4) {
    final v = 120 + random.nextInt(120);
    rgba
      ..[i] = v
      ..[i + 1] = v - random.nextInt(40)
      ..[i + 2] = v - random.nextInt(80)
      ..[i + 3] = 255;
  }
  final jpeg = (await codec.encodeJpeg(
    rgba: rgba,
    width: w,
    height: h,
    targetWidth: w,
    targetHeight: h,
    quality: 60,
  )).valueOrNull!;
  final doc = (await engine.createEmpty() as EngineOk<DocHandle>).value;
  for (var i = 0; i < pages; i++) {
    await engine.addJpegPage(doc, TransferableTypedData.fromList([jpeg]), PageLayout.a4);
  }
  final path = '$dir/$name';
  await engine.save(doc, path);
  await engine.close(doc);
  return path;
}

Future<List<String>> _pageTexts(String path) async {
  final doc = await PdfDocument.openFile(path);
  try {
    return [for (final page in doc.pages) (await page.loadText())!.fullText.trim()];
  } finally {
    await doc.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();

  late Directory sources, saveDir;
  late DiskJobWorkspace workspace;
  late JsonRecentsRepository recents;
  late _PathGateway gateway;
  late PlatformFileGateway real;
  const engine = PdfiumEngine();

  setUpAll(() async {
    final cache = await getTemporaryDirectory();
    final files = await getApplicationSupportDirectory();
    sources = Directory('${cache.path}/it_sources')..createSync(recursive: true);
    saveDir = Directory('${cache.path}/it_saved')..createSync(recursive: true);
    workspace = DiskJobWorkspace(cacheDir: cache.path, filesDir: files.path);
    await workspace.sweepLeftovers();
    recents = await JsonRecentsRepository.open(filesDir: files.path, resultsDir: await workspace.resultsDir());
    await recents.clear();
    real = PlatformFileGateway(MethodChannelPlatformFiles(), freeSpacePath: cache.path);
    gateway = _PathGateway(real)..saveDir = saveDir.path;
  });

  tearDownAll(() async {
    await recents.clear();
    sources.deleteSync(recursive: true);
    saveDir.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // The texts below are Spanish whatever the device language is.
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(_Settings()),
          jobWorkspaceProvider.overrideWithValue(workspace),
          fileGatewayProvider.overrideWithValue(gateway),
          imageCodecProvider.overrideWithValue(real),
          pdfServiceProvider.overrideWithValue(const EnginePdfService(engine)),
          recentsRepositoryProvider.overrideWithValue(recents),
        ],
        child: const FileFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// pumpAndSettle with a deadline: the engine works on another isolate, so
  /// frames alone do not finish the job.
  Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) fail('timed out waiting for $finder');
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('unir 3 → guardar, sin conexión: orden, texto, originales intactos', (tester) async {
    final inputs = [
      await _textPdf(sources.path, 'A', 2),
      await _textPdf(sources.path, 'B', 3),
      await _textPdf(sources.path, 'C', 1),
    ];
    final damaged = File('${sources.path}/dañado.pdf')..writeAsStringSync('%PDF-1.7 truncated');
    final originals = [for (final p in inputs) File(p).readAsBytesSync()];

    await pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    gateway.nextPick = [inputs[0], damaged.path, inputs[1], inputs[2]];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('3 archivos · 6 páginas'));
    expect(find.text('No pudimos abrir este archivo. Puede estar dañado o no ser un PDF.'), findsOneWidget);

    await tester.tap(find.text('Unir 3 archivos'));
    await waitFor(tester, find.byType(ResultScreen));

    final item = recents.current.single;
    expect(item.pages, 6);
    expect(await _pageTexts(item.path), [
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
    expect(File(gateway.saved.single).readAsBytesSync(), File(item.path).readAsBytesSync());

    // Back on Inicio the job folder is gone and the result is listed.
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text(item.name), findsOneWidget);
    expect(Directory('${(await getTemporaryDirectory()).path}/jobs').listSync(), isEmpty);
  });

  testWidgets('cancelar no deja archivos', (tester) async {
    final big = await _scanPdf(sources.path, 'escaneo.pdf', 60, real, engine);
    await recents.clear();
    await pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    gateway.nextPick = [big, big, big, big];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('4 archivos · 240 páginas'));

    await tester.tap(find.text('Unir 4 archivos'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Cancelar'));
    await waitFor(tester, find.text('Unir 4 archivos'));
    // Let the engine reach its next cancellation check and clean up.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));

    expect(recents.current, isEmpty);
    expect(Directory(await workspace.resultsDir()).listSync(), isEmpty);
  });

  testWidgets('rendimiento: 360 páginas escaneadas', (tester) async {
    final part = await _scanPdf(sources.path, 'parte.pdf', 120, real, engine);
    final mb = File(part).lengthSync() * 3 / (1024 * 1024);

    await recents.clear();
    await pumpApp(tester);
    await tester.tap(find.text('Unir en uno solo'));
    await tester.pumpAndSettle();
    gateway.nextPick = [part, part, part];
    await tester.tap(find.text('Agregar PDF'));
    await waitFor(tester, find.text('3 archivos · 360 páginas'));

    final clock = Stopwatch()..start();
    await tester.tap(find.text('Unir 3 archivos'));
    await waitFor(tester, find.byType(ResultScreen));
    clock.stop();

    // ignore: avoid_print
    print('H4 perf: 360 pages, ${mb.toStringAsFixed(1)} MB, tap to Resultado in ${clock.elapsedMilliseconds} ms');
    expect(recents.current.single.pages, 360);
  });
}

class _Settings implements SettingsRepository {
  @override
  ThemePreference theme = ThemePreference.light;

  @override
  Future<void> setTheme(ThemePreference value) async => theme = value;
}
