import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_engine/pdf_engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:platform_files/platform_files.dart';

import '../data/files/disk_job_workspace.dart';
import '../data/files/platform_file_gateway.dart';
import '../data/pdf/engine_pdf_service.dart';
import '../data/pdf/engine_thumbnails.dart';
import '../data/recents/json_recents_repository.dart';
import '../data/settings/prefs_settings_repository.dart';
import 'app.dart';
import 'flavor.dart';
import 'providers.dart';

/// Composition root: the only place that builds adapters.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  final cache = await getTemporaryDirectory();
  final files = await getApplicationSupportDirectory();
  final settings = await PrefsSettingsRepository.create();
  final workspace = DiskJobWorkspace(cacheDir: cache.path, filesDir: files.path);
  final interrupted = await workspace.sweepLeftovers();
  final gateway = PlatformFileGateway(MethodChannelPlatformFiles(), freeSpacePath: cache.path);
  final recents = await JsonRecentsRepository.open(filesDir: files.path, resultsDir: await workspace.resultsDir());
  await recents.purgeExpired(DateTime.now(), settings.retention.period);
  final thumbnails = EngineThumbnailSource(const PdfiumEngine(), gateway, cacheDir: cache.path);
  await thumbnails.sweep();
  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        settingsRepositoryProvider.overrideWithValue(settings),
        jobWorkspaceProvider.overrideWithValue(workspace),
        fileGatewayProvider.overrideWithValue(gateway),
        imageCodecProvider.overrideWithValue(gateway),
        interruptedJobsProvider.overrideWithValue(interrupted),
        pdfServiceProvider.overrideWithValue(EnginePdfService(const PdfiumEngine(), gateway)),
        recentsRepositoryProvider.overrideWithValue(recents),
        thumbnailSourceProvider.overrideWithValue(thumbnails),
      ],
      child: const FileFlowApp(),
    ),
  );
}
