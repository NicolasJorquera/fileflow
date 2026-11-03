import 'package:go_router/go_router.dart';

import '../features/dev_tools/presentation/diagnostics_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/processing_screen.dart';
import '../features/shared/result_screen.dart';
import '../features/tools/merge/presentation/merge_controller.dart';
import '../features/tools/merge/presentation/merge_screen.dart';

/// Route paths. Tool, processing and result screens sit above Inicio, so
/// leaving a result always lands there.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';
  static const merge = '/merge';

  /// Takes [ProcessingArgs] as `extra`.
  static const processing = '/processing';
  static String result(String id) => '/result/$id';

  /// Dev flavor only (reached from Settings).
  static const diagnostics = '/dev/diagnostics';
}

GoRouter buildRouter({String initialLocation = Routes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'merge',
          builder: (context, state) => MergeScreen(args: state.extra as MergeArgs? ?? const MergeArgs()),
        ),
        GoRoute(
          path: 'processing',
          builder: (context, state) => ProcessingScreen(args: state.extra! as ProcessingArgs),
        ),
        GoRoute(
          path: 'result/:id',
          builder: (context, state) => ResultScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
    GoRoute(path: Routes.diagnostics, builder: (context, state) => const DiagnosticsScreen()),
  ],
);
