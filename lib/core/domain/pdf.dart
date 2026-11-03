import '../jobs/jobs.dart';
import 'result.dart';

class PdfSummary {
  const PdfSummary({required this.pageCount, required this.looksTextOnly});

  final int pageCount;

  /// The first pages have no images: compression would barely help.
  final bool looksTextOnly;
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
}
