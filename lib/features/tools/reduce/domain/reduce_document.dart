import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/domain/produce_result.dart';

/// What «Reducir tamaño» aims for.
sealed class ReduceGoal {
  const ReduceGoal();
}

/// «Calidad»: one pass at a fixed level.
final class ReduceAtLevel extends ReduceGoal {
  const ReduceAtLevel(this.level);

  final ReduceLevel level;
}

/// «Tamaño máximo»: the best quality that fits in [bytes] (PRD RN-04).
final class FitUnder extends ReduceGoal {
  const FitUnder(this.bytes);

  final int bytes;
}

/// Reducir tamaño (PRD H3). Never delivers a file that is not smaller than the
/// original (RN-03: fails with [AlreadyOptimized]) and never claims a size
/// goal it did not meet (RN-04: the result keeps the goal, the screen says
/// whether it was met).
class ReduceDocument {
  ReduceDocument({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  /// Leaves room for the estimate's error so the first full pass usually fits.
  static const _estimateMargin = 0.95;

  /// The levels «ajustar a X MB» tries, best quality first.
  static const fitLevels = [ReduceLevel.high, ReduceLevel.balanced, ReduceLevel.minimal, ReduceLevel.extra];

  /// The first level of [fitLevels] whose estimated size fits [target]; the
  /// last one when none does.
  static int firstLevelToTry(Map<ReduceLevel, double> ratios, int sourceBytes, int target) {
    for (final (i, level) in fitLevels.indexed) {
      final ratio = ratios[level];
      if (ratio != null && sourceBytes * ratio <= target * _estimateMargin) return i;
    }
    return fitLevels.length - 1;
  }

  JobBody call(LocalFile source, ReduceGoal goal, {required String name}) => produceResult(
    recents: _recents,
    name: name,
    kind: ResultKind.reduced,
    inputBytes: source.sizeBytes,
    targetBytes: switch (goal) {
      FitUnder(:final bytes) => bytes,
      ReduceAtLevel() => null,
    },
    write: (slot, token, progress) async {
      final Result<ReduceStats> result;
      switch (goal) {
        case ReduceAtLevel(:final level):
          result = await _pdf.reduce(source.path, slot.path, level: level, token: token, onProgress: progress);
        case FitUnder(:final bytes):
          result = await _fit(source, bytes, slot.path, token, progress);
      }
      return switch (result) {
        Ok(:final value) when value.imagesChanged == 0 || value.outputBytes >= source.sizeBytes => const Err(
          AlreadyOptimized(),
        ),
        Ok(:final value) => Ok(Written(pages: value.pages)),
        Err(:final failure) => Err(failure),
      };
    },
  );

  /// Estimates on a sample, then compresses at the best level expected to fit
  /// and steps down while the real result is still too big. Each attempt
  /// overwrites the previous one: lower levels only produce smaller files.
  Future<Result<ReduceStats>> _fit(
    LocalFile source,
    int target,
    String output,
    CancelToken token,
    void Function(int, int) progress,
  ) async {
    final Map<ReduceLevel, double> ratios;
    switch (await _pdf.estimateReduce(source.path, fitLevels, token: token)) {
      case Ok(:final value):
        ratios = value;
      case Err(:final failure):
        return Err(failure);
    }
    Result<ReduceStats>? last;
    for (var i = firstLevelToTry(ratios, source.sizeBytes, target); i < fitLevels.length; i++) {
      last = await _pdf.reduce(source.path, output, level: fitLevels[i], token: token, onProgress: progress);
      switch (last) {
        case Ok(:final value) when value.outputBytes <= target:
          return last;
        case Ok():
          continue;
        case Err():
          return last;
      }
    }
    return last!;
  }
}
