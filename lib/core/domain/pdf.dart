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

/// How hard «Reducir tamaño» recompresses images (PRD H3): images above [dpi]
/// are resampled to it, and images that are not JPEG are re-encoded, at JPEG
/// [quality]. [extra] is only used by «ajustar a X MB» as a last attempt.
enum ReduceLevel {
  high(200, 85),
  balanced(150, 75),
  minimal(110, 60),
  extra(90, 50);

  const ReduceLevel(this.dpi, this.quality);

  final int dpi, quality;

  /// The levels people choose, best quality first.
  static const choices = [high, balanced, minimal];
}

class ReduceStats {
  const ReduceStats({required this.pages, required this.imagesChanged, required this.outputBytes});

  final int pages, imagesChanged, outputBytes;
}

/// Page sizes of «Fotos a PDF» (PRD H2). [auto] is resolved by region.
enum PagePreset { auto, a4, letter, oficio, fitImage }

/// How each photo becomes a page.
class PhotoPageSpec {
  const PhotoPageSpec({required this.preset, required this.margin, required this.dpi, required this.quality});

  /// Never [PagePreset.auto]: the caller resolves it first.
  final PagePreset preset;
  final bool margin;

  /// Photos are decoded scaled to at most this resolution on the page.
  final int dpi;
  final int quality;
}

/// A photo to place on its own page, turned [quarterTurns] × 90°.
class PhotoInput {
  const PhotoInput(this.path, [this.quarterTurns = 0]);

  final String path;
  final int quarterTurns;
}

class PhotosWritten {
  const PhotosWritten({required this.pages, required this.unreadable});

  final int pages;

  /// Photos the device could not decode; they were left out (E-IMG-01).
  final int unreadable;
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

  /// Recompresses the images of [input] at [level] into [output] (text and
  /// vectors are never rasterized; images with transparency are left alone).
  /// Progress is reported per page.
  Future<Result<ReduceStats>> reduce(
    String input,
    String output, {
    required ReduceLevel level,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  });

  /// Estimated output/input size ratio of [reduce] at each of [levels],
  /// measured on a few evenly spread pages so «ajustar a X MB» does not
  /// compress the whole document once per attempt.
  Future<Result<Map<ReduceLevel, double>>> estimateReduce(String input, List<ReduceLevel> levels, {CancelToken? token});

  /// One page per photo, in order, sized by [spec]. Photos the device cannot
  /// decode are skipped and counted.
  Future<Result<PhotosWritten>> photosToPdf(
    List<PhotoInput> photos,
    String output, {
    required PhotoPageSpec spec,
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

/// Page size in points for a photo of [width] × [height] pixels (PRD H2):
/// fixed sizes follow the photo's orientation; [PagePreset.fitImage] is the
/// photo itself at [PhotoPageSpec.dpi]. Margin is 10 mm when asked for.
PageBox pageBoxFor(PhotoPageSpec spec, int width, int height) {
  const mm = 72 / 25.4;
  final margin = spec.margin ? 10 * mm : 0.0;
  final (short, long) = switch (spec.preset) {
    PagePreset.a4 || PagePreset.auto => (210 * mm, 297 * mm),
    PagePreset.letter => (215.9 * mm, 279.4 * mm),
    PagePreset.oficio => (216 * mm, 330 * mm),
    PagePreset.fitImage => (0.0, 0.0),
  };
  if (spec.preset == PagePreset.fitImage) {
    return PageBox(width * 72 / spec.dpi + 2 * margin, height * 72 / spec.dpi + 2 * margin, margin);
  }
  return width > height ? PageBox(long, short, margin) : PageBox(short, long, margin);
}

/// The largest photo side, in pixels, worth decoding for [spec]: the long
/// side of the page at its dpi. Larger photos would only add bytes.
int maxPhotoSide(PhotoPageSpec spec) {
  final long = switch (spec.preset) {
    PagePreset.oficio => 330 / 25.4,
    _ => 297 / 25.4,
  };
  return (long * spec.dpi).round();
}

/// Letter where it is the norm (PRD H2: CL, MX, CO and US), A4 elsewhere.
PagePreset resolveAutoPage(String? countryCode) =>
    const {'CL', 'MX', 'CO', 'US', 'CA', 'PH'}.contains(countryCode?.toUpperCase()) ? PagePreset.letter : PagePreset.a4;

/// A page in PDF points with the margin around its content.
class PageBox {
  const PageBox(this.width, this.height, this.margin);

  final double width, height, margin;
}
