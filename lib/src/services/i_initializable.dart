part of '../../simple_architecture.dart';

/// Whenever a class that implements this interface is initialized within
/// [Services] dependency injection, the method [initialize] will run.
///
/// This happens once for singletons and everytime for transients.
abstract interface class IInitializable {
  void initialize();
}
