part of '../../simple_architecture.dart';

/// Represents a message that can be sent to [Mediator] and it will be handled
/// by some class that implements [IRequestHandler<TResponse, IRequest>].
///
/// This class should only contain primitive types, since it is a message.
///
/// It is a good idea to make it value equalitable with some package such as
/// https://pub.dev/packages/dart_mappable. Also, it is a good idea to always
/// return a [Result<T>] class as `TResponse` and never throw exceptions on
/// messages or handlers.
///
/// Requests are handled by its RequestHandler in a request/response manner (
/// i.e.: no streams are changed while processing a request).
abstract interface class IRequest<TResponse> {}

/// You must implement a class with this contract to handle what your
/// application do when a message [IRequest<TResponse>].
///
/// Ideally, your [TResponse] should be a [Result<T>] and all your business
/// logic should be inside a `try/catch`, so this handlers never fails with
/// exceptions.
abstract interface class IRequestHandler<TResponse,
    TRequest extends IRequest<TResponse>> {
  Future<TResponse> handle(TRequest request);
}
