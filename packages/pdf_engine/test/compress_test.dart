import 'dart:io';

import 'package:pdf_engine/pdf_engine.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Recompresses every image above [targetDpi] the way the Reduce tool will,
/// with a Dart JPEG encoder standing in for the platform codec.
Future<int> recompress(String src, String out, {required int targetDpi}) async {
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
        ok(await engine.replaceImageWithJpeg(doc, page, slot.objectIndex, encodeJpegForTest(rgba)));
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
}
