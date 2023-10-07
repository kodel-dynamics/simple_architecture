part of '../../simple_architecture.dart';

/// A required element was not found.
///
/// This exception is thrown, for example, in dependency injection when you ask
/// for a type that wasn't registered.
final class ElementNotFoundException implements Exception {
  const ElementNotFoundException({required this.message});

  final String message;
}
