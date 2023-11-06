part of '../../simple_architecture.dart';

typedef GetDelegate = T Function<T>([String? key]);
typedef _FactoryDelegate = dynamic Function(GetDelegate get);

final class NamedType {
  const NamedType({required this.type, required this.key});

  final Type type;
  final String? key;

  String get mapKey => key == null ? type.toString() : "$type{$key}";

  @override
  String toString() => mapKey;

  @override
  bool operator ==(covariant NamedType other) {
    if (identical(this, other)) {
      return true;
    }

    return runtimeType == other.runtimeType && mapKey == other.mapKey;
  }

  @override
  int get hashCode {
    return mapKey.hashCode;
  }
}

/// Keeps a collection of all classes that can be located or injected as a
/// dependency. This also includes [Services] and [Mediator]'s handlers.
///
/// You can use this mechanics to register classes that will always have the
/// same instance returned (aka singleton) or classes that will be constructed
/// each time you request it (aka transient).
///
/// Every registration takes a [GetDelegate] so you can inject other
/// dependencies on those constructors.
final class Services {
  Services._();

  final _transientFactories = <NamedType, _FactoryDelegate>{};
  final _singletonFactories = <NamedType, _FactoryDelegate>{};
  final _bootableFactories = <NamedType, _FactoryDelegate>{};
  final _singletonInstances = <NamedType, dynamic>{};

  void _purgeAll() {
    _transientFactories.clear();
    _singletonFactories.clear();
    _bootableFactories.clear();
    _singletonInstances.clear();
  }

  /// Registers a factory that will build a new instance of [TAbstract] when
  /// requested, as a transient instance (each time someone asks for a
  /// [TAbstract], it will return a new instance using this [delegate]).
  ///
  /// You can decorate your class with [IInitializable] to automatically run
  /// `initialize` when the class is returned.
  ///
  /// Throws:
  /// * [DuplicatedElementException] in case [TAbstract] is already registered
  /// either as a singleton or transient.
  /// * [StateError] in case [Services] is already initialized (you can only
  /// register types before that)
  void registerTransient<TAbstract>(
    TAbstract Function(GetDelegate get) delegate, [
    String? key,
  ]) {
    final namedType = NamedType(type: TAbstract, key: key);

    logger.config("Registering $namedType transient");
    _registerIn(_transientFactories, namedType, delegate);
  }

  /// Registers a factory that will build a instance of [TAbstract] when
  /// requested, as a singleton instance (each time someone asks for a
  /// [TAbstract], it will return the same instance using this [delegate]).
  ///
  /// You can decorate your class with [IInitializable] to automatically run
  /// `initialize` when the class is created.
  ///
  /// Throws:
  /// * [DuplicatedElementException] in case [TAbstract] is already registered
  /// either as a singleton or transient.
  /// * [StateError] in case [Services] is already initialized (you can only
  /// register types before that)
  void registerSingleton<TAbstract>(
    TAbstract Function(GetDelegate get) delegate, [
    String? key,
  ]) {
    final namedType = NamedType(type: TAbstract, key: key);

    logger.config("Registering $namedType singleton");
    _registerIn(_singletonFactories, namedType, delegate);
  }

  /// This method also register a singleton factory, same as
  /// [registerSingleton], but those concrete instances must implement the
  /// [IBootable] interface. This interface makes every singleton to initialize
  /// and run the `initializeAsync` method when the [Services] mechanic is
  /// initialized in your `main` method.
  ///
  /// This is useful to initialize async stuff when your app starts, such as
  /// Firebase, databases, etc.
  ///
  /// Throws:
  /// * [DuplicatedElementException] in case [TAbstract] is already registered
  /// either as a singleton or transient.
  /// * [StateError] in case [Services] is already initialized (you can only
  /// register types before that)
  void registerBootableSingleton<TAbstract>(
    TAbstract Function(GetDelegate get) delegate, [
    String? key,
  ]) {
    final namedType = NamedType(type: TAbstract, key: key);

    logger.config("Registering $namedType bootable singleton");
    _registerIn(_bootableFactories, namedType, delegate);
  }

  void _registerIn<TAbstract>(
    Map<NamedType, _FactoryDelegate> where,
    NamedType namedType,
    TAbstract Function(GetDelegate get) delegate,
  ) {
    if (SimpleArchitecture._isInitialized) {
      throw StateError(
        "You cannot register new abstract classes when Services is already "
        "initialized",
      );
    }

    if (_transientFactories.containsKey(namedType)) {
      throw DuplicatedElementException(
        message: "There is already a transient of type $namedType registered",
      );
    }

    if (_singletonFactories.containsKey(namedType)) {
      throw DuplicatedElementException(
        message: "There is already a singleton of type $namedType registered",
      );
    }

    where[namedType] = delegate;
  }

  /// Gets an instance of the registered [TAbstract] class.
  ///
  /// If [TAbstract] extends [IInitializable], it will run once it is
  /// constructed (each time for transient, a single time for singletons).
  ///
  /// Throws:
  /// * [ElementNotFoundException] if [TAbstract] wasn't registered.
  /// * [StateError] if [Services] isn't initialized.
  TAbstract get<TAbstract>([String? key]) {
    if (SimpleArchitecture._isInitialized == false) {
      throw StateError("You need to initialize Services before using get");
    }

    return _get<TAbstract>(key);
  }

  TAbstract _get<TAbstract>([String? key]) {
    final namedType = NamedType(type: TAbstract, key: key);
    final singletonInstance = _singletonInstances[namedType];

    if (singletonInstance != null) {
      return singletonInstance as TAbstract;
    }

    final singletonFactory = _singletonFactories[namedType];

    if (singletonFactory != null) {
      return _createSingletonInstance(namedType, singletonFactory) as TAbstract;
    }

    final transientFactory = _transientFactories[namedType];

    if (transientFactory == null) {
      logger.error("$TAbstract not registered");

      throw ElementNotFoundException(
        message: "There is no registered transient or singleton service "
            "of type $TAbstract",
      );
    }

    return _createInstance(namedType, transientFactory, true) as TAbstract;
  }

  dynamic _createInstance(
    NamedType namedType,
    _FactoryDelegate factory,
    bool isTransient,
  ) {
    logger.debug(() => "Instantiating $namedType");

    final instance = factory(_get);
    final abstractTypeName = "${namedType.type}";
    final concreteTypeName = "${instance.runtimeType}";

    final typeName = abstractTypeName == concreteTypeName
        ? abstractTypeName
        : "$concreteTypeName as $abstractTypeName";

    final registryType = isTransient ? "transient" : "singleton";

    logger.debug(
      () => "${instance.runtimeType} instantiated as "
          "$namedType $registryType",
    );

    if (instance is IInitializable) {
      logger.debug(() => "Initializing $registryType $typeName");
      instance.initialize();
    }

    if (instance is IBootable && isTransient) {
      logger.warning(
        "Boot of $registryType $typeName will be ignored "
        "because it is transient",
      );
    }

    return instance;
  }

  dynamic _createSingletonInstance(
    NamedType namedType,
    _FactoryDelegate factory,
  ) {
    final instance = _createInstance(namedType, factory, false);

    _singletonInstances[namedType] = instance;

    return instance;
  }

  void _replaceSingletonInstance<TAbstract>(
    NamedType namedType,
    TAbstract instance,
  ) {
    _singletonInstances[namedType] = instance;
  }
}
