/// Page ranges as people type them: «1-3, 5, 8-10» (PRD H5). Numbers are
/// 1-based positions; each comma group is one range.
class PageRange {
  const PageRange(this.first, this.last);

  final int first, last;

  int get length => last - first + 1;

  /// 0-based positions.
  Iterable<int> get indices sync* {
    for (var p = first; p <= last; p++) {
      yield p - 1;
    }
  }

  @override
  bool operator ==(Object other) => other is PageRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => first == last ? '$first' : '$first-$last';
}

/// Why a text is not a valid list of ranges; [token] is the part to fix.
enum RangeProblem { empty, notANumber, outOfRange, reversed }

sealed class RangeParse {
  const RangeParse();
}

final class RangesOk extends RangeParse {
  const RangesOk(this.ranges);

  final List<PageRange> ranges;
}

final class RangesInvalid extends RangeParse {
  const RangesInvalid(this.problem, [this.token = '']);

  final RangeProblem problem;
  final String token;
}

/// Parses «1-3, 5, 8-10» against a document of [pageCount] pages. Spaces are
/// ignored; «–» and «—» count as «-»; «;» counts as «,» (common on phones).
RangeParse parseRanges(String text, int pageCount) {
  final groups = text
      .replaceAll(RegExp('[–—]'), '-')
      .replaceAll(';', ',')
      .split(',')
      .map((g) => g.replaceAll(RegExp(r'\s'), ''))
      .where((g) => g.isNotEmpty)
      .toList();
  if (groups.isEmpty) return const RangesInvalid(RangeProblem.empty);
  final ranges = <PageRange>[];
  for (final group in groups) {
    final match = RegExp(r'^(\d{1,5})(?:-(\d{1,5}))?$').firstMatch(group);
    if (match == null) return RangesInvalid(RangeProblem.notANumber, group);
    final first = int.parse(match.group(1)!);
    final last = match.group(2) == null ? first : int.parse(match.group(2)!);
    if (first < 1 || last > pageCount || first > pageCount) return RangesInvalid(RangeProblem.outOfRange, group);
    if (last < first) return RangesInvalid(RangeProblem.reversed, group);
    ranges.add(PageRange(first, last));
  }
  return RangesOk(ranges);
}

/// The shortest way to write a set of 1-based pages: [3, 4, 5, 8] → «3-5, 8».
String describePages(Iterable<int> pages) {
  final sorted = pages.toSet().toList()..sort();
  final parts = <String>[];
  for (var i = 0; i < sorted.length; i++) {
    final start = sorted[i];
    while (i + 1 < sorted.length && sorted[i + 1] == sorted[i] + 1) {
      i++;
    }
    parts.add(start == sorted[i] ? '$start' : '$start-${sorted[i]}');
  }
  return parts.join(', ');
}

/// How Separar cuts a document.
sealed class SplitPlan {
  const SplitPlan();

  /// The parts as ranges over a document of [pageCount] pages.
  List<PageRange> parts(int pageCount);
}

final class SplitEvery extends SplitPlan {
  const SplitEvery(this.size);

  final int size;

  @override
  List<PageRange> parts(int pageCount) => [
    for (var first = 1; first <= pageCount; first += size) PageRange(first, (first + size - 1).clamp(1, pageCount)),
  ];
}

final class SplitByRanges extends SplitPlan {
  const SplitByRanges(this.ranges);

  final List<PageRange> ranges;

  @override
  List<PageRange> parts(int pageCount) => ranges;
}

final class SplitEachPage extends SplitPlan {
  const SplitEachPage();

  @override
  List<PageRange> parts(int pageCount) => [for (var p = 1; p <= pageCount; p++) PageRange(p, p)];
}
