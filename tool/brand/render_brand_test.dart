// Renders the app icon, launcher icons and Play feature graphics.
// Run: flutter test tool/brand/render_brand_test.dart
// Not part of the test suite: it writes files into android/, ios/ and docs/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = Color(0xFF2349C9);
const _deep = Color(0xFF16318F);
const _soft = Color(0xFFC9D4F6);
const _accent = Color(0xFF1C7447);

/// The glyph on a 1024 grid: a page with a folded corner and a badge with a
/// down arrow (smaller, lighter files). [scale] shrinks it around the centre.
void _glyph(Canvas c, double scale) {
  c.save();
  c.translate(512, 512);
  c.scale(scale);
  c.translate(-512, -512);
  const l = 300.0, t = 220.0, r = 680.0, b = 780.0, fold = 120.0;
  final page = Path()
    ..moveTo(l + 40, t)
    ..lineTo(r - fold, t)
    ..lineTo(r, t + fold)
    ..lineTo(r, b - 40)
    ..arcToPoint(const Offset(r - 40, b), radius: const Radius.circular(40))
    ..lineTo(l + 40, b)
    ..arcToPoint(const Offset(l, b - 40), radius: const Radius.circular(40))
    ..lineTo(l, t + 40)
    ..arcToPoint(const Offset(l + 40, t), radius: const Radius.circular(40))
    ..close();
  c.drawPath(page.shift(const Offset(0, 14)), Paint()..color = _deep.withValues(alpha: 0.35));
  c.drawPath(page, Paint()..color = const Color(0xFFFFFFFF));
  final corner = Path()
    ..moveTo(r - fold, t)
    ..lineTo(r - fold, t + fold - 24)
    ..arcToPoint(const Offset(r - fold + 24, t + fold), radius: const Radius.circular(24), clockwise: false)
    ..lineTo(r, t + fold)
    ..close();
  c.drawPath(corner, Paint()..color = _soft);
  final line = Paint()
    ..color = _soft
    ..strokeWidth = 34
    ..strokeCap = StrokeCap.round;
  for (final (y, end) in [(400.0, 600.0), (480.0, 600.0), (560.0, 500.0)]) {
    c.drawLine(Offset(l + 70, y), Offset(end, y), line);
  }
  const centre = Offset(668, 700);
  c.drawCircle(centre, 150, Paint()..color = _blue);
  c.drawCircle(centre, 122, Paint()..color = _accent);
  final arrow = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 30
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  c.drawLine(centre + const Offset(0, -62), centre + const Offset(0, 58), arrow);
  c.drawPath(
    Path()
      ..moveTo(centre.dx - 52, centre.dy + 8)
      ..lineTo(centre.dx, centre.dy + 60)
      ..lineTo(centre.dx + 52, centre.dy + 8),
    arrow,
  );
  c.restore();
}

enum _Shape { square, rounded, none }

Future<void> _icon(String path, int px, {required _Shape bg, double scale = 1}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)..scale(px / 1024);
  const full = Rect.fromLTWH(0, 0, 1024, 1024);
  final fill = Paint()
    ..shader = ui.Gradient.linear(Offset.zero, const Offset(1024, 1024), [const Color(0xFF2F5BE0), _blue]);
  switch (bg) {
    case _Shape.square:
      c.drawRect(full, fill);
    case _Shape.rounded:
      c.drawRRect(RRect.fromRectAndRadius(full.deflate(40), const Radius.circular(220)), fill);
    case _Shape.none:
      break;
  }
  _glyph(c, scale);
  await _write(rec, path, px, px);
}

Future<void> _write(ui.PictureRecorder rec, String path, int w, int h) async {
  final image = await rec.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

ui.Paragraph _text(String s, double size, Color color, double width, {FontWeight weight = FontWeight.w700}) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Brand', fontSize: size, fontWeight: weight))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Brand', fontSize: size, height: 1.15))
    ..addText(s);
  return b.build()..layout(ui.ParagraphConstraints(width: width));
}

Future<void> _feature(String path, String tagline) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1024, 500),
    Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(1024, 500), [const Color(0xFF2F5BE0), _deep]),
  );
  c.save();
  c.translate(60, 40);
  c.scale(420 / 1024);
  _glyph(c, 1);
  c.restore();
  c.drawParagraph(_text('FileFlow', 96, const Color(0xFFFFFFFF), 520), const Offset(470, 130));
  c.drawParagraph(_text(tagline, 40, const Color(0xFFE5EBFB), 500), const Offset(474, 260));
  await _write(rec, path, 1024, 500);
}

void main() {
  test('render brand assets', () async {
    final font = File('/System/Library/Fonts/Supplemental/Arial Bold.ttf').readAsBytesSync();
    await ui.loadFontFromList(Uint8List.fromList(font), fontFamily: 'Brand');
    const res = 'android/app/src/main/res';
    const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final MapEntry(key: d, value: f) in densities.entries) {
      await _icon('$res/mipmap-$d/ic_launcher.png', (48 * f).round(), bg: _Shape.rounded, scale: 0.92);
      await _icon('$res/mipmap-$d/ic_launcher_foreground.png', (108 * f).round(), bg: _Shape.none, scale: 0.62);
    }
    await _icon('docs/store/graphics/icon-512.png', 512, bg: _Shape.square, scale: 0.86);
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final (name, px) in [
      ('1024x1024@1x', 1024),
      ('20x20@1x', 20),
      ('20x20@2x', 40),
      ('20x20@3x', 60),
      ('29x29@1x', 29),
      ('29x29@2x', 58),
      ('29x29@3x', 87),
      ('40x40@1x', 40),
      ('40x40@2x', 80),
      ('40x40@3x', 120),
      ('60x60@2x', 120),
      ('60x60@3x', 180),
      ('76x76@1x', 76),
      ('76x76@2x', 152),
      ('83.5x83.5@2x', 167),
    ]) {
      await _icon('$ios/Icon-App-$name.png', px, bg: _Shape.square, scale: 0.86);
    }
    await _feature('docs/store/graphics/feature-es.png', 'Tus PDF, en tu teléfono. Sin subir nada.');
    await _feature('docs/store/graphics/feature-en.png', 'Your PDFs, on your phone. Nothing uploaded.');
    await _feature('docs/store/graphics/feature-pt.png', 'Seus PDFs, no seu celular. Nada é enviado.');
    expect(math.max(1, 0), 1);
  });
}
