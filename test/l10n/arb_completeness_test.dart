import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every published language must have every key of the template (es). Region
/// variants such as es_ES only override what differs, so they are exempt.
void main() {
  test('los idiomas publicados tienen todas las claves', () {
    Map<String, dynamic> read(String name) =>
        jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

    final template = keys(read('app_es.arb'));
    final languages = Directory('lib/l10n')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => RegExp(r'^app_[a-z]{2}\.arb$').hasMatch(n) && n != 'app_es.arb');
    expect(languages, isNotEmpty);
    for (final file in languages) {
      expect(template.difference(keys(read(file))), isEmpty, reason: '$file is missing keys');
    }
  });
}
