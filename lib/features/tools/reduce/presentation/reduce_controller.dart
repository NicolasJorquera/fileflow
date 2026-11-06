import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/presentation/run_job.dart';
import '../../shared/presentation/source_loader.dart';
import '../../shared/presentation/tool_args.dart';
import '../domain/reduce_document.dart';

enum ReduceMode { size, quality }

const _mb = 1024 * 1024;

class ReduceState {
  const ReduceState({
    this.loading = false,
    this.failure,
    this.source,
    this.mode = ReduceMode.size,
    this.targetMb = 2,
    this.level = ReduceLevel.balanced,
  });

  final bool loading;
  final AppFailure? failure;
  final LoadedSource? source;
  final ReduceMode mode;

  /// «Tamaño máximo» in MB; may be a custom value from «Otro…».
  final double targetMb;
  final ReduceLevel level;

  int get targetBytes => (targetMb * _mb).round();

  ReduceGoal get goal => mode == ReduceMode.size ? FitUnder(targetBytes) : ReduceAtLevel(level);

  bool get isBig =>
      source != null && (source!.file.sizeBytes > ReduceLimits.softBytes || source!.pageCount > ReduceLimits.softPages);

  /// Over the hard limits: refused, with a shortcut to Separar.
  bool get isTooBig =>
      source != null && (source!.file.sizeBytes > ReduceLimits.maxBytes || source!.pageCount > ReduceLimits.maxPages);

  ReduceState copyWith({ReduceMode? mode, double? targetMb, ReduceLevel? level}) => ReduceState(
    source: source,
    mode: mode ?? this.mode,
    targetMb: targetMb ?? this.targetMb,
    level: level ?? this.level,
  );
}

final reduceControllerProvider = NotifierProvider.autoDispose<ReduceController, ReduceState>(ReduceController.new);

/// Reducir tamaño: the file, a diagnosis, the goal (size or quality) and the
/// button that says what will happen.
class ReduceController extends Notifier<ReduceState> {
  late SourceLoader _loader;

  @override
  ReduceState build() {
    final loader = _loader = SourceLoader(
      files: ref.read(fileGatewayProvider),
      pdf: ref.read(pdfServiceProvider),
      workspace: ref.read(jobWorkspaceProvider),
    );
    ref.onDispose(loader.dispose);
    return const ReduceState();
  }

  Future<void> start(ToolArgs args) => _load(() => _loader.fromArgs(args));

  Future<void> pick() => _load(_loader.pick);

  Future<void> _load(Future<Result<LoadedSource>?> Function() load) async {
    final previous = state;
    state = ReduceState(loading: true, mode: previous.mode, targetMb: previous.targetMb, level: previous.level);
    final result = await load();
    if (!ref.mounted) return;
    state = switch (result) {
      null => previous,
      Ok(:final value) => ReduceState(
        source: value,
        mode: previous.mode,
        targetMb: previous.targetMb,
        level: previous.level,
      ),
      Err(:final failure) => ReduceState(
        failure: failure,
        mode: previous.mode,
        targetMb: previous.targetMb,
        level: previous.level,
      ),
    };
  }

  void setMode(ReduceMode mode) => state = state.copyWith(mode: mode);
  void setTarget(double mb) => state = state.copyWith(targetMb: mb);
  void setLevel(ReduceLevel level) => state = state.copyWith(level: level);

  Job reduce(String name) =>
      runKeepingAlive(ref, ref.read(reduceDocumentProvider).call(state.source!.file, state.goal, name: name));
}
