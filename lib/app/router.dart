import 'package:go_router/go_router.dart';

import '../features/dev_tools/presentation/diagnostics_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/processing_screen.dart';
import '../features/shared/result_screen.dart';
import '../features/recents/presentation/recents_screen.dart';
import '../features/tools/merge/presentation/merge_screen.dart';
import '../features/tools/organize/presentation/organize_screen.dart';
import '../features/tools/photos/presentation/photos_screen.dart';
import '../features/tools/reduce/presentation/reduce_screen.dart';
import '../features/tools/shared/presentation/tool_args.dart';
import '../features/tools/to_image/presentation/to_image_screen.dart';

/// Route paths. Tool, processing and result screens sit above Inicio, so
/// leaving a result always lands there.
abstract final class Routes {
  static const home = '/';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const recents = '/recents';
  static const merge = '/merge';
  static const reduce = '/reduce';
  static const photos = '/photos';
  static const organize = '/organize';
  static const toImage = '/to-image';

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
        GoRoute(path: 'recents', builder: (context, state) => const RecentsScreen()),
        GoRoute(
          path: 'merge',
          builder: (context, state) => MergeScreen(args: _args(state)),
        ),
        GoRoute(
          path: 'reduce',
          builder: (context, state) => ReduceScreen(args: _args(state)),
        ),
        GoRoute(
          path: 'photos',
          builder: (context, state) => PhotosScreen(args: _args(state)),
        ),
        GoRoute(
          path: 'organize',
          builder: (context, state) => OrganizeScreen(args: _args(state)),
        ),
        GoRoute(
          path: 'to-image',
          builder: (context, state) => ToImageScreen(args: _args(state)),
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
    GoRoute(path: Routes.privacy, builder: (context, state) => const PrivacyScreen()),
    GoRoute(path: Routes.diagnostics, builder: (context, state) => const DiagnosticsScreen()),
  ],
);

ToolArgs _args(GoRouterState state) => state.extra as ToolArgs? ?? const ToolArgs();
