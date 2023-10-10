part of '../../simple_architecture.dart';

/// Pipeline behaviors will be called before your `IQueryHandler` or
/// `IRequestHandler` is called.
///
/// Some examples of pipeline behavior:
/// * Performance measurements: you start a new [StopWatch] before the
/// `handler` and prints the ellapsed time after that call, so you know how
/// much time some handler takes to execute.
/// * Global error handlers: if your handlers throw some error (or if you are
/// using [Result<T>] and it is a [Failure], you can log the error or even
/// send it to Firebase Crashlytics)
/// * Logging: you can log all business logic methods being called, with the
/// input and output parameters for audit or debugging.
abstract interface class IPipelineBehavior {
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  );
}
