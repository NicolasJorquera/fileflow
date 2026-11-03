import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_engine/pdf_engine.dart';

import '../core/domain/files.dart';
import '../core/domain/settings.dart';
import '../core/jobs/jobs.dart';
import 'flavor.dart';

// Ports are overridden at startup with real adapters (bootstrap.dart) and in
// tests with fakes. Presentation reads them here and never builds adapters.

Never _missing(String name) => throw UnimplementedError('$name must be overridden in bootstrap');

final flavorProvider = Provider<Flavor>((ref) => Flavor.prod);
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => _missing('settingsRepositoryProvider'));
final fileGatewayProvider = Provider<FileGateway>((ref) => _missing('fileGatewayProvider'));
final imageCodecProvider = Provider<ImageCodec>((ref) => _missing('imageCodecProvider'));
final jobWorkspaceProvider = Provider<JobWorkspace>((ref) => _missing('jobWorkspaceProvider'));
final pdfEngineProvider = Provider<PdfEngine>((ref) => const PdfiumEngine());
final jobRunnerProvider = Provider<JobRunner>((ref) => JobRunner());

/// Job folders found at startup: the system killed the app mid-job (RF-08).
final interruptedJobsProvider = Provider<int>((ref) => 0);

final themePreferenceProvider = NotifierProvider<ThemePreferenceController, ThemePreference>(
  ThemePreferenceController.new,
);

class ThemePreferenceController extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.read(settingsRepositoryProvider).theme;

  Future<void> select(ThemePreference value) async {
    state = value;
    await ref.read(settingsRepositoryProvider).setTheme(value);
  }
}
