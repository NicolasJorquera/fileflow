import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings/prefs_settings_repository.dart';
import 'app.dart';
import 'flavor.dart';
import 'providers.dart';

final flavorProvider = Provider<Flavor>((ref) => Flavor.prod);

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await PrefsSettingsRepository.create();
  runApp(
    ProviderScope(
      overrides: [flavorProvider.overrideWithValue(flavor), settingsRepositoryProvider.overrideWithValue(settings)],
      child: const ListoApp(),
    ),
  );
}
