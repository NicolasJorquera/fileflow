// Generates the synthetic PDFs the engine tests use (ported from phase 1).
//
//   dart run tool/make_fixtures.dart              small set (~1 min), used by CI
//   dart run tool/make_fixtures.dart --only-large 300-page file for memory tests
//
// Output goes to test/fixtures/ (git-ignored). Everything is synthetic; results
// must be re-checked with real, anonymized documents (plan H8).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _out = Directory('test/fixtures');

Future<void> main(List<String> args) async {
  _out.createSync(recursive: true);
  if (args.contains('--only-large')) {
    await _scanPdf('large_300p.pdf', pages: 300, dpi: 150, color: true, quality: 85);
    stdout.writeln('large_300p.pdf: ${_mb(File('${_out.path}/large_300p.pdf').lengthSync())}');
    return;
  }

  await _scanPdf('scan_color_10p.pdf', pages: 10, dpi: 300, color: true);
  await _scanPdf('scan_gray_10p.pdf', pages: 10, dpi: 300, color: false);
  await _scanPdf('scan_phone_5p.pdf', pages: 5, dpi: 200, color: true, quality: 80);
  await _textPdf('text_50p.pdf', pages: 50);
  await _mixedPdf('mixed_12p.pdf', pages: 12);
  await _alphaPdf('alpha_logo_1p.pdf');
  _signaturePng('signature.png');
  _damaged();
  stdout.writeln('Fixtures in ${_out.absolute.path}:');
  for (final f in _out.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path))) {
    stdout.writeln('  ${f.uri.pathSegments.last.padRight(28)} ${_mb(f.lengthSync())}');
  }
}

String _mb(int bytes) => '${(bytes / 1048576).toStringAsFixed(2)} MB';

/// A4 page rendered like a phone/flatbed scan: off-white paper with sensor
/// noise, dark "text" strokes, a colored stamp and a photo block.
img.Image _scanImage(int seed, {required int dpi, required bool color}) {
  final w = (8.27 * dpi).round();
  final h = (11.69 * dpi).round();
  final rnd = Random(seed);
  final im = img.Image(width: w, height: h);
  for (final p in im) {
    final n = (rnd.nextDouble() + rnd.nextDouble() + rnd.nextDouble() - 1.5) * 10;
    p
      ..r = (240 + n).clamp(0, 255)
      ..g = (237 + n).clamp(0, 255)
      ..b = (229 + n).clamp(0, 255);
  }
  // Text-like strokes.
  final line = (dpi * 0.17).round();
  for (var y = (dpi * 1.2).round(); y < h - dpi; y += line * 2) {
    var x = dpi;
    while (x < w - dpi) {
      final word = (dpi * (0.15 + rnd.nextDouble() * 0.5)).round();
      img.fillRect(
        im,
        x1: x,
        y1: y,
        x2: min(x + word, w - dpi),
        y2: y + (line * 0.6).round(),
        color: img.ColorRgb8(35, 35, 45),
      );
      x += word + (dpi * 0.08).round();
    }
    if (rnd.nextDouble() < 0.12) y += line * 2;
  }
  // Blue stamp and a photo block.
  img.fillCircle(im, x: w - dpi * 2, y: h - dpi * 2, radius: (dpi * 0.6).round(), color: img.ColorRgb8(40, 70, 170));
  final px = dpi, py = (h * 0.62).round(), pw0 = (w * 0.35).round(), ph = (h * 0.12).round();
  for (var y = py; y < py + ph; y++) {
    for (var x = px; x < px + pw0; x++) {
      final n = rnd.nextInt(18);
      im.setPixelRgb(x, y, 90 + (x - px) * 120 ~/ pw0 + n, 140 + n, 200 - (y - py) * 120 ~/ ph + n);
    }
  }
  return color ? im : img.grayscale(im);
}

Future<void> _scanPdf(
  String name, {
  required int pages,
  required int dpi,
  required bool color,
  int quality = 90,
}) async {
  final doc = pw.Document(compress: true);
  for (var i = 0; i < pages; i++) {
    final im = _scanImage(name.hashCode + i, dpi: dpi, color: color);
    final jpg = img.encodeJpg(im, quality: quality, chroma: color ? img.JpegChroma.yuv420 : img.JpegChroma.yuv444);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(jpg), fit: pw.BoxFit.fill),
      ),
    );
    if (pages > 20 && i % 25 == 0) stdout.writeln('  $name: page $i/$pages');
  }
  File('${_out.path}/$name').writeAsBytesSync(await doc.save());
}

const _paragraphs = [
  'Por medio del presente certifico que la persona individualizada ha cumplido con todos los requisitos '
      'exigidos para la postulación, incluyendo la presentación de antecedentes académicos y laborales.',
  'Se adjuntan copia de la cédula de identidad por ambos lados, certificado de residencia emitido por la '
      'junta de vecinos y comprobante de ingresos de los últimos tres meses.',
  'El plazo para la entrega de documentos vence el día hábil siguiente a la publicación de los resultados. '
      'Los archivos deben enviarse en formato PDF y no superar el tamaño máximo indicado en el portal.',
  'Declaro bajo juramento que la información proporcionada es verídica y que acepto las condiciones '
      'establecidas en las bases del concurso, así como las verificaciones que la institución estime necesarias.',
];

