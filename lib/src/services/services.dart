part of '../../simple_architecture.dart';

typedef GetDelegate = T Function<T>();
typedef _FactoryDelegate = dynamic Function(GetDelegate get);

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

  final _transientFactories = <Type, _FactoryDelegate>{};
  final _singletonFactories = <Type, _FactoryDelegate>{};
  final _bootableFactories = <Type, _FactoryDelegate>{};
  final _singletonInstances = <Type, dynamic>{};
  final _logger = Logger<Services>();

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
    TAbstract Function(GetDelegate get) delegate,
  ) {
    _logger.config("Registering $TAbstract transient");
    _registerIn(_transientFactories, delegate);
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
    TAbstract Function(GetDelegate get) delegate,
  ) {
    _logger.config("Registering $TAbstract singleton");
    _registerIn(_singletonFactories, delegate);
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
    TAbstract Function(GetDelegate get) delegate,
  ) {
    _logger.config("Registering $TAbstract bootable singleton");
    _registerIn(_bootableFactories, delegate);
  }

  void _registerIn<TAbstract>(
    Map<Type, _FactoryDelegate> where,
    TAbstract Function(GetDelegate get) delegate,
  ) {
    if (SimpleArchitecture._isInitialized) {
      throw StateError(
        "You cannot register new abstract classes when Services is already "
        "initialized",
      );
    }
    if (_transientFactories.containsKey(TAbstract)) {
      throw DuplicatedElementException(
        message: "There is already a transient of type $TAbstract registered",
      );
    }

    if (_singletonFactories.containsKey(TAbstract)) {
      throw DuplicatedElementException(
        message: "There is already a singleton of type $TAbstract registered",
      );
    }

    where[TAbstract] = delegate;
  }

  /// Gets an instance of the registered [TAbstract] class.
  ///
  /// If [TAbstract] extends [IInitializable], it will run once it is
  /// constructed (each time for transient, a single time for singletons).
  ///
  /// Throws:
  /// * [ElementNotFoundException] if [TAbstract] wasn't registered.
  /// * [StateError] if [Services] isn't initialized.
  TAbstract get<TAbstract>() {
    if (SimpleArchitecture._isInitialized == false) {
      throw StateError("You need to initialize Services before using get");
    }

    return _get<TAbstract>();
  }

  TAbstract _get<TAbstract>() {
    final singletonInstance = _singletonInstances[TAbstract];

    if (singletonInstance != null) {
      return singletonInstance as TAbstract;
    }

    final singletonFactory = _singletonFactories[TAbstract];

    if (singletonFactory != null) {
      return _createSingletonInstance(TAbstract, singletonFactory) as TAbstract;
    }

    final transientFactory = _transientFactories[TAbstract];

    if (transientFactory == null) {
      throw ElementNotFoundException(
        message: "There is no registered transient or singleton service "
            "of type $TAbstract",
      );
    }

    return _createInstance(TAbstract, transientFactory, true) as TAbstract;
  }

  dynamic _createInstance(
    Type abstractType,
    _FactoryDelegate factory,
    bool isTransient,
  ) {
    _logger.info("Instantiating $abstractType");

    final instance = factory(_get);
    final abstractTypeName = "$abstractType";
    final concreteTypeName = "${instance.runtimeType}";

    final typeName = abstractTypeName == concreteTypeName
        ? abstractTypeName
        : "$concreteTypeName as $abstractTypeName";

    final registryType = isTransient ? "transient" : "singleton";

    _logger.info(
      "${instance.runtimeType} instantiated as $abstractType $registryType",
    );

    if (instance is IInitializable) {
      _logger.info("Initializing $registryType $typeName");
      instance.initialize();
    }

    if (instance is IBootable && isTransient) {
      _logger.warning(
        "Boot of $registryType $typeName will be ignored "
        "because it is transient",
      );
    }

    return instance;
  }

  dynamic _createSingletonInstance(
    Type abstractType,
    _FactoryDelegate factory,
  ) {
    final instance = _createInstance(abstractType, factory, false);

    _singletonInstances[abstractType] = instance;

    return instance;
  }

  void _replaceSingletonInstance<TAbstract>(TAbstract instance) {
    _singletonInstances[TAbstract] = instance;
  }
}
