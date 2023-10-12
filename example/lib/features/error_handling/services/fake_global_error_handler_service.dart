import 'package:simple_architecture/simple_architecture.dart';

import '../domain/i_global_error_handler_service.dart';

/// This is an actual implementation of the [IGlobalErrorHandlerService] service
/// that will be used in the [GlobalErrorHandlerPipelineBehavior].
///
/// In a real-world application, that would be an implementation for error
/// logging into Firebase Crashlytics or Sentry.
///
/// Remember that you can decorate your services with [IInitializable], so
/// `void initialize()` runs every time this class is instantiated and/or
/// [IBootable], so `async void initializeAsync()` runs *when this class is
/// specially registered as a bootable singleton*, so you can initialize all
/// required stuff your implemenation/external services needs.
final class FakeGlobalErrorHandlerService
    implements IGlobalErrorHandlerService {
  const FakeGlobalErrorHandlerService();

  @override
  Future<void> logError({
    required String message,
    required Object exception,
    StackTrace? stackTrace,
  }) async {
    final logger = Logger<FakeGlobalErrorHandlerService>();

    logger.warning(
      "I am just an example and I do not do anything useful, just "
      "here to say that something has crashed!",
    );

    logger.error(message, exception, stackTrace);
  }
}
