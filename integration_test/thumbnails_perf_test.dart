// H5 acceptance: scrolling 300 thumbnails keeps 90% of frames under 16 ms.
// Only meaningful in profile mode (see test_driver/integration_test.dart).
import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  final env = DeviceEnv();

  setUpAll(env.setUp);
  tearDownAll(env.tearDown);

  testWidgets('desplazar 300 miniaturas', (tester) async {
    final source = await textPdf(env.sources.path, 'largo', 300);
    await env.pumpApp(tester);
    GoRouter.of(tester.element(find.text('FileFlow'))).push(
      Routes.organize,
      extra: ToolArgs(
        local: [LocalFile(path: source, name: 'largo.pdf', sizeBytes: 1)],
      ),
    );
    await waitFor(tester, find.text('largo.pdf · 300 págs.'));
    final grid = find.byType(GridView);

    await binding.watchPerformance(() async {
      // Down to the end and back up, at a brisk reading pace, while
      // thumbnails keep arriving from the engine.
      for (final dy in <double>[-1200, -1200, -1200, -1200, -1200, -1200, 1800, 1800, 1800, 1800]) {
        await tester.fling(grid, Offset(0, dy), 2500);
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'thumbnails_scroll');
  });
}
