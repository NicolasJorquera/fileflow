import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_imports.dart';

void main() {
  test('domain importing Flutter is a violation', () {
    final v = checkImports({'lib/core/domain/x.dart': "import 'package:flutter/widgets.dart';"});
    expect(v.single.rule, contains('pure Dart'));
  });

  test('domain may import its own files and dart:async', () {
    final v = checkImports({'lib/core/domain/result.dart': "import 'failures.dart';\nimport 'dart:async';"});
    expect(v, isEmpty);
  });

  test('domain importing dart:io is a violation', () {
    expect(checkImports({'lib/core/domain/x.dart': "import 'dart:io';"}), hasLength(1));
  });

  test('presentation importing data is a violation', () {
    final v = checkImports({
      'lib/features/home/presentation/home.dart': "import '../../../data/settings/prefs_settings_repository.dart';",
    });
    expect(v.single.rule, contains('lib/data'));
  });

  test('network SDK outside lib/data/ads is a violation, inside is allowed', () {
    const ads = "import 'package:google_mobile_ads/google_mobile_ads.dart';";
    expect(checkImports({'lib/data/files/f.dart': ads}), hasLength(1));
    expect(checkImports({'lib/data/ads/a.dart': ads}), isEmpty);
  });

  test('dart:io with HttpClient outside ads is a violation; plain file IO is fine', () {
    expect(checkImports({'lib/data/files/f.dart': "import 'dart:io';\nfinal c = HttpClient();"}), hasLength(1));
    expect(checkImports({'lib/data/files/f.dart': "import 'dart:io';\nfinal f = File('x');"}), isEmpty);
  });
}
