import 'dart:io';

import 'package:pdf_engine/pdf_engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUpAll(PdfiumEngine.initializeForDart);
  tearDown(() async => expect(await engine.openCounts(), (0, 0), reason: 'documents or pages left open'));

  test('inspect counts pages and detects text-only documents', () async {
    final text = ok(await engine.inspect(fixture('text_50p.pdf')));
    expect(text.pageCount, 50);
    expect(text.looksTextOnly, isTrue);
    final scan = ok(await engine.inspect(fixture('scan_phone_5p.pdf')));
    expect((scan.pageCount, scan.imagesOnScannedPages), (5, 5));
  });

  test('merge keeps every page, in order, and the text', () async {
    final out = '${tempDir().path}/merged.pdf';
    final dest = ok(await engine.createEmpty());
    final a = ok(await engine.open(fixture('text_50p.pdf')));
    final b = ok(await engine.open(fixture('scan_phone_5p.pdf')));
    try {
      expect(ok(await engine.importPages(dest, a, at: 0)), 50);
      expect(ok(await engine.importPages(dest, b, at: 50)), 55);
      ok(await engine.save(dest, out));
    } finally {
      for (final d in [dest, a, b]) {
        await engine.close(d);
      }
    }
    expect(await pageCountOf(out), 55);
    expect(await textOf(out), contains('Documento de prueba · página 50'));
  });

  test('extract a selection of pages', () async {
    final out = '${tempDir().path}/extract.pdf';
    final dest = ok(await engine.createEmpty());
    final src = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      ok(await engine.importPages(dest, src, pages: [2, 3, 4], at: 0));
      ok(await engine.save(dest, out));
    } finally {
      await engine.close(dest);
      await engine.close(src);
    }
    final text = await textOf(out);
    expect(await pageCountOf(out), 3);
    expect(text, contains('página 3'));
    expect(text, isNot(contains('página 6')));
  });

  test('rotate and delete pages', () async {
    final out = '${tempDir().path}/edited.pdf';
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      ok(await engine.rotatePage(doc, 0, 1));
      ok(await engine.deletePage(doc, 49));
      ok(await engine.save(doc, out));
    } finally {
      await engine.close(doc);
    }
    final reopened = ok(await engine.open(out));
    try {
      expect(reopened.pageCount, 49);
      final page = ok(await engine.render(reopened, 0, widthPx: 200));
      expect(page.width > 0 && page.height < page.width, isTrue, reason: 'rotated A4 renders landscape');
    } finally {
      await engine.close(reopened);
    }
  });

  test('photos to PDF: a JPEG becomes a page fitted inside the layout', () async {
    final out = '${tempDir().path}/photos.pdf';
    final doc = ok(await engine.createEmpty());
    try {
      ok(await engine.addJpegPage(doc, tinyJpeg(), PageLayout.letter));
      ok(await engine.addJpegPage(doc, tinyJpeg(), PageLayout.oficio));
      ok(await engine.save(doc, out));
    } finally {
      await engine.close(doc);
    }
    expect(await pageCountOf(out), 2);
  });

  test('render returns white-backed BGRA of the requested width', () async {
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      final page = ok(await engine.render(doc, 0, widthPx: 300));
      final bytes = page.pixels.materialize().asUint8List();
      expect(page.width, 300);
      expect(bytes.length, page.width * page.height * 4);
      expect(bytes.sublist(0, 4), [255, 255, 255, 255], reason: 'top-left corner is paper');
    } finally {
      await engine.close(doc);
    }
  });

  test('render by dpi follows the page size and stops at the width cap', () async {
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      final a4 = ok(await engine.render(doc, 0, dpi: 150));
      expect(a4.width, closeTo(595.28 * 150 / 72, 1), reason: 'A4 at 150 dpi');
      expect(a4.height / a4.width, closeTo(841.89 / 595.28, 0.01));
      final capped = ok(await engine.render(doc, 0, dpi: 600, maxWidthPx: 4000));
      expect(capped.width, 4000);
    } finally {
      await engine.close(doc);
    }
  });

  test('render can hand RGBA to the platform codecs', () async {
    final doc = ok(await engine.open(fixture('scan_color_10p.pdf')));
    try {
      final bgra = ok(await engine.render(doc, 0, widthPx: 200)).pixels.materialize().asUint8List();
      final rgba = ok(await engine.render(doc, 0, widthPx: 200, rgba: true)).pixels.materialize().asUint8List();
      var differing = 0;
      for (var i = 0; i < bgra.length; i += 4) {
        expect([rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]], [bgra[i + 2], bgra[i + 1], bgra[i], bgra[i + 3]]);
        if (bgra[i] != bgra[i + 2]) differing++;
      }
      expect(differing, greaterThan(0), reason: 'the page must have colour for this check to mean anything');
    } finally {
      await engine.close(doc);
    }
  });

  test('saving where it cannot write is writeFailed and leaves no file', () async {
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      final failure = err(await engine.save(doc, '/nonexistent-dir/out.pdf'));
      expect(failure.code, EngineErrorCode.writeFailed);
    } finally {
      await engine.close(doc);
    }
    expect(File('/nonexistent-dir/out.pdf').existsSync(), isFalse);
  });
}
