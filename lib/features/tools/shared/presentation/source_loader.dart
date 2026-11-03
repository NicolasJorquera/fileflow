import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/jobs/jobs.dart';
import 'tool_args.dart';

/// The one PDF Organizar or PDF a imagen works on, ready to read.
class LoadedSource {
  const LoadedSource({required this.file, required this.pageCount});

  final LocalFile file;
  final int pageCount;
}

/// Brings the PDF of a single-document tool into the app: copies a picked or
/// shared file into the tool's job folder (results in Recientes are read in
/// place) and reads its page count. Owns the folder; [dispose] deletes it.
class SourceLoader {
  SourceLoader({required this._files, required this._pdf, required this._workspace});

  final FileGateway _files;
  final PdfService _pdf;
  final JobWorkspace _workspace;
  final _token = CancelToken();
  Future<JobDir>? _dir;

  /// Opens the system picker; null when the user cancels it.
  Future<Result<LoadedSource>?> pick() async {
    switch (await _files.pickPdfs()) {
      case Ok(:final value) when value.isEmpty:
        return null;
      case Ok(:final value):
        return _import(value.first);
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// Null when [args] brings nothing: the tool then asks for a file.
  Future<Result<LoadedSource>?> fromArgs(ToolArgs args) async {
    if (args.local.isNotEmpty) return _inspect(args.local.first);
    if (args.picked.isNotEmpty) return _import(args.picked.first);
    return null;
  }

  Future<Result<LoadedSource>> _import(PickedFile picked) async {
    final dir = await (_dir ??= _workspace.create());
    return switch (await _files.importToJob(picked, dir, token: _token)) {
      Ok(:final value) => _inspect(value),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<LoadedSource>> _inspect(LocalFile file) async =>
      (await _pdf.inspect(file.path)).map((summary) => LoadedSource(file: file, pageCount: summary.pageCount));

  Future<void> dispose() async {
    _token.cancel();
    final dir = _dir;
    if (dir != null) await _workspace.delete(await dir);
  }
}
