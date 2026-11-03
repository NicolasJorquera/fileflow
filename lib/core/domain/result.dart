import 'failures.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Expected failures travel as [Err] values instead of exceptions, so every
/// failure reaches the UI as an [AppFailure] with its localized message.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  /// The value, or null when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok(transform(value)),
    Err<T>(:final failure) => Err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
