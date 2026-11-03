import 'dart:typed_data';

import '../jobs/jobs.dart';
import 'files.dart';
import 'result.dart';

class PdfSummary {
  const PdfSummary({required this.pageCount, required this.looksTextOnly});

  final int pageCount;

  /// The first pages have no images: compression would barely help.
  final bool looksTextOnly;
}

/// One page of a source document as it goes into a new one: its 0-based
/// [index] in the source, turned [quarterTurns] × 90° clockwise.
class PageRef {
  const PageRef(this.index, [this.quarterTurns = 0]);

  final int index;
  final int quarterTurns;

  @override
  bool operator ==(Object other) => other is PageRef && other.index == index && other.quarterTurns == quarterTurns;

  @override
  int get hashCode => Object.hash(index, quarterTurns);

  @override
  String toString() => 'PageRef($index, $quarterTurns)';
}

/// PDF operations the tools need, with failures as [AppFailure]s. Implemented
/// on the pdf_engine package (lib/data/pdf); the domain never sees PDFium.
abstract interface class PdfService {
  Future<Result<PdfSummary>> inspect(String path);

  /// Merges [inputs] in order into [output] and returns its page count.
  /// Reports progress after each input and after saving; stops between steps
  /// once [token] is cancelled (returns Err(Cancelled) and leaves no output).
  Future<Result<int>> merge(
    List<String> inputs,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  });

  /// Writes a new PDF at [output] with [pages] of [input] in that order
  /// (Organizar: save, extract and each part of a split). Returns its page
  /// count. Same progress and cancellation contract as [merge].
  Future<Result<int>> compose(
    String input,
    List<PageRef> pages,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  });

  /// Renders each of [pages] (0-based) of [input] to the matching path in
  /// [outputs] at [dpi], never wider than 4.000 px (PRD H6). Returns the total
  /// bytes written. Progress is reported per page.
  Future<Result<int>> exportImages(
    String input,
    List<int> pages,
    List<String> outputs, {
    required ImageFormat format,
    required int dpi,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  });
}

/// Page previews for grids (Organizar, «Elegir páginas»). A screen opens one
/// [Thumbnails] per document and closes it when it goes away.
abstract interface class ThumbnailSource {
  Future<Result<Thumbnails>> open(String path);
}

abstract interface class Thumbnails {
  int get pageCount;

  /// JPEG bytes of page [index] (0-based). The most recent requests are served
  /// first, so the pages on screen come before the ones scrolled past.
  /// Completes with null when cancelled or closed.
  Future<Uint8List?> page(int index);

  /// Drops a pending request (its tile left the screen).
  void cancel(int index);
  Future<void> close();
}
