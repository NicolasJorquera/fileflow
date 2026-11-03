import 'package:pdf_engine/pdf_engine.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Phase-1 S5 cases: every damaged or protected file yields a typed failure,
/// never a crash or a hang, and the worker keeps serving afterwards.
void main() {
  setUpAll(PdfiumEngine.initializeForDart);
  tearDown(() async => expect(await engine.openCounts(), (0, 0)));

  const expected = {
    'bad_empty.pdf': EngineErrorCode.damaged,
    'bad_header_only.pdf': EngineErrorCode.damaged,
    'bad_not_a_pdf.pdf': EngineErrorCode.damaged,
    'bad_truncated_60.pdf': EngineErrorCode.damaged,
    'bad_truncated_scan_50.pdf': EngineErrorCode.damaged,
    'locked_password.pdf': EngineErrorCode.passwordRequired,
  };

  for (final MapEntry(key: name, value: code) in expected.entries) {
    test('$name → ${code.name}', () async {
      expect(err(await engine.open(fixture(name))).code, code);
      expect(err(await engine.inspect(fixture(name))).code, code);
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  test('a PDF without xref is repaired by PDFium and opens', () async {
    final doc = ok(await engine.open(fixture('bad_no_xref.pdf')));
    expect(doc.pageCount, 50);
    await engine.close(doc);
  });

  test('random byte corruption never throws out of the engine', () async {
    final result = await engine.open(fixture('bad_random_bytes.pdf'));
    if (result case EngineOk(:final value)) {
      for (var i = 0; i < value.pageCount; i++) {
        await engine.render(value, i, widthPx: 120); // ok or a typed failure
      }
      await engine.close(value);
    }
  });

  test('missing file is io', () async {
    expect(err(await engine.open('test/fixtures/does-not-exist.pdf')).code, EngineErrorCode.io);
  });

  test('an unexpected error inside the worker becomes data and the worker survives', () async {
    expect(err(await engine.debugThrowInWorker()).code, EngineErrorCode.internal);
    expect(ok(await engine.inspect(fixture('text_50p.pdf'))).pageCount, 50);
  });

  test('a closed handle is invalidHandle, not a crash', () async {
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    await engine.close(doc);
    await engine.close(doc); // closing twice is safe
    expect(err(await engine.render(doc, 0, widthPx: 100)).code, EngineErrorCode.invalidHandle);
  });

  test('a page index out of range is pageUnreadable', () async {
    final doc = ok(await engine.open(fixture('text_50p.pdf')));
    try {
      expect(err(await engine.render(doc, 999, widthPx: 100)).code, EngineErrorCode.pageUnreadable);
    } finally {
      await engine.close(doc);
    }
  });
}
