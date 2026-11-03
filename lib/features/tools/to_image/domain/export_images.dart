import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/domain/produce_result.dart';

/// PDF a imagen (PRD H6, built in H5): one image per page, «nombre-p01.jpg»,
/// kept together in one result.
class ExportImages {
  ExportImages({required this._pdf, required this._recents});

  final PdfService _pdf;
  final RecentsRepository _recents;

  /// File names for [pages] (0-based) of a [pageCount]-page document called
  /// [sourceName]: the page number is padded to the longest one, at least 2.
  static List<String> namesFor(String sourceName, List<int> pages, int pageCount, ImageFormat format) {
    final stem = fileStem(safeFileName(sourceName));
    final width = '$pageCount'.length < 2 ? 2 : '$pageCount'.length;
    return [for (final p in pages) '$stem-p${'${p + 1}'.padLeft(width, '0')}.${format.extension}'];
  }

  JobBody call(
    LocalFile source,
    List<int> pages, {
    required int pageCount,
    required String setName,
    required ImageFormat format,
    required int dpi,
  }) {
    final names = namesFor(source.name, pages, pageCount, format);
    return produceResult(
      recents: _recents,
      name: setName,
      kind: ResultKind.images,
      inputBytes: source.sizeBytes,
      write: (slot, token, progress) async => (await _pdf.exportImages(
        source.path,
        pages,
        [for (final n in names) '${slot.dir}/$n'],
        format: format,
        dpi: dpi,
        token: token,
        onProgress: progress,
      )).map((_) => Written(pages: pages.length, files: names)),
    );
  }
}
