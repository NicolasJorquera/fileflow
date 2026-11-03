import '../../../../core/domain/files.dart';

/// What a tool starts with: files chosen elsewhere (shared from another app,
/// «Elegir un PDF» in Recientes) or results already in the app («Siguiente
/// paso», «Usar en otra herramienta»). Empty means the tool asks for them.
class ToolArgs {
  const ToolArgs({this.picked = const [], this.local = const []});

  final List<PickedFile> picked;
  final List<LocalFile> local;

  bool get isEmpty => picked.isEmpty && local.isEmpty;
}
