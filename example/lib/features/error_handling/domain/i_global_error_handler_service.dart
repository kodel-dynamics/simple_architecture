/// This is a contract for a service. You can inject this interface in other
/// services or business logic (pipeline handlers, request handlers, etc.). The
/// actual implementation of this feature (the ability to log an exception to
/// an external service, such as Crashlytics or Sentry) is unknown to the
/// application itself.
abstract interface class IGlobalErrorHandlerService {
  /// Logs an error to the global error handler service.
  ///
  /// [message] can be any message you want to pass to the error service.
  /// [exception] the error thrown.
  /// [stackTrace] the optional stack trace.
  Future<void> logError({
    required String message,
    required Object exception,
    StackTrace? stackTrace,
  });
}
