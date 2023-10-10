part of '../../simple_architecture.dart';

/// Every singleton that implements this interface will be instantiated and
/// the method [initializeAsync] will run when [Services.initializeAsync] is
/// called (commonly on `main` method).
abstract interface class IBootable {
  Future<void> initializeAsync();
}
