/// Outcome of an engine task. Failures are data: the engine never throws for an
/// expected problem, so callers keep the error code (pdfrx's worker turns
/// thrown errors into strings and the code would be lost).
sealed class EngineResult<T> {
  const EngineResult();

  T get valueOrThrow => switch (this) {
    EngineOk<T>(:final value) => value,
    EngineErr<T>(:final failure) => throw StateError('EngineErr: $failure'),
  };
}

final class EngineOk<T> extends EngineResult<T> {
  const EngineOk(this.value);

  final T value;
}

final class EngineErr<T> extends EngineResult<T> {
  const EngineErr(this.failure);

  final EngineFailure failure;
}

enum EngineErrorCode {
  /// File missing or unreadable (FPDF_ERR_FILE).
  io,

  /// Not a PDF, damaged or truncated (FPDF_ERR_FORMAT, FPDF_ERR_UNKNOWN).
  damaged,

  /// Password protected (FPDF_ERR_PASSWORD).
  passwordRequired,

  /// Security handler PDFium cannot open (FPDF_ERR_SECURITY).
  unsupportedSecurity,

  /// A page could not be loaded (FPDF_ERR_PAGE or a null page).
  pageUnreadable,

  /// An embedded image in a format we cannot re-encode.
  imageUnsupported,

  /// Writing the output failed, typically for lack of space.
  writeFailed,

  /// A handle was used after close or never existed (a bug in the caller).
  invalidHandle,

  /// Anything else; [EngineFailure.message] goes to the local log only.
  internal,
}

class EngineFailure {
  const EngineFailure(this.code, [this.message = '']);

  final EngineErrorCode code;

  /// Diagnostic text. Never contains file names or paths.
  final String message;

  @override
  String toString() => '${code.name}${message.isEmpty ? '' : ': $message'}';
}
