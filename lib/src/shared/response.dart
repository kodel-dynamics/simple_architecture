part of '../../simple_architecture.dart';

sealed class Response<TValue, TFailure extends Enum> {
  const Response._({
    required TValue? value,
    required this.isSuccess,
    required TFailure? failure,
    required Object? exception,
    required this.stackTrace,
  })  : _value = value,
        _exception = exception,
        _failure = failure;

  final TValue? _value;
  TValue get value => _value as TValue;

  final TFailure? _failure;
  TFailure get failure => _failure!;

  final Object? _exception;
  Object get exception => _exception ?? Exception(_failure);

  final StackTrace? stackTrace;

  final bool isSuccess;
  bool get isFailure => !isSuccess;

  void ensureSuccess() {
    if (isSuccess) {
      return;
    }

    if (_exception == null) {
      throw failure;
    }

    if (stackTrace == null) {
      throw exception;
    }

    Error.throwWithStackTrace(exception, stackTrace!);
  }

  @override
  String toString() {
    if (isSuccess) {
      return "Success<$TValue>($value)";
    }

    if (_exception == null) {
      return "Failure<$TFailure>($failure)";
    }

    return "Failure<$TFailure>($failure) [${_exception.runtimeType}]";
  }

  @override
  bool operator ==(covariant Response<TValue, TFailure> other) {
    if (identical(this, other)) {
      return true;
    }

    return runtimeType == other.runtimeType &&
        _value == other._value &&
        _failure == other._failure &&
        _exception == other._exception &&
        stackTrace == other.stackTrace &&
        isSuccess == other.isSuccess;
  }

  @override
  int get hashCode {
    return _finish(
      [_value, _failure, _exception, stackTrace, isSuccess].fold(0, _combine),
    );
  }

  int _combine(int hash, Object? object) {
    hash = 0x1fffffff & (hash + object.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));

    return hash ^ (hash >> 6);
  }

  int _finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);

    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

final class Success<TValue, TFailure extends Enum>
    extends Response<TValue, TFailure> {
  const Success(TValue value)
      : super._(
          value: value,
          exception: null,
          failure: null,
          isSuccess: true,
          stackTrace: null,
        );
}

final class Failure<TValue, TFailure extends Enum>
    extends Response<TValue, TFailure> {
  const Failure(TFailure failure, [Object? exception, StackTrace? stackTrace])
      : super._(
          exception: exception,
          failure: failure,
          isSuccess: false,
          stackTrace: stackTrace,
          value: null,
        );

  Failure.from(Response<dynamic, TFailure> other)
      : super._(
          exception: other._exception,
          failure: other._failure,
          isSuccess: false,
          stackTrace: other.stackTrace,
          value: null,
        );
}
