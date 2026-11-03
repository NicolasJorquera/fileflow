// Nightly robustness run (plan H3): mutates the fixtures and pushes each
// variant through every engine path. Any crash, hang or exception escaping the
// engine fails the run. Mutations: random byte flips, truncation, duplicated
// chunks and zeroed ranges.
//
//   dart run tool/fuzz.dart [count=200] [seed=1]
//
// A native crash kills this process; the last "file" line printed names the
// input, which is kept under test/fixtures/fuzz/ for reproduction.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pdf_engine/pdf_engine.dart';

const _sources = ['text_50p.pdf', 'scan_phone_5p.pdf', 'mixed_12p.pdf', 'alpha_logo_1p.pdf'];

Future<void> main(List<String> args) async {
  final count = args.isNotEmpty ? int.parse(args[0]) : 200;
  final rnd = Random(args.length > 1 ? int.parse(args[1]) : 1);
  await PdfiumEngine.initializeForDart();
  const engine = PdfiumEngine();
  final dir = Directory('test/fixtures/fuzz')..createSync(recursive: true);
  final out = '${Directory.systemTemp.path}/fuzz_out.pdf';
  final outcomes = <String, int>{};

  for (var i = 0; i < count; i++) {
    final source = File('test/fixtures/${_sources[i % _sources.length]}').readAsBytesSync();
    final path = '${dir.path}/fuzz_$i.pdf';
    File(path).writeAsBytesSync(_mutate(source, rnd));
    stdout.writeln('file $path');
    final outcome = await _exercise(engine, path, out).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        stderr.writeln('HANG on $path');
        exit(2);
      },
    );
    outcomes.update(outcome, (n) => n + 1, ifAbsent: () => 1);
    File(path).deleteSync();
  }
  stdout.writeln('fuzz: $count files, outcomes $outcomes, 0 crashes, 0 hangs');
  exit(0);
}

/// Runs open/inspect/scan/extract/render/save; returns "ok" or the first error code.
Future<String> _exercise(PdfEngine engine, String path, String out) async {
  try {
    await engine.inspect(path);
    final opened = await engine.open(path);
    if (opened is! EngineOk<DocHandle>) return (opened as EngineErr).failure.code.name;
    final doc = opened.value;
    try {
      for (var p = 0; p < doc.pageCount && p < 3; p++) {
        final slots = await engine.imagesOnPage(doc, p);
        if (slots case EngineOk(:final value) when value.isNotEmpty) {
          await engine.extractImage(doc, p, value.first.objectIndex, 0.5);
        }
        await engine.finishPage(doc, p, changed: false);
        await engine.render(doc, p, widthPx: 120);
      }
      final saved = await engine.save(doc, out);
      return saved is EngineOk ? 'ok' : (saved as EngineErr).failure.code.name;
    } finally {
      await engine.close(doc);
    }
  } catch (e) {
    stderr.writeln('EXCEPTION escaped the engine on $path: ${e.runtimeType}');
    exit(3);
  }
}

Uint8List _mutate(Uint8List source, Random rnd) {
  final b = Uint8List.fromList(source);
  switch (rnd.nextInt(4)) {
    case 0:
      for (var i = 0, n = 1 + rnd.nextInt(200); i < n; i++) {
        b[rnd.nextInt(b.length)] = rnd.nextInt(256);
      }
      return b;
    case 1:
      return Uint8List.sublistView(b, 0, rnd.nextInt(b.length));
    case 2:
      final start = rnd.nextInt(b.length), len = rnd.nextInt(min(4096, b.length - start) + 1);
      return Uint8List.fromList([...b.sublist(0, start + len), ...b.sublist(start)]);
    default:
      final start = rnd.nextInt(b.length);
      b.fillRange(start, min(b.length, start + rnd.nextInt(2048)), 0);
      return b;
  }
}
