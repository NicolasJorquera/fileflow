import 'package:go_router/go_router.dart';

import '../features/dev_tools/presentation/diagnostics_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Route paths. Tool routes are added from the tool registry in H4.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';

  /// Dev flavor only (reached from Settings).
  static const diagnostics = '/dev/diagnostics';
}

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
    GoRoute(path: Routes.diagnostics, builder: (context, state) => const DiagnosticsScreen()),
  ],
);
