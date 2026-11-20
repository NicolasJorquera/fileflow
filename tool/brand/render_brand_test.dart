// Renders the app icon, launcher icons and Play feature graphics.
// Run: flutter test tool/brand/render_brand_test.dart
// Not part of the test suite: it writes files into android/, ios/ and docs/.
// Logo: «P7 · Gradiente», three isometric layers (Figma file «FileFlow · Logo»).
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _light = Color(0xFFF4F6FB);
const _navy = Color(0xFF13235F);
const _muted = Color(0xFF566072);

/// Layer centres and colours (top to bottom) on a 1024 grid.
const _layers = [
  (450.0, Color(0xFF3BE0C0), Color(0xFF14A88F)),
  (550.0, Color(0xFF4F8BFF), Color(0xFF2349C9)),
  (650.0, Color(0xFF3F63E8), _navy),
];
const _halfWidth = 300.0, _halfHeight = 170.0;

/// Point on the layer centred at [cy]: a runs along the top-right edge, b along the top-left one.
Offset _iso(double cy, double a, double b) =>
    Offset(512 + (a - b) * _halfWidth, cy - _halfHeight + (a + b) * _halfHeight);

void _glyph(Canvas c, double scale) {
  c.save();
  c.translate(512, 512);
  c.scale(scale);
  c.translate(-512, -550); // the stack's centre sits at y = 550
  for (final (cy, from, to) in _layers.reversed) {
    final rhombus = Path()
      ..moveTo(512, cy - _halfHeight)
      ..lineTo(512 + _halfWidth, cy)
      ..lineTo(512, cy + _halfHeight)
      ..lineTo(512 - _halfWidth, cy)
      ..close();
    final box = rhombus.getBounds();
    c.drawPath(rhombus, Paint()..shader = ui.Gradient.linear(box.topLeft, box.bottomRight, [from, to]));
  }
  final line = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..strokeWidth = 28
    ..strokeCap = StrokeCap.round;
  const top = 450.0;
  for (final (a1, b) in [(0.75, 0.3), (0.85, 0.48), (0.6, 0.66)]) {
    c.drawLine(_iso(top, 0.25, b), _iso(top, a1, b), line);
  }
  c.restore();
}

enum _Shape { square, rounded, none }

Future<void> _icon(String path, int px, {required _Shape bg, double scale = 1}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)..scale(px / 1024);
  const full = Rect.fromLTWH(0, 0, 1024, 1024);
  final fill = Paint()..color = _light;
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

ui.Paragraph _text(String s, double size, Color color, double width) {
  final b = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Brand', fontSize: size))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Brand', fontSize: size, height: 1.15))
    ..addText(s);
  return b.build()..layout(ui.ParagraphConstraints(width: width));
}

Future<void> _feature(String path, String tagline) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1024, 500),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(1024, 500), [
        const Color(0xFFF7F9FD),
        const Color(0xFFE4EAF6),
      ]),
  );
  c.save();
  c.translate(50, 30);
  c.scale(440 / 1024);
  _glyph(c, 1);
  c.restore();
  c.drawParagraph(_text('FileFlow', 96, _navy, 520), const Offset(480, 130));
  c.drawParagraph(_text(tagline, 40, _muted, 500), const Offset(484, 260));
  await _write(rec, path, 1024, 500);
}

void main() {
  test('render brand assets', () async {
    final font = File('/System/Library/Fonts/Supplemental/Arial Bold.ttf').readAsBytesSync();
    await ui.loadFontFromList(Uint8List.fromList(font), fontFamily: 'Brand');
    const res = 'android/app/src/main/res';
    const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final MapEntry(key: d, value: f) in densities.entries) {
      await _icon('$res/mipmap-$d/ic_launcher.png', (48 * f).round(), bg: _Shape.rounded, scale: 0.9);
      // Adaptive foreground: keeps the stack inside the 66 dp safe circle.
      await _icon('$res/mipmap-$d/ic_launcher_foreground.png', (108 * f).round(), bg: _Shape.none, scale: 0.8);
    }
    await _icon('docs/store/graphics/icon-512.png', 512, bg: _Shape.square, scale: 1);
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
      await _icon('$ios/Icon-App-$name.png', px, bg: _Shape.square, scale: 1);
    }
    await _feature('docs/store/graphics/feature-es.png', 'Tus PDF, en tu teléfono. Sin subir nada.');
    await _feature('docs/store/graphics/feature-en.png', 'Your PDFs, on your phone. Nothing uploaded.');
    await _feature('docs/store/graphics/feature-pt.png', 'Seus PDFs, no seu celular. Nada é enviado.');
  });
}
