import 'package:simple_architecture/simple_architecture.dart';

import 'i_global_error_handler_service.dart';

/// The logger is here because, otherwise, [GlobalErrorHandlerPipelineBehavior]
/// could not be const. Since the logger doesn't have state, it's not a problem
/// to make it a global static variable.
final _logger = Logger<GlobalErrorHandlerPipelineBehavior>();

/// This pipeline behavior is executed every time a message is sent to
/// [$.mediator], so any exceptions thrown can be intercepted and logged.
final class GlobalErrorHandlerPipelineBehavior implements IPipelineBehavior {
  /// The [IGlobalErrorHandlerService] is a contract without any code that
  /// specifies a service that can handle global exceptions and log them.
  ///
  /// A useful real-world implementation of this interface would be a service
  /// that uses Firebase Crashlytics, Sentry, etc.
  ///
  /// This pipeline then contains only generic business logic (that know nothing
  /// about Crashlytics, Sentry, etc.). It is ok for this kind of business
  /// logic be almost empty, only calling the service itself.
  const GlobalErrorHandlerPipelineBehavior({
    required IGlobalErrorHandlerService globalErrorHandlerService,
  }) : _globalErrorHandlerService = globalErrorHandlerService;

  final IGlobalErrorHandlerService _globalErrorHandlerService;

  /// This handler can do things before and after the pipeline execution, so
  /// it is a good candidate for a global try/catch.
  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) async {
    // You can log whatever you want (maybe this should be a `debug` level,
    // so it won't appear on release)
    _logger.info("Handling ${request.runtimeType} with care");

    try {
      // Continue the pipeline, running all other pipeline behaviors and the
      // actual request handler.
      return await next(request);
    } catch (ex, stackTrace) {
      // Something terrible has happened!
      _logger.error(
        "$GlobalErrorHandlerPipelineBehavior is catching an error",
        ex,
        stackTrace,
      );

      // Let's inform the global error handler service to log this
      // error (notice that we don't care if that service is using
      // Crashlytics, Sentry, whatever)
      await _globalErrorHandlerService.logError(
        message: "$GlobalErrorHandlerPipelineBehavior caught a "
            "${ex.runtimeType} error",
        exception: ex,
        stackTrace: stackTrace,
      );

      // We're rethrowing the original exception with the original stacktrace,
      // so the app crashes as intended (this behavior only purpose is to tell
      // an external service that some error occurred)
      rethrow;
    }
  }
}
