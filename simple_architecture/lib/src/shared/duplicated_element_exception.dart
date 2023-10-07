part of '../../simple_architecture.dart';

/// A duplicated element exists where it should be unique.
///
/// This exception is thrown, for example, in dependency injection registration,
/// since there can be only one registered type in the system.
final class DuplicatedElementException implements Exception {
  const DuplicatedElementException({required this.message});

  final String message;
}
