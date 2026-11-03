import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Platform goldens (real fonts) only run locally; CI compares the
/// font-independent "CI goldens" so Linux and macOS agree.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final isCi = Platform.environment['CI'] == 'true';
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(comparator.basedir.resolve('golden_test.dart'));
  }
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi)),
    run: () async => testMain(),
  );
}

/// Accepts differences up to 0.5% of pixels. Icon anti-aliasing differs a few
/// dozen pixels between macOS and Linux (first CI run: 66 px, 0.00%); a real
/// visual change is far above this.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const _maxDiffPercent = 0.5;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent * 100 <= _maxDiffPercent) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
