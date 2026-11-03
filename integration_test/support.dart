// Shared pieces of the on-device tests: real engine, storage and UI with the
// system pickers replaced (they cannot be driven from a test).
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
import 'package:fileflow/data/pdf/engine_thumbnails.dart';
import 'package:fileflow/data/recents/json_recents_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_engine/pdf_engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:platform_files/platform_files.dart';

/// The real gateway, except that "picking" returns [nextPick] (file paths)
/// and importing is a plain copy, as the plugin does for content URIs.
class PathGateway implements FileGateway {
  PathGateway(this._real);

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
Future<String> textPdf(String dir, String label, int pages) async {
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
Future<String> scanPdf(String dir, String name, int pages, ImageCodec codec, PdfEngine engine) async {
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

Future<List<String>> pageTexts(String path) async {
  final doc = await PdfDocument.openFile(path);
  try {
    return [for (final page in doc.pages) (await page.loadText())!.fullText.trim()];
  } finally {
    await doc.dispose();
  }
}

/// Real adapters over the app's own folders, cleaned before and after.
class DeviceEnv {
  late Directory sources, saveDir;
  late DiskJobWorkspace workspace;
  late JsonRecentsRepository recents;
  late PathGateway gateway;
  late PlatformFileGateway real;
  late EngineThumbnailSource thumbnails;
  late String cacheDir;
  final settings = TestSettings();
  static const engine = PdfiumEngine();

  Future<void> setUp() async {
    final cache = await getTemporaryDirectory();
    final files = await getApplicationSupportDirectory();
    cacheDir = cache.path;
    sources = Directory('${cache.path}/it_sources')..createSync(recursive: true);
    saveDir = Directory('${cache.path}/it_saved')..createSync(recursive: true);
    workspace = DiskJobWorkspace(cacheDir: cache.path, filesDir: files.path);
    await workspace.sweepLeftovers();
    recents = await JsonRecentsRepository.open(filesDir: files.path, resultsDir: await workspace.resultsDir());
    await recents.clear();
    real = PlatformFileGateway(MethodChannelPlatformFiles(), freeSpacePath: cache.path);
    gateway = PathGateway(real)..saveDir = saveDir.path;
    thumbnails = EngineThumbnailSource(engine, real, cacheDir: cache.path);
    await thumbnails.sweep();
  }

  Future<void> tearDown() async {
    await recents.clear();
    await thumbnails.sweep();
    sources.deleteSync(recursive: true);
    saveDir.deleteSync(recursive: true);
  }

  /// The whole app in Spanish, whatever the device language is.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          jobWorkspaceProvider.overrideWithValue(workspace),
          fileGatewayProvider.overrideWithValue(gateway),
          imageCodecProvider.overrideWithValue(real),
          pdfServiceProvider.overrideWithValue(EnginePdfService(engine, real)),
          recentsRepositoryProvider.overrideWithValue(recents),
          thumbnailSourceProvider.overrideWithValue(thumbnails),
        ],
        child: const FileFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
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

class TestSettings implements SettingsRepository {
  @override
  ThemePreference theme = ThemePreference.light;

  @override
  Future<void> setTheme(ThemePreference value) async => theme = value;

  @override
  RecentsRetention retention = RecentsRetention.sevenDays;

  @override
  Future<void> setRetention(RecentsRetention value) async => retention = value;
}
