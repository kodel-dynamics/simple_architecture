import 'package:flutter_test/flutter_test.dart';

import 'package:simple_architecture/simple_architecture.dart';

void purgeAll() {
  $.purgeAll();
  Concrete._bootCount = 0;
  Concrete._initializationCount = 0;
  InitializableConcrete._bootCount = 0;
  InitializableConcrete._initializationCount = 0;
  BootableConcrete._bootCount = 0;
  BootableConcrete._initializationCount = 0;
}

void main() {
  test("Transient should be registered", () async {
    purgeAll();
    $.services.registerTransient<IAbstract>((get) => Concrete());

    await $.services.initializeAsync();

    final c = $.services.get<IAbstract>();

    expect(Concrete, c.runtimeType);
    expect(c.initializationCount, 0);
    expect(c.bootCount, 0);

    final c2 = $.services.get<IAbstract>();

    expect(identical(c, c2), false);
    purgeAll();
  });

  test("Singletons should be registered", () async {
    purgeAll();
    $.services.registerSingleton<IAbstract>((get) => Concrete());

    await $.services.initializeAsync();

    final c = $.services.get<IAbstract>();

    expect(Concrete, c.runtimeType);

    final c2 = $.services.get<IAbstract>();

    expect(identical(c, c2), true);
    purgeAll();
  });

  test("Duplicate registration should throw", () {
    purgeAll();
    $.services.registerSingleton<IAbstract>((get) => Concrete());

    expect(
      () => $.services.registerSingleton<IAbstract>((get) => Concrete()),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );

    expect(
      () => $.services.registerTransient<IAbstract>((get) => Concrete()),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );

    purgeAll();
    $.services.registerTransient<IAbstract>((get) => Concrete());

    expect(
      () => $.services.registerSingleton<IAbstract>((get) => Concrete()),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );

    expect(
      () => $.services.registerTransient<IAbstract>((get) => Concrete()),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Non existing registration should throw", () async {
    purgeAll();

    await $.services.initializeAsync();

    expect(
      () => $.services.get<IAbstract>(),
      throwsA(const TypeMatcher<ElementNotFoundException>()),
    );
  });

  test("Transient instances should initialize correctly", () async {
    purgeAll();
    $.services.registerTransient<IAbstract>((get) => Concrete());

    $.services.registerTransient<IInitializableAbstract>(
      (get) => InitializableConcrete(),
    );

    await $.services.initializeAsync();

    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().bootCount, 0);

    expect($.services.get<IInitializableAbstract>().initializationCount, 1);
    expect($.services.get<IInitializableAbstract>().initializationCount, 2);
    expect($.services.get<IInitializableAbstract>().bootCount, 0);
  });

  test("Singleton instances should initialize correctly", () async {
    purgeAll();
    $.services.registerSingleton<IAbstract>((get) => Concrete());

    $.services.registerSingleton<IInitializableAbstract>(
      (get) => InitializableConcrete(),
    );

    await $.services.initializeAsync();

    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().bootCount, 0);

    expect($.services.get<IInitializableAbstract>().initializationCount, 1);
    expect($.services.get<IInitializableAbstract>().initializationCount, 1);
    expect($.services.get<IInitializableAbstract>().bootCount, 0);
  });

  test("Singleton bootable should initialize correctly", () async {
    purgeAll();
    $.services.registerSingleton<IAbstract>((get) => Concrete());

    $.services.registerBootableSingleton<IBootableAbstract>(
      (get) => BootableConcrete(),
    );

    await $.services.initializeAsync();

    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().bootCount, 0);

    expect($.services.get<IBootableAbstract>().initializationCount, 0);
    expect($.services.get<IBootableAbstract>().initializationCount, 0);
    expect($.services.get<IBootableAbstract>().bootCount, 1);
    expect($.services.get<IBootableAbstract>().bootCount, 1);
  });

  test("Transient bootable should not boot", () async {
    purgeAll();
    $.services.registerTransient<IAbstract>((get) => Concrete());

    $.services.registerTransient<IBootableAbstract>(
      (get) => BootableConcrete(),
    );

    await $.services.initializeAsync();

    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().initializationCount, 0);
    expect($.services.get<IAbstract>().bootCount, 0);

    expect($.services.get<IBootableAbstract>().initializationCount, 0);
    expect($.services.get<IBootableAbstract>().initializationCount, 0);
    expect($.services.get<IBootableAbstract>().bootCount, 0);
    expect($.services.get<IBootableAbstract>().bootCount, 0);
  });

  test("Get should throw before initialization", () {
    purgeAll();

    expect(
      () => $.services.get<IAbstract>(),
      throwsA(const TypeMatcher<StateError>()),
    );
  });

  test("Register should throw after initialization", () async {
    purgeAll();

    await $.services.initializeAsync();

    expect(
      () => $.services.registerTransient<IAbstract>((get) => Concrete()),
      throwsA(const TypeMatcher<StateError>()),
    );
  });
}

abstract interface class IAbstract {
  int get initializationCount;
  int get bootCount;
}

final class Concrete implements IAbstract {
  static int _initializationCount = 0;

  @override
  int get initializationCount => _initializationCount;

  static int _bootCount = 0;

  @override
  int get bootCount => _bootCount;

  void initialize() {
    _initializationCount++;
  }

  Future<void> initializeAsync() async {
    _bootCount++;
  }
}

abstract interface class IInitializableAbstract
    implements IAbstract, IInitializable {}

final class InitializableConcrete implements IInitializableAbstract {
  static int _initializationCount = 0;

  @override
  int get initializationCount => _initializationCount;

  static int _bootCount = 0;

  @override
  int get bootCount => _bootCount;

  @override
  void initialize() {
    _initializationCount++;
  }

  Future<void> initializeAsync() async {
    _bootCount++;
  }
}

abstract interface class IBootableAbstract implements IAbstract, IBootable {}

final class BootableConcrete implements IBootableAbstract {
  static int _initializationCount = 0;

  @override
  int get initializationCount => _initializationCount;

  static int _bootCount = 0;

  @override
  int get bootCount => _bootCount;

  void initialize() {
    _initializationCount++;
  }

  @override
  Future<void> initializeAsync() async {
    _bootCount++;
  }
}
