import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:listo_pdf/core/domain/failures.dart';
import 'package:listo_pdf/core/domain/result.dart';
import 'package:listo_pdf/core/format/sizes.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Result', () {
    test('map transforms Ok and keeps Err', () {
      expect(const Ok(2).map((v) => v * 3).valueOrNull, 6);
      final err = const Err<int>(PdfDamaged()).map((v) => v * 3);
      expect(err, isA<Err<int>>());
      expect((err as Err<int>).failure, isA<PdfDamaged>());
    });
  });

  group('formatBytes', () {
    const mb = 1024 * 1024;
    test('uses the locale decimal separator', () {
      expect(formatBytes((1.7 * mb).round(), 'es'), '1,7 MB');
      expect(formatBytes((1.7 * mb).round(), 'en'), '1.7 MB');
      expect(formatBytes((1.7 * mb).round(), 'pt_BR'), '1,7 MB');
    });

    test('drops decimals from 100 MB and switches to KB below 1 MB', () {
      expect(formatBytes(131 * mb, 'es'), '131 MB');
      expect(formatBytes(640 * 1024, 'es'), '640 KB');
    });
  });
}
