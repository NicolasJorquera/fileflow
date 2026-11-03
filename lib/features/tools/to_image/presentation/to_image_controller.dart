import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/presentation/run_job.dart';
import '../../shared/presentation/source_loader.dart';
import '../../shared/presentation/tool_args.dart';

class ToImageState {
  const ToImageState({
    this.loading = false,
    this.failure,
    this.source,
    this.format = ImageFormat.jpeg,
    this.dpi = ToImageLimits.defaultDpi,
    this.pages,
  });

  final bool loading;
  final AppFailure? failure;
  final LoadedSource? source;
  final ImageFormat format;
  final int dpi;

  /// Chosen pages (0-based, in document order); null means all.
  final List<int>? pages;

  List<int> get chosen => pages ?? [for (var i = 0; i < (source?.pageCount ?? 0); i++) i];
  bool get tooMany => chosen.length > ToImageLimits.maxPages;
  bool get canConvert => source != null && chosen.isNotEmpty && !tooMany;

  /// Rough output size: an A4 page at [dpi] and the bytes per pixel a
  /// document page usually takes (mostly white). Shown as «unos X MB».
  int get estimatedBytes {
    final pixels = (8.27 * dpi) * (11.69 * dpi);
    final perPixel = format == ImageFormat.jpeg ? 0.12 : 0.45;
    return (pixels * perPixel * chosen.length).round();
  }

  ToImageState copyWith({ImageFormat? format, int? dpi, List<int>? Function()? pages}) => ToImageState(
    source: source,
    format: format ?? this.format,
    dpi: dpi ?? this.dpi,
    pages: pages == null ? this.pages : pages(),
  );
}

final toImageControllerProvider = NotifierProvider.autoDispose<ToImageController, ToImageState>(ToImageController.new);

/// PDF a imagen: format, resolution and pages, then one image per page.
class ToImageController extends Notifier<ToImageState> {
  late SourceLoader _loader;

  @override
  ToImageState build() {
    final loader = _loader = SourceLoader(
      files: ref.read(fileGatewayProvider),
      pdf: ref.read(pdfServiceProvider),
      workspace: ref.read(jobWorkspaceProvider),
    );
    ref.onDispose(loader.dispose);
    return const ToImageState();
  }

  Future<void> start(ToolArgs args) => _load(() => _loader.fromArgs(args));

  /// Also «Cambiar»: a new file keeps the format and resolution.
  Future<void> pick() => _load(_loader.pick);

  Future<void> _load(Future<Result<LoadedSource>?> Function() load) async {
    final previous = state;
    state = ToImageState(loading: true, format: previous.format, dpi: previous.dpi);
    final result = await load();
    if (!ref.mounted) return;
    state = switch (result) {
      null => previous,
      Ok(:final value) => ToImageState(source: value, format: previous.format, dpi: previous.dpi),
      Err(:final failure) => ToImageState(failure: failure, format: previous.format, dpi: previous.dpi),
    };
  }

  void setFormat(ImageFormat format) => state = state.copyWith(format: format);
  void setDpi(int dpi) => state = state.copyWith(dpi: dpi);

  /// [pages] null or all of them means «Todas».
  void setPages(List<int>? pages) => state = state.copyWith(
    pages: () => pages == null || pages.length == state.source!.pageCount ? null : ([...pages]..sort()),
  );

  Job convert(String setName) {
    final source = state.source!;
    final body = ref
        .read(exportImagesProvider)
        .call(
          source.file,
          state.chosen,
          pageCount: source.pageCount,
          setName: setName,
          format: state.format,
          dpi: state.dpi,
        );
    return runKeepingAlive(ref, body);
  }
}
