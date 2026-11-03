import 'dart:io';

import 'package:pdf_engine/pdf_engine.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Plan H3: 1,000 consecutive tasks without memory growth (RSS within ±10%
/// after warm-up) and nothing left open.
void main() {
  setUpAll(PdfiumEngine.initializeForDart);

  test('1,000 tasks keep memory stable', tags: ['slow'], () async {
    final path = fixture('scan_phone_5p.pdf');
    Future<void> round() async {
      final doc = ok(await engine.open(path));
      for (var p = 0; p < doc.pageCount; p++) {
        final slots = ok(await engine.imagesOnPage(doc, p));
        ok(await engine.extractImage(doc, p, slots.first.objectIndex, 0.5)).pixels.materialize();
        await engine.finishPage(doc, p, changed: false);
      }
      await engine.close(doc);
    }

    // Each round is 1 open + 5 x (scan + extract + finish) + 1 close = 17 tasks.
    for (var i = 0; i < 10; i++) {
      await round();
    }
    final warm = ProcessInfo.currentRss;
    for (var i = 0; i < 60; i++) {
      await round();
    }
    final after = ProcessInfo.currentRss;
    final growth = (after - warm) / warm;
    printOnFailure('RSS warm=${warm >> 20} MB after=${after >> 20} MB growth=${(growth * 100).toStringAsFixed(1)}%');
    expect(growth, lessThan(0.10));
    expect(await engine.openCounts(), (0, 0));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
