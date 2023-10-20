part of '../../simple_architecture.dart';

final class CancellationToken {
  CancellationToken({required this.operationName});

  final String operationName;

  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel({String? message, Object? exception, StackTrace? stackTrace}) {
    if (message == null) {
      message = "$operationName is being cancelled";
    } else {
      message = "$operationName is being cancelled: $message";
    }

    if (exception == null) {
      logger.warning(message);
    } else {
      logger.error(message, exception, stackTrace);
    }

    _isCancelled = true;
  }
}
