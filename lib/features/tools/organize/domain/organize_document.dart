import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/domain/produce_result.dart';

/// Organizar páginas (PRD H5): every change is written to a new PDF; the
/// source stays as it was (RN-05).
class OrganizeDocument {
  OrganizeDocument({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  /// «Guardar» ([ResultKind.edited]) or «Extraer» ([ResultKind.extracted]):
  /// one PDF with [pages] in that order.
  JobBody save(LocalFile source, List<PageRef> pages, {required String name, required ResultKind kind}) =>
      produceResult(
        recents: _recents,
        name: name,
        kind: kind,
        inputBytes: source.sizeBytes,
        write: (slot, token, progress) async => (await _pdf.compose(
          source.path,
          pages,
          slot.path,
          token: token,
          onProgress: progress,
        )).map((count) => Written(pages: count)),
      );

  /// «Separar»: one PDF per part, kept together in one result called
  /// [setName]. [partNames] are the file names, one per part.
  JobBody split(
    LocalFile source,
    List<List<PageRef>> parts, {
    required String setName,
    required List<String> partNames,
  }) {
    assert(parts.length == partNames.length);
    final names = [for (final n in partNames) safeFileName(n)];
    return produceResult(
      recents: _recents,
      name: setName,
      kind: ResultKind.split,
      inputBytes: source.sizeBytes,
      write: (slot, token, progress) async {
        var pages = 0;
        for (final (i, part) in parts.indexed) {
          final written = await _pdf.compose(source.path, part, '${slot.dir}/${names[i]}', token: token);
          switch (written) {
            case Ok(:final value):
              pages += value;
            case Err(:final failure):
              return Err(failure);
          }
          progress(i + 1, parts.length);
        }
        return Ok(Written(pages: pages, files: names));
      },
    );
  }
}
