// Attributes the engine's memory over a 300-page compression (follow-up of
// spike S7: +451 MB peak on a 2 GB device). Each mode adds one stage:
//
//   scan     imagesOnPage + finishPage
//   extract  + extractImage (pixels materialized and dropped)
//   replace  + replaceImageWithJpeg with a tiny JPEG (no codec cost)
//
//   dart run tool/make_fixtures.dart --only-large
//   dart run tool/memory_probe.dart scan|extract|replace
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf_engine/pdf_engine.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'replace' : args.first;
  await PdfiumEngine.initializeForDart();
  const engine = PdfiumEngine();
  final jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 8), quality: 50));
  int mb(int bytes) => bytes >> 20;

  final base = ProcessInfo.currentRss;
  final doc = (await engine.open('test/fixtures/large_300p.pdf')).valueOrThrow;
  final samples = <String>[];
  for (var page = 0; page < doc.pageCount; page++) {
    var changed = false;
    for (final slot in (await engine.imagesOnPage(doc, page)).valueOrThrow) {
      if (mode == 'scan') continue;
      final scale = 110 / slot.effectiveDpi;
      final rgba = (await engine.extractImage(doc, page, slot.objectIndex, scale < 1 ? scale : 1)).valueOrThrow;
      rgba.pixels.materialize();
      if (mode == 'replace') {
        await engine.replaceImageWithJpeg(doc, page, slot.objectIndex, TransferableTypedData.fromList([jpeg]));
        changed = true;
      }
    }
    await engine.finishPage(doc, page, changed: changed);
    if ((page + 1) % 50 == 0) samples.add('p${page + 1}=${mb(ProcessInfo.currentRss - base)}');
  }
  if (mode == 'replace') await engine.save(doc, '${Directory.systemTemp.path}/memory_probe.pdf');
  await engine.close(doc);
  stdout.writeln(
    '$mode: base=${mb(base)} MB  growth by page (MB): ${samples.join(' ')}  '
    'after close=${mb(ProcessInfo.currentRss - base)}  peak=${mb(ProcessInfo.maxRss - base)}',
  );
}
