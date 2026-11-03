import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Route paths. Tool routes are added from the tool registry in H4.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';
}

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
  ],
);
