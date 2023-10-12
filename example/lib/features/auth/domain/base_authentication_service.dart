import 'package:flutter/foundation.dart';

import 'package:example/features/auth/domain/authenticated_user_changed_notification.dart';

import 'package:simple_architecture/simple_architecture.dart';

import 'user.dart';

/// Unless you call some domain method to emit a
/// [AuthenticatedUserChangedNotification], we need a [IBootable] service
/// that will check if there is an authenticated user at app's startup (for
/// example, by checking `FirebaseAuthentication.instance.currentUser`).
///
/// As we don't want to reimplement that in every authentication service
/// that we're building or can build in the future, we make this base class
/// for authentication as an abstract class, so that code isn't repeated
/// elsewhere.
abstract base class BaseAuthenticationService implements IBootable {
  const BaseAuthenticationService();

  static final _logger = Logger<BaseAuthenticationService>();

  /// This code will run at `$.initializeAsync` because this class implements
  /// [IBootable] **and** it is registered using
  /// `$.services.register`.
  @override
  Future<void> initializeAsync() async {
    _logger.config("Initializing");

    // We ask our concrete implementation if there is any authenticated user
    // (null means no)
    final currentUser = await loadCurrentUser();

    _logger.info(
      currentUser == null
          ? "No user is authenticated"
          : "Welcome back, ${currentUser.name}",
    );

    // Then we publish this notification (so, now we can listen to this
    // domain logic without need to call anything in advance - that's why the
    // [MediatorNotificationListener<AuthenticatedUserChangedNotification>] on
    // app.dart works.
    $.mediator.publish(AuthenticatedUserChangedNotification(user: currentUser));
  }

  /// Returns the current authenticated user, if any.
  @protected
  Future<User?> loadCurrentUser();
}
