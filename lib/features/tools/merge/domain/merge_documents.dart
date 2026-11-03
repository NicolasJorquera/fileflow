import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/domain/produce_result.dart';

/// Unir en uno solo (PRD H4): merges PDFs in the given order into a new result
/// in Recientes.
class MergeDocuments {
  MergeDocuments({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  JobBody call(List<LocalFile> inputs, {required String outputName}) {
    if (inputs.length < 2) return (_) => Stream.value(const JobFailed(Unexpected('merge needs two files')));
    return produceResult(
      recents: _recents,
      name: outputName,
      kind: ResultKind.merged,
      inputBytes: inputs.fold<int>(0, (sum, f) => sum + f.sizeBytes),
      write: (slot, token, progress) async => (await _pdf.merge(
        [for (final f in inputs) f.path],
        slot.path,
        token: token,
        onProgress: progress,
      )).map((pages) => Written(pages: pages)),
    );
  }
}
