/// The tools of the catalog. Presentation describes them (name, icon, colour)
/// in features/tools/registry.dart; the domain only needs their identity.
enum ToolId { merge, reduce, scan, imagesToPdf, organize, pdfToImage }

/// Hard limits from the PRD (H4 Unir).
abstract final class MergeLimits {
  static const maxFiles = 20;
  static const maxPages = 500;

  /// Soft limit: above this the UI warns that it may take a while.
  static const softTotalBytes = 300 * 1024 * 1024;
}

/// PRD H5 Organizar páginas: a warning above [softPages], refused above
/// [maxPages].
abstract final class OrganizeLimits {
  static const softPages = 300;
  static const maxPages = 1000;
}

/// PRD H6 PDF a imagen.
abstract final class ToImageLimits {
  static const maxPages = 200;
  static const dpiChoices = [72, 150, 300];
  static const defaultDpi = 150;
}

/// PRD H3 Reducir tamaño: a time warning above the soft limits, refused
/// above the hard ones (with a shortcut to Separar).
abstract final class ReduceLimits {
  static const softBytes = 100 * 1024 * 1024, softPages = 150;
  static const maxBytes = 300 * 1024 * 1024, maxPages = 500;

  /// The sizes offered by «Tamaño máximo», in MB.
  static const targetsMb = [1, 2, 5, 10];
}

/// PRD H2 Fotos a PDF.
abstract final class PhotoLimits {
  static const maxPhotos = 100;
}

/// PRD H1 Escanear.
abstract final class ScanLimits {
  static const maxPages = 50;
}
