import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

/// Platform goldens (real fonts) only run locally; CI compares the
/// font-independent "CI goldens" so Linux and macOS agree.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final isCi = Platform.environment['CI'] == 'true';
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi)),
    run: () async => testMain(),
  );
}
