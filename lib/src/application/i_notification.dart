part of '../../simple_architecture.dart';

/// Classes that implements this contract serves as a notification message
/// for the [Mediator][publish] method.
///
/// Those notifications are published into a stream and whomever wants to listen
/// to those streams.
///
/// It is usually used to notify actions so unrelated classes can react when
/// your application does things, such as `CustomerCreatedNotification` being
/// published when your application logic successfully creates a customer, so
/// some other unrelated part of your code can know about it, without the need
/// of responding to it (that job is for `IQuery<TResponse>`).
abstract interface class INotification {}
