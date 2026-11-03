import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/settings.dart';

/// Overridden at startup with the real implementation (see bootstrap.dart) and
/// in tests with fakes. Presentation never instantiates adapters itself.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepositoryProvider must be overridden'),
);

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
