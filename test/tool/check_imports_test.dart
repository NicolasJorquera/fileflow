import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_imports.dart';

void main() {
  test('domain importing Flutter is a violation', () {
    final v = checkImports({'lib/core/domain/x.dart': "import 'package:flutter/widgets.dart';"});
    expect(v.single.rule, contains('pure Dart'));
  });

  test('domain may import core/jobs and dart:typed_data', () {
    final v = checkImports({'lib/core/domain/x.dart': "import '../jobs/jobs.dart';\nimport 'dart:typed_data';"});
    expect(v, isEmpty);
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

  test('Play Billing only in lib/data/billing; it does not open the network rule', () {
    const billing = "import 'package:in_app_purchase/in_app_purchase.dart';";
    const android = "import 'package:in_app_purchase_android/in_app_purchase_android.dart';";
    expect(checkImports({'lib/data/billing/b.dart': '$billing\n$android'}), isEmpty);
    expect(checkImports({'lib/data/ads/a.dart': billing}).single.rule, contains('lib/data/billing'));
    expect(checkImports({'lib/app/bootstrap.dart': android}).single.rule, contains('lib/data/billing'));
    const ads = "import 'package:google_mobile_ads/google_mobile_ads.dart';";
    expect(checkImports({'lib/data/billing/b.dart': ads}).single.rule, contains('lib/data/ads'));
  });
}
