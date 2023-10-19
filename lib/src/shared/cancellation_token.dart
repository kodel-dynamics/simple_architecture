part of '../../simple_architecture.dart';

final class CancellationToken {
  CancellationToken({required this.operationName});

  final String operationName;

  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  final _logger = const Logger<CancellationToken>();

  void cancel({String? message, Object? exception, StackTrace? stackTrace}) {
    if (message == null) {
      message = "$operationName is being cancelled";
    } else {
      message = "$operationName is being cancelled: $message";
    }

    if (exception == null) {
      _logger.warning(message);
    } else {
      _logger.error(message, exception, stackTrace);
    }

    _isCancelled = true;
  }
}
