import 'package:fileflow/features/tools/organize/domain/page_ranges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRanges', () {
    test('«1-3, 5, 8-10» is three ranges', () {
      final parsed = parseRanges('1-3, 5, 8-10', 12) as RangesOk;
      expect(parsed.ranges, const [PageRange(1, 3), PageRange(5, 5), PageRange(8, 10)]);
      expect([for (final r in parsed.ranges) ...r.indices], [0, 1, 2, 4, 7, 8, 9]);
    });

    test('accepts the separators phones type', () {
      expect((parseRanges(' 1 – 3 ;5,,8—10 ', 12) as RangesOk).ranges.length, 3);
    });

    for (final (text, problem, token) in [
      ('', RangeProblem.empty, ''),
      (' , ', RangeProblem.empty, ''),
      ('1-3, x', RangeProblem.notANumber, 'x'),
      ('1-', RangeProblem.notANumber, '1-'),
      ('2-4-6', RangeProblem.notANumber, '2-4-6'),
      ('0', RangeProblem.outOfRange, '0'),
      ('11-13', RangeProblem.outOfRange, '11-13'),
      ('13', RangeProblem.outOfRange, '13'),
      ('5-3', RangeProblem.reversed, '5-3'),
    ]) {
      test('«$text» is invalid: $problem', () {
        final parsed = parseRanges(text, 12) as RangesInvalid;
        expect((parsed.problem, parsed.token), (problem, token));
      });
    }
  });

  test('describePages writes the shortest form', () {
    expect(describePages([8, 3, 4, 5, 4]), '3-5, 8');
    expect(describePages([1]), '1');
    expect(describePages([1, 3, 5]), '1, 3, 5');
  });

  group('SplitPlan', () {
    test('120 pages every 10 is 12 parts of 10', () {
      final parts = const SplitEvery(10).parts(120);
      expect(parts.length, 12);
      expect(parts.first, const PageRange(1, 10));
      expect(parts.last, const PageRange(111, 120));
    });

    test('the last part keeps the remainder', () {
      expect(const SplitEvery(4).parts(10), const [PageRange(1, 4), PageRange(5, 8), PageRange(9, 10)]);
    });

    test('one page per file', () {
      expect(const SplitEachPage().parts(3), const [PageRange(1, 1), PageRange(2, 2), PageRange(3, 3)]);
    });
  });
}
