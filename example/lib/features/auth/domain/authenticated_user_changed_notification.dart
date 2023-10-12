// Value equality is super useful for notifications (because Mediator is smart
// enough to not dispatch two notifications with the same value), so, as
// explained in [User], we're using dart_mappable here as well:
import 'package:dart_mappable/dart_mappable.dart';

import 'package:simple_architecture/simple_architecture.dart';

import 'user.dart';

part 'authenticated_user_changed_notification.mapper.dart';

/// This notification will be emitted by the authentication domain whenever
/// a user sign in, sign out or change his/her name or photo.
///
/// So all you need to do is to listen to it using a
/// [MediatorNotificationListener<AuthenticatedUserChangedNotification>] (see
/// `app.dart` on how to use this)
@MappableClass()
final class AuthenticatedUserChangedNotification
    with AuthenticatedUserChangedNotificationMappable
    implements INotification {
  const AuthenticatedUserChangedNotification({
    required this.user,
  });
  factory AuthenticatedUserChangedNotification.fromMap(
          Map<String, dynamic> map) =>
      AuthenticatedUserChangedNotificationMapper.fromMap(map);

  factory AuthenticatedUserChangedNotification.fromJson(String json) =>
      AuthenticatedUserChangedNotificationMapper.fromJson(json);

  final User? user;
}
