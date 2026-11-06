import 'package:fileflow/core/domain/pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mm = 72 / 25.4;
  PhotoPageSpec spec(PagePreset preset, {bool margin = false, int dpi = 200}) =>
      PhotoPageSpec(preset: preset, margin: margin, dpi: dpi, quality: 80);

  test('fixed sizes follow the photo orientation', () {
    final portrait = pageBoxFor(spec(PagePreset.a4), 3000, 4000);
    expect(portrait.width, closeTo(210 * mm, 0.01));
    expect(portrait.height, closeTo(297 * mm, 0.01));
    final landscape = pageBoxFor(spec(PagePreset.letter), 4000, 3000);
    expect(landscape.width, closeTo(279.4 * mm, 0.01));
    expect(landscape.height, closeTo(215.9 * mm, 0.01));
    final oficio = pageBoxFor(spec(PagePreset.oficio), 1000, 2000);
    expect(oficio.height, closeTo(330 * mm, 0.01));
  });

  test('«Ajustar a la foto» is the photo at the chosen resolution, plus the margin', () {
    final box = pageBoxFor(spec(PagePreset.fitImage, margin: true, dpi: 200), 2000, 1000);
    expect(box.width, closeTo(2000 * 72 / 200 + 20 * mm, 0.01));
    expect(box.margin, closeTo(10 * mm, 0.01));
  });

  test('photos are never decoded larger than the page needs (≤ 300 dpi)', () {
    expect(maxPhotoSide(spec(PagePreset.a4, dpi: 300)), 3508);
    expect(maxPhotoSide(spec(PagePreset.oficio, dpi: 200)), 2598);
  });

  test('«Automático» is Letter in CL, MX, CO and US, A4 elsewhere', () {
    for (final c in ['CL', 'MX', 'CO', 'US', 'us']) {
      expect(resolveAutoPage(c), PagePreset.letter, reason: c);
    }
    for (final c in ['ES', 'AR', 'BR', 'DE', null]) {
      expect(resolveAutoPage(c), PagePreset.a4, reason: '$c');
    }
  });
}
