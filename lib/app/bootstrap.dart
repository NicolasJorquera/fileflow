import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_engine/pdf_engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:platform_files/platform_files.dart';

import '../core/domain/ads.dart';
import '../data/ads/admob.dart';
import '../data/files/disk_job_workspace.dart';
import '../data/files/platform_file_gateway.dart';
import '../data/pdf/engine_pdf_service.dart';
import '../data/pdf/engine_thumbnails.dart';
import '../data/recents/json_recents_repository.dart';
import '../data/scanner/ml_kit_scanner_gateway.dart';
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
  final api = MethodChannelPlatformFiles();
  final gateway = PlatformFileGateway(api, freeSpacePath: cache.path);
  final scanner = MlKitScannerGateway(api);
  // Fetch the scanner module while there is a connection (PRD H1); no wait.
  unawaited(scanner.prepare());
  // Two pages in flight need ~400 MB at peak (H3): one lane below 3 GB.
  final lanes = await _lanesFor(api);
  final recents = await JsonRecentsRepository.open(filesDir: files.path, resultsDir: await workspace.resultsDir());
  await recents.purgeExpired(DateTime.now(), settings.retention.period);
  final thumbnails = EngineThumbnailSource(const PdfiumEngine(), gateway, cacheDir: cache.path);
  await thumbnails.sweep();
  final units = AdUnits.forFlavor(flavor);
  final consent = UmpConsentGateway(debugEea: flavor == Flavor.dev && const bool.fromEnvironment('UMP_DEBUG_EEA'));
  final ads = AdMobAdsGateway(units, consent);
  runApp(
    ProviderScope(
      overrides: [
        adsGatewayProvider.overrideWithValue(ads),
        consentGatewayProvider.overrideWithValue(consent),
        // RN-08 is enforced here, not only by the screens that ask for a banner.
        adBannerProvider.overrideWithValue(
          (placement) => bannerAllowed(placement) && units.banner != null
              ? AdMobBanner(adUnitId: units.banner!)
              : const SizedBox.shrink(),
        ),
        flavorProvider.overrideWithValue(flavor),
        settingsRepositoryProvider.overrideWithValue(settings),
        jobWorkspaceProvider.overrideWithValue(workspace),
        fileGatewayProvider.overrideWithValue(gateway),
        imageCodecProvider.overrideWithValue(gateway),
        interruptedJobsProvider.overrideWithValue(interrupted),
        pdfServiceProvider.overrideWithValue(EnginePdfService(const PdfiumEngine(), gateway, lanes: lanes)),
        scannerGatewayProvider.overrideWithValue(scanner),
        regionProvider.overrideWithValue(PlatformDispatcher.instance.locale.countryCode),
        recentsRepositoryProvider.overrideWithValue(recents),
        thumbnailSourceProvider.overrideWithValue(thumbnails),
      ],
      child: const FileFlowApp(),
    ),
  );
}

Future<int> _lanesFor(PlatformFilesApi api) async {
  try {
    return await api.deviceMemory() >= 3 * 1024 * 1024 * 1024 ? 2 : 1;
  } on PlatformFilesException {
    return 1;
  }
}
