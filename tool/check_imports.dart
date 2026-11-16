// Architecture rules (Arquitectura v1.0, «Capas y reglas de dependencia»).
//
//   dart run tool/check_imports.dart        exits 1 and lists violations
//
// 1. lib/core/domain and lib/core/jobs are pure Dart: no Flutter, no dart:io, no
//    packages; they may import each other.
// 2. Presentation (lib/features/**/presentation) never imports lib/data.
// 3. Only lib/data/ads may use network-capable SDKs (RN-01: no document
//    operation touches the network).
// 4. Only lib/data/billing may use Google Play Billing (in_app_purchase). It
//    opens no connection itself: it talks to the Play Store app on the phone,
//    which charges the purchase. It lives apart from lib/data/ads so that the
//    network rule above stays as strict as before, and it is kept out of
//    every other folder like a network SDK.
import 'dart:io';

class Violation {
  Violation(this.file, this.import, this.rule);

  final String file, import, rule;

  @override
  String toString() => '$file: "$import" — $rule';
}

final _importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

const _pureFolders = ['lib/core/domain/', 'lib/core/jobs/'];
const _pureDartLibraries = {'dart:async', 'dart:core', 'dart:collection', 'dart:typed_data', 'dart:math'};

const _networkPackages = ['package:http/', 'package:dio/', 'package:google_mobile_ads/', 'package:web_socket'];

/// in_app_purchase, in_app_purchase_android, in_app_purchase_platform_interface…
const _billingPackages = ['package:in_app_purchase'];

/// [files] maps a path relative to the project root (with `/`) to its source.
List<Violation> checkImports(Map<String, String> files) {
  final violations = <Violation>[];
  for (final MapEntry(key: path, value: source) in files.entries) {
    for (final match in _importRe.allMatches(source)) {
      final target = match.group(1)!;
      if (_pureFolders.any(path.startsWith) &&
          !_pureDartLibraries.contains(target) &&
          !_pureFolders.any((folder) => _isRelativeInside(path, target, folder))) {
        violations.add(Violation(path, target, 'core/domain and core/jobs must be pure Dart'));
      }
      if (path.contains('/presentation/') && _resolves(path, target).startsWith('lib/data/')) {
        violations.add(Violation(path, target, 'presentation must not import lib/data'));
      }
      final usesNetwork =
          _networkPackages.any(target.startsWith) ||
          (target == 'dart:io' && RegExp(r'\b(HttpClient|Socket|WebSocket)\b').hasMatch(source));
      if (usesNetwork && !path.startsWith('lib/data/ads/')) {
        violations.add(Violation(path, target, 'network access is only allowed in lib/data/ads'));
      }
      if (_billingPackages.any(target.startsWith) && !path.startsWith('lib/data/billing/')) {
        violations.add(Violation(path, target, 'Play Billing is only allowed in lib/data/billing'));
      }
    }
  }
  return violations;
}

bool _isRelativeInside(String from, String target, String folder) =>
    !target.contains(':') && _resolves(from, target).startsWith(folder);

/// Resolves a relative import against [from]; package/dart imports pass through,
/// except `package:fileflow/x` which maps to `lib/x`.
String _resolves(String from, String target) {
  if (target.startsWith('package:fileflow/')) return 'lib/${target.substring('package:fileflow/'.length)}';
  if (target.contains(':')) return target;
  final parts = from.split('/')..removeLast();
  for (final segment in target.split('/')) {
    if (segment == '..') {
      parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

void main() {
  final files = <String, String>{
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
      f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
  };
  final violations = checkImports(files);
  for (final v in violations) {
    stderr.writeln(v);
  }
  stdout.writeln('check_imports: ${files.length} files, ${violations.length} violations');
  exit(violations.isEmpty ? 0 : 1);
}
