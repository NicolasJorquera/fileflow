import 'dart:isolate';

/// A document opened in the engine's worker. Only the id crosses isolates; the
/// PDFium handle stays in the worker until [PdfEngine.close].
class DocHandle {
  const DocHandle(this.id, this.pageCount);

  final int id;
  final int pageCount;

  @override
  String toString() => 'DocHandle($id, $pageCount pages)';
}

class PdfInfo {
  const PdfInfo({required this.pageCount, required this.pagesScanned, required this.imagesOnScannedPages});

  final int pageCount;

  /// [inspect] looks at the first pages only (cheap preflight for big files).
  final int pagesScanned;
  final int imagesOnScannedPages;

  /// True when the scanned pages have no images: compression can barely help.
  bool get looksTextOnly => pagesScanned > 0 && imagesOnScannedPages == 0;
}

/// An image object on a loaded page and what recompressing it would involve.
class ImageSlot {
  const ImageSlot({
    required this.objectIndex,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.effectiveDpi,
    required this.isJpeg,
    required this.hasTransparency,
  });

  final int objectIndex;
  final int pixelWidth, pixelHeight;

  /// Pixels per inch at the size the image is drawn on the page.
  final double effectiveDpi;
  final bool isJpeg;

  /// Recompressing with FPDFImageObj_GetBitmap would drop the mask: skip these.
  final bool hasTransparency;
}

/// RGBA pixels already box-reduced by an integer factor; [targetWidth] x
/// [targetHeight] is the final size the platform codec should scale to.
class RgbaImage {
  const RgbaImage({
    required this.width,
    required this.height,
    required this.targetWidth,
    required this.targetHeight,
    required this.pixels,
  });

  final int width, height, targetWidth, targetHeight;
  final TransferableTypedData pixels;
}

/// Pixels of a rendered page on white: BGRA, or RGBA when asked for.
class RenderedPage {
  const RenderedPage({required this.width, required this.height, required this.pixels});

  final int width, height;
  final TransferableTypedData pixels;
}

/// Where a JPEG goes on a new page, in PDF points (1/72 inch).
class PageLayout {
  const PageLayout({required this.pageWidth, required this.pageHeight, this.margin = 0});

  final double pageWidth, pageHeight, margin;

  static const a4 = PageLayout(pageWidth: 595.28, pageHeight: 841.89);
  static const letter = PageLayout(pageWidth: 612, pageHeight: 792);

  /// Chilean «oficio», 216 x 330 mm.
  static const oficio = PageLayout(pageWidth: 612.28, pageHeight: 935.43);
}