Future<void> _textPdf(String name, {required int pages}) async {
  final doc = pw.Document(compress: true);
  for (var i = 0; i < pages; i++) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Documento de prueba · página ${i + 1}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            for (var k = 0; k < 9; k++) ...[
              pw.Text(_paragraphs[(i + k) % _paragraphs.length], style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
  File('${_out.path}/$name').writeAsBytesSync(await doc.save());
}

Future<void> _mixedPdf(String name, {required int pages}) async {
  final doc = pw.Document(compress: true);
  for (var i = 0; i < pages; i++) {
    final photo = img.copyResize(_scanImage(900 + i, dpi: 150, color: true), width: 1200);
    final jpg = img.encodeJpg(photo, quality: 88);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          children: [
            pw.Text(_paragraphs[i % _paragraphs.length], style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.Image(pw.MemoryImage(jpg), height: 380),
            pw.SizedBox(height: 10),
            pw.Text(_paragraphs[(i + 1) % _paragraphs.length], style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
  File('${_out.path}/$name').writeAsBytesSync(await doc.save());
}

/// Page with a PNG logo that has real transparency (exported with an SMask),
/// to check that recompression does not destroy alpha.
Future<void> _alphaPdf(String name) async {
  final logo = img.Image(width: 800, height: 800, numChannels: 4);
  img.fillCircle(logo, x: 400, y: 400, radius: 380, color: img.ColorRgba8(200, 30, 40, 255));
  img.fillCircle(logo, x: 400, y: 400, radius: 200, color: img.ColorRgba8(0, 0, 0, 0));
  final doc = pw.Document(compress: true);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Stack(
        children: [
          pw.Text(List.filled(40, _paragraphs[0]).join(' '), style: const pw.TextStyle(fontSize: 10)),
          pw.Center(child: pw.Image(pw.MemoryImage(img.encodePng(logo)), width: 300)),
        ],
      ),
    ),
  );
  File('${_out.path}/$name').writeAsBytesSync(await doc.save());
}

/// Hand-drawn-looking signature with transparent background.
void _signaturePng(String name) {
  final sig = img.Image(width: 900, height: 300, numChannels: 4);
  var prev = const Point<double>(40, 200);
  for (var t = 0.0; t < 1; t += 0.002) {
    final p = Point<double>(40 + t * 820, 150 + sin(t * 26) * 70 * (1 - t) + cos(t * 9) * 30);
    img.drawLine(
      sig,
      x1: prev.x.round(),
      y1: prev.y.round(),
      x2: p.x.round(),
      y2: p.y.round(),
      color: img.ColorRgba8(20, 30, 110, 255),
      thickness: 6,
      antialias: true,
    );
    prev = p;
  }
  File('${_out.path}/$name').writeAsBytesSync(img.encodePng(sig));
}

void _damaged() {
  final good = File('${_out.path}/text_50p.pdf').readAsBytesSync();
  final scan = File('${_out.path}/scan_phone_5p.pdf').readAsBytesSync();
  void write(String name, List<int> bytes) => File('${_out.path}/$name').writeAsBytesSync(bytes);

  write('bad_empty.pdf', []);
  write('bad_not_a_pdf.pdf', List<int>.generate(4096, (i) => (i * 31) % 256));
  write('bad_truncated_60.pdf', good.sublist(0, (good.length * 0.6).round()));
  write('bad_truncated_scan_50.pdf', scan.sublist(0, scan.length ~/ 2));
  write('bad_header_only.pdf', '%PDF-1.7\n%âãÏÓ\n'.codeUnits);
  final corrupt = Uint8List.fromList(good);
  final rnd = Random(7);
  for (var i = 0; i < 400; i++) {
    corrupt[200 + rnd.nextInt(corrupt.length - 400)] = rnd.nextInt(256);
  }
  write('bad_random_bytes.pdf', corrupt);
  // xref removed: PDFium should try to rebuild the cross-reference table.
  final s = String.fromCharCodes(good);
  final xref = s.lastIndexOf('xref');
  write('bad_no_xref.pdf', xref > 0 ? good.sublist(0, xref) + '%%EOF\n'.codeUnits : good);
  write('locked_password.pdf', _encryptedStub());
}

/// Minimal PDF with a Standard security handler (RC4, R2) whose /U entry does
/// not match the empty password, so viewers must ask for a password. Content is
/// irrelevant: the spike only checks that the app reports "password required".
List<int> _encryptedStub() {
  final rnd = Random(3);
  String hex(int n) => List.generate(n, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] >>',
    '<< /Filter /Standard /V 1 /R 2 /O <${hex(32)}> /U <${hex(32)}> /P -44 >>',
  ];
  final b = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(b.length);
    b.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
  }
  final xrefAt = b.length;
  b.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    b.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  b.write('trailer\n<< /Size ${objs.length + 1} /Root 1 0 R /Encrypt 4 0 R /ID [<${hex(16)}> <${hex(16)}>] >>\n');
  b.write('startxref\n$xrefAt\n%%EOF\n');
  return b.toString().codeUnits;
}
