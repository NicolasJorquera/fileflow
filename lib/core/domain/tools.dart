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
