import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf_engine/pdf_engine.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart' as pdfrx;
import 'package:test/test.dart';

const engine = PdfiumEngine();

String fixture(String name) {
  final path = 'test/fixtures/$name';
  if (!File(path).existsSync()) fail('Missing $path: run `dart run tool/make_fixtures.dart` first');
  return path;
}

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('pdf_engine_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

T ok<T>(EngineResult<T> result) => switch (result) {
  EngineOk<T>(:final value) => value,
  EngineErr<T>(:final failure) => fail('Expected success, got $failure'),
};

EngineFailure err<T>(EngineResult<T> result) => switch (result) {
  EngineErr<T>(:final failure) => failure,
  EngineOk<T>() => fail('Expected a failure, got success'),
};

/// Text of all pages via pdfrx's high-level API (independent of our engine).
Future<String> textOf(String path) async {
  final doc = await pdfrx.PdfDocument.openFile(path);
  try {
    final b = StringBuffer();
    for (final p in doc.pages) {
      b.write((await p.loadText())?.fullText ?? '');
    }
    return b.toString();
  } finally {
    await doc.dispose();
  }
}

Future<int> pageCountOf(String path) async {
  final doc = await pdfrx.PdfDocument.openFile(path);
  try {
    return doc.pages.length;
  } finally {
    await doc.dispose();
  }
}

/// JPEG encoder for tests. The app uses the platform codec instead.
TransferableTypedData encodeJpegForTest(RgbaImage image, {int quality = 75}) {
  final rgba = image.pixels.materialize().asUint8List();
  final decoded = img.Image.fromBytes(width: image.width, height: image.height, bytes: rgba.buffer, numChannels: 4);
  final scaled = (image.targetWidth != image.width || image.targetHeight != image.height)
      ? img.copyResize(
          decoded,
          width: image.targetWidth,
          height: image.targetHeight,
          interpolation: img.Interpolation.average,
        )
      : decoded;
  return TransferableTypedData.fromList([img.encodeJpg(scaled, quality: quality)]);
}

TransferableTypedData tinyJpeg() => TransferableTypedData.fromList([
  Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 8)..clear(img.ColorRgb8(240, 240, 240)), quality: 50)),
]);
