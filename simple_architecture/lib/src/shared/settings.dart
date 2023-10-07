part of '../../simple_architecture.dart';

/// Keeps a collection of settings available for dependency injection or general
/// use.
///
/// You can use this mechanics to store any setting initialized at startup (for
/// instance: a Google Client Id for Google Sign In package).
///
/// Every setting registered here will also be registered as a singleton
/// dependency in the Services mechanics (so you can inject these settings on
/// services constructors (see [Services] for details))
final class Settings {
  Settings._();

  final _settings = <Type, dynamic>{};
  final _logger = Logger<Settings>();

  void _purgeAll() {
    _settings.clear();
  }

  /// Adds a setting in the [Settings] mechanics and register it as a singleton
  /// in the [Services] and [Mediator] dependency injector.
  ///
  /// Throws a [DuplicatedElementException] if [T] is already registered.
  void add<T>(T setting) {
    if (_settings.containsKey(T)) {
      throw DuplicatedElementException(
        message: "There is already a setting of type ${T} registered",
      );
    }

    _settings[T] = setting;
    // TODO: $.services.registerSingletonInstance(setting);
    _logger.config("Setting ${T} registered");
    _logger.debug(() => setting.toString());
  }

  /// Gets a registered setting of type [T].
  ///
  /// Throws an [ElementNotFoundException] if [T] isn't registered.
  T get<T>() {
    final setting = _settings[T];

    if (setting == null) {
      throw ElementNotFoundException(
        message: "There is no registered setting of type ${T}",
      );
    }

    return setting as T;
  }

  /// Replaces a previous registered setting of type [T]. This can be useful
  /// when using Firebase Remote Config and the remote config has changed.
  ///
  /// Throws an [ElementNotFoundException] if [T] isn't registered.
  void replace<T>(T setting) {
    if (_settings.containsKey(T) == false) {
      throw ElementNotFoundException(
        message: "There is no registered setting of type ${T}",
      );
    }

    _settings[T] = setting;
    // TODO:$.services._replaceSingletonInstance(setting);
    _logger.config("Setting ${T} replaced");
    _logger.debug(() => setting.toString());
  }
}
