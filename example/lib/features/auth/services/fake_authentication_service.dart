import 'package:example/features/auth/domain/base_authentication_service.dart';
import 'package:example/features/auth/domain/user.dart';

import 'package:simple_architecture/simple_architecture.dart';

/// A fake authentication service.
final class FakeAuthenticationService extends BaseAuthenticationService {
  const FakeAuthenticationService();

  static User? _currentUser;

  static final _logger = Logger<FakeAuthenticationService>();

  @override
  Future<User?> loadCurrentUser() async {
    _logger.debug(() => "Loading current user: $_currentUser");

    return _currentUser;
  }
}
