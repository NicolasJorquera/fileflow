import '../../../../core/domain/failures.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/domain/produce_result.dart';

/// Fotos a PDF (PRD H2): one page per photo, in the chosen order.
class PhotosToPdf {
  PhotosToPdf({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  JobBody call(List<PhotoInput> photos, {required PhotoPageSpec spec, required String name, int? inputBytes}) {
    if (photos.isEmpty) return (_) => Stream.value(const JobFailed(Unexpected('no photos')));
    return produceResult(
      recents: _recents,
      name: name,
      kind: ResultKind.photos,
      inputBytes: inputBytes,
      write: (slot, token, progress) async => (await _pdf.photosToPdf(
        photos,
        slot.path,
        spec: spec,
        token: token,
        onProgress: progress,
      )).map((written) => Written(pages: written.pages)),
    );
  }
}
