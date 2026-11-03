import 'package:intl/intl.dart';

/// Formats a byte count for people, using the locale's decimal separator:
/// "1,7 MB" in Spanish, "1.7 MB" in English. Units follow the PRD (MB = 2^20).
String formatBytes(int bytes, String locale) {
  const kb = 1024, mb = 1024 * 1024;
  if (bytes >= mb) {
    final value = bytes / mb;
    final digits = value >= 100 ? 0 : 1;
    return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits).format(value)} MB';
  }
  if (bytes >= kb) {
    return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0).format(bytes / kb)} KB';
  }
  return '${NumberFormat.decimalPattern(locale).format(bytes)} B';
}
