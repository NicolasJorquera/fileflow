import 'dart:io';
import 'dart:math' as math;

import 'package:pdf_engine/pdf_engine.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Recompresses every image above [targetDpi] the way the Reduce tool will,
/// with a Dart JPEG encoder standing in for the platform codec.
Future<int> recompress(String src, String out, {required int targetDpi, int quality = 75}) async {
  final doc = ok(await engine.open(src));
  var replaced = 0;
  try {
    for (var page = 0; page < doc.pageCount; page++) {
      var changed = false;
      for (final slot in ok(await engine.imagesOnPage(doc, page))) {
        final needsResample = slot.effectiveDpi > targetDpi * 1.1;
        if (slot.hasTransparency || (!needsResample && slot.isJpeg)) continue;
        final scale = needsResample ? targetDpi / slot.effectiveDpi : 1.0;
        final rgba = ok(await engine.extractImage(doc, page, slot.objectIndex, scale));
        ok(await engine.replaceImageWithJpeg(doc, page, slot.objectIndex, encodeJpegForTest(rgba, quality: quality)));
        changed = true;
        replaced++;
      }
      await engine.finishPage(doc, page, changed: changed);
    }
    ok(await engine.save(doc, out));
  } finally {
    await engine.close(doc);
  }
  return replaced;
}

void main() {
  setUpAll(PdfiumEngine.initializeForDart);
  tearDown(() async => expect(await engine.openCounts(), (0, 0)));

  test('a 200 dpi phone scan reduced to 150 dpi is smaller and keeps every page', () async {
    final src = fixture('scan_phone_5p.pdf');
    final out = '${tempDir().path}/reduced.pdf';
    expect(await recompress(src, out, targetDpi: 150), 5);
    expect(File(out).lengthSync(), lessThan(File(src).lengthSync() * 0.7));
    expect(await pageCountOf(out), 5);
  });

  test('text is preserved in a mixed document', () async {
    final src = fixture('mixed_12p.pdf');
    final out = '${tempDir().path}/mixed.pdf';
    await recompress(src, out, targetDpi: 110);
    expect(await textOf(out), await textOf(src));
  });

  test('images with transparency are reported and skipped', () async {
    final doc = ok(await engine.open(fixture('alpha_logo_1p.pdf')));
    try {
      final slots = ok(await engine.imagesOnPage(doc, 0));
      expect(slots.single.hasTransparency, isTrue);
      await engine.finishPage(doc, 0, changed: false);
    } finally {
      await engine.close(doc);
    }
  });

  test('box reduction: scale 0.5 halves dimensions exactly, targets round', () async {
    final doc = ok(await engine.open(fixture('scan_phone_5p.pdf')));
    try {
      final slot = ok(await engine.imagesOnPage(doc, 0)).single;
      final rgba = ok(await engine.extractImage(doc, 0, slot.objectIndex, 0.5));
      expect(rgba.width, slot.pixelWidth ~/ 2);
      expect(rgba.targetWidth, (slot.pixelWidth * 0.5).round().clamp(1, rgba.width));
      expect(rgba.pixels.materialize().lengthInBytes, rgba.width * rgba.height * 4);
      await engine.finishPage(doc, 0, changed: false);
    } finally {
      await engine.close(doc);
    }
  });

  // The Reduce levels of the PRD (dpi, JPEG quality).
  const levels = {'high': (200, 85), 'balanced': (150, 75), 'minimal': (110, 60)};

  /// Peak signal-to-noise ratio of [a] against [b] (same size, BGRA), on RGB.
  double psnr(List<int> a, List<int> b) {
    var sum = 0.0, n = 0;
    for (var i = 0; i < a.length; i += 4) {
      for (var c = 0; c < 3; c++) {
        final d = a[i + c] - b[i + c];
        sum += d * d;
        n++;
      }
    }
    final mse = sum / n;
    return mse == 0 ? 99 : 10 * math.log(255 * 255 / mse) / math.ln10;
  }

  /// Lowest PSNR over the pages, rendered at 100 dpi (A4 → 827 px).
  Future<double> worstPsnr(String original, String reduced) async {
    final a = ok(await engine.open(original)), b = ok(await engine.open(reduced));
    var worst = 99.0;
    try {
      for (var page = 0; page < a.pageCount; page++) {
        final ra = ok(await engine.render(a, page, dpi: 100)).pixels.materialize().asUint8List();
        final rb = ok(await engine.render(b, page, dpi: 100)).pixels.materialize().asUint8List();
        worst = math.min(worst, psnr(ra, rb));
      }
    } finally {
      await engine.close(a);
      await engine.close(b);
    }
    return worst;
  }

  // Floors 2 dB under the worst page measured on 2026-11-03 (high 32.4,
  // balanced 30.4, minimal 23.6 dB; the synthetic colour scan is mostly
  // noise, hence the low minimal): a regression in resampling or encoding
  // shows here. Recheck with real documents (plan H8).
  for (final (level, floor) in [('high', 30.0), ('balanced', 28.0), ('minimal', 21.0)]) {
    test('PSNR at «$level» stays above $floor dB on scans and mixed pages', () async {
      final (dpi, quality) = levels[level]!;
      for (final name in ['scan_color_10p.pdf', 'mixed_12p.pdf']) {
        final out = '${tempDir().path}/$level-$name';
        await recompress(fixture(name), out, targetDpi: dpi, quality: quality);
        final value = await worstPsnr(fixture(name), out);
        printOnFailure('$level $name: ${value.toStringAsFixed(1)} dB');
        expect(value, greaterThan(floor), reason: '$name at $level');
      }
    });
  }

  // Phase 1 (docs/fase1-resultados.md, S2): reduction per fixture and level.
  // The plan accepts ±5 points; the platform codec is checked on a device.
  const phase1 = {
    'scan_color_10p.pdf': {'high': 70, 'balanced': 89, 'minimal': 95},
    'scan_gray_10p.pdf': {'high': 72, 'balanced': 90, 'minimal': 95},
    'mixed_12p.pdf': {'high': 66, 'balanced': 86, 'minimal': 92},
  };
  for (final MapEntry(key: name, value: expected) in phase1.entries) {
    test('$name reduces as in phase 1 (±5 points)', () async {
      final before = File(fixture(name)).lengthSync();
      for (final MapEntry(key: level, value: percent) in expected.entries) {
        final (dpi, quality) = levels[level]!;
        final out = '${tempDir().path}/$level-$name';
        await recompress(fixture(name), out, targetDpi: dpi, quality: quality);
        final saved = (1 - File(out).lengthSync() / before) * 100;
        printOnFailure('$name $level: −${saved.toStringAsFixed(1)} %');
        expect(saved, closeTo(percent, 5), reason: '$name at $level');
      }
    });
  }
}
