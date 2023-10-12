// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element

part of 'authenticated_user_changed_notification.dart';

class AuthenticatedUserChangedNotificationMapper
    extends ClassMapperBase<AuthenticatedUserChangedNotification> {
  AuthenticatedUserChangedNotificationMapper._();

  static AuthenticatedUserChangedNotificationMapper? _instance;
  static AuthenticatedUserChangedNotificationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals
          .use(_instance = AuthenticatedUserChangedNotificationMapper._());
      UserMapper.ensureInitialized();
    }
    return _instance!;
  }

  static T _guard<T>(T Function(MapperContainer) fn) {
    ensureInitialized();
    return fn(MapperContainer.globals);
  }

  @override
  final String id = 'AuthenticatedUserChangedNotification';

  static User? _$user(AuthenticatedUserChangedNotification v) => v.user;
  static const Field<AuthenticatedUserChangedNotification, User> _f$user =
      Field('user', _$user);

  @override
  final Map<Symbol, Field<AuthenticatedUserChangedNotification, dynamic>>
      fields = const {
    #user: _f$user,
  };

  static AuthenticatedUserChangedNotification _instantiate(DecodingData data) {
    return AuthenticatedUserChangedNotification(user: data.dec(_f$user));
  }

  @override
  final Function instantiate = _instantiate;

  static AuthenticatedUserChangedNotification fromMap(
      Map<String, dynamic> map) {
    return _guard((c) => c.fromMap<AuthenticatedUserChangedNotification>(map));
  }

  static AuthenticatedUserChangedNotification fromJson(String json) {
    return _guard(
        (c) => c.fromJson<AuthenticatedUserChangedNotification>(json));
  }
}

mixin AuthenticatedUserChangedNotificationMappable {
  String toJson() {
    return AuthenticatedUserChangedNotificationMapper._guard(
        (c) => c.toJson(this as AuthenticatedUserChangedNotification));
  }

  Map<String, dynamic> toMap() {
    return AuthenticatedUserChangedNotificationMapper._guard(
        (c) => c.toMap(this as AuthenticatedUserChangedNotification));
  }

  AuthenticatedUserChangedNotificationCopyWith<
          AuthenticatedUserChangedNotification,
          AuthenticatedUserChangedNotification,
          AuthenticatedUserChangedNotification>
      get copyWith => _AuthenticatedUserChangedNotificationCopyWithImpl(
          this as AuthenticatedUserChangedNotification, $identity, $identity);
  @override
  String toString() {
    return AuthenticatedUserChangedNotificationMapper._guard(
        (c) => c.asString(this));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            AuthenticatedUserChangedNotificationMapper._guard(
                (c) => c.isEqual(this, other)));
  }

  @override
  int get hashCode {
    return AuthenticatedUserChangedNotificationMapper._guard(
        (c) => c.hash(this));
  }
}

extension AuthenticatedUserChangedNotificationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AuthenticatedUserChangedNotification, $Out> {
  AuthenticatedUserChangedNotificationCopyWith<$R,
          AuthenticatedUserChangedNotification, $Out>
      get $asAuthenticatedUserChangedNotification => $base.as((v, t, t2) =>
          _AuthenticatedUserChangedNotificationCopyWithImpl(v, t, t2));
}

abstract class AuthenticatedUserChangedNotificationCopyWith<
    $R,
    $In extends AuthenticatedUserChangedNotification,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  UserCopyWith<$R, User, User>? get user;
  $R call({User? user});
  AuthenticatedUserChangedNotificationCopyWith<$R2, $In, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AuthenticatedUserChangedNotificationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthenticatedUserChangedNotification, $Out>
    implements
        AuthenticatedUserChangedNotificationCopyWith<$R,
            AuthenticatedUserChangedNotification, $Out> {
  _AuthenticatedUserChangedNotificationCopyWithImpl(
      super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthenticatedUserChangedNotification> $mapper =
      AuthenticatedUserChangedNotificationMapper.ensureInitialized();
  @override
  UserCopyWith<$R, User, User>? get user =>
      $value.user?.copyWith.$chain((v) => call(user: v));
  @override
  $R call({Object? user = $none}) =>
      $apply(FieldCopyWithData({if (user != $none) #user: user}));
  @override
  AuthenticatedUserChangedNotification $make(CopyWithData data) =>
      AuthenticatedUserChangedNotification(
          user: data.get(#user, or: $value.user));

  @override
  AuthenticatedUserChangedNotificationCopyWith<$R2,
      AuthenticatedUserChangedNotification, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _AuthenticatedUserChangedNotificationCopyWithImpl($value, $cast, t);
}
