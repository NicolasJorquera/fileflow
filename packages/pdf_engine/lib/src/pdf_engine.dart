import 'dart:isolate';

import 'engine_result.dart';
import 'models.dart';

/// PDF operations as short tasks (one page or one image each) so callers can
/// report progress and cancel between them. No method throws for an expected
/// problem; see [EngineResult].
abstract interface class PdfEngine {
  /// Page count plus image statistics of the first [maxPagesToScan] pages.
  Future<EngineResult<PdfInfo>> inspect(String path, {int maxPagesToScan = 30});

  Future<EngineResult<DocHandle>> open(String path);
  Future<EngineResult<DocHandle>> createEmpty();

  /// Closes the document and any page still loaded. Safe to call twice.
  Future<void> close(DocHandle doc);

  /// Copies [pages] (0-based, all when null) of [src] into [dest] at index [at].
  Future<EngineResult<int>> importPages(DocHandle dest, DocHandle src, {List<int>? pages, required int at});
  Future<EngineResult<void>> rotatePage(DocHandle doc, int page, int quarterTurns);
  Future<EngineResult<void>> deletePage(DocHandle doc, int page);

  /// Appends a page holding [jpeg] fitted inside [layout] (aspect ratio kept).
  Future<EngineResult<void>> addJpegPage(DocHandle doc, TransferableTypedData jpeg, PageLayout layout);

  /// Loads [page] (it stays loaded until [finishPage]) and lists its images.
  Future<EngineResult<List<ImageSlot>>> imagesOnPage(DocHandle doc, int page);

  /// Decodes an image, box-reduces it towards [scale] (0 < scale ≤ 1) and
  /// returns RGBA for the platform JPEG codec.
  Future<EngineResult<RgbaImage>> extractImage(DocHandle doc, int page, int objectIndex, double scale);
  Future<EngineResult<void>> replaceImageWithJpeg(DocHandle doc, int page, int objectIndex, TransferableTypedData jpeg);

  /// Regenerates the page content when [changed] and unloads the page.
  Future<void> finishPage(DocHandle doc, int page, {required bool changed});

  /// Streams the document to [outPath]; never holds the whole output in memory.
  Future<EngineResult<void>> save(DocHandle doc, String outPath);

  /// Renders [page] on white, [widthPx] wide or at [dpi], capped at
  /// [maxWidthPx] (height keeps the aspect ratio). Pixels are BGRA, or RGBA
  /// for the platform codecs when [rgba] is true.
  Future<EngineResult<RenderedPage>> render(
    DocHandle doc,
    int page, {
    int? widthPx,
    double? dpi,
    int maxWidthPx = 4000,
    bool rgba = false,
  });
}
