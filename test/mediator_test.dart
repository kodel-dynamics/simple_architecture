import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:simple_architecture/simple_architecture.dart';

void purgeAll() {
  SimpleArchitecture.purgeAll();
  TestRequestHandler.runCount = 0;
  InitializableTestRequestHandler.initializeCount = 0;
  InitializablePipelineBehavior.initializeCount = 0;
  InitializablePipelineBehavior.runCount = 0;
  Priority10PipelineBehavior.runCount = 0;
  Priority20PipelineBehavior.runCount = 0;
  CancelledPipelineBehavior.runCount = 0;
  CancelledWithErrorPipelineBehavior.runCount = 0;
  pipelineBehaviorPriorityOrder.clear();
}

void main() {
  setUp(purgeAll);

  test("Mediators should work as transient", () async {
    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
      registerAsTransient: true,
    );

    await SimpleArchitecture.initializeAsync();

    final response = await $mediator.send(const TestRequest());

    expect(response, true);
    expect(TestRequestHandler.runCount, 1);

    final response2 = await $mediator.send(const TestRequest());

    expect(response2, true);
    expect(TestRequestHandler.runCount, 2);
  });

  test("Mediators should work as singleton", () async {
    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
      registerAsTransient: false,
    );

    await SimpleArchitecture.initializeAsync();

    final response = await $mediator.send(const TestRequest());

    expect(response, true);
    expect(TestRequestHandler.runCount, 1);

    final response2 = await $mediator.send(const TestRequest());

    expect(response2, false);
    expect(TestRequestHandler.runCount, 2);
  });

  test("Pipeline behaviors as transient", () async {
    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
      registerAsTransient: true,
    );

    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: true,
    );

    $mediator.registerPipelineBehavior(
      20,
      (get) => Priority20PipelineBehavior(),
      registerAsTransient: true,
    );

    await SimpleArchitecture.initializeAsync();

    await $mediator.send(const TestRequest());

    expect(Priority10PipelineBehavior.runCount, 1);
    expect(Priority20PipelineBehavior.runCount, 1);
    expect(pipelineBehaviorPriorityOrder, [10, 20]);

    await $mediator.send(const TestRequest());

    expect(Priority10PipelineBehavior.runCount, 2);
    expect(Priority20PipelineBehavior.runCount, 2);
    expect(pipelineBehaviorPriorityOrder, [10, 20, 10, 20]);
  });

  test("Pipeline behaviors as singleton", () async {
    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
      registerAsTransient: false,
    );

    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerPipelineBehavior(
      20,
      (get) => Priority20PipelineBehavior(),
      registerAsTransient: false,
    );

    await SimpleArchitecture.initializeAsync();

    await $mediator.send(const TestRequest());

    expect(Priority10PipelineBehavior.runCount, 1);
    expect(Priority20PipelineBehavior.runCount, 1);
    expect(pipelineBehaviorPriorityOrder, [10, 20]);

    await $mediator.send(const TestRequest());

    expect(Priority10PipelineBehavior.runCount, 2);
    expect(Priority20PipelineBehavior.runCount, 2);
    expect(pipelineBehaviorPriorityOrder, [10, 20, 10, 20]);
  });

  test("Pipeline behaviors duplication as transient should thow", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: true,
    );

    expect(
      () => $mediator.registerPipelineBehavior(
        10,
        (get) => Priority20PipelineBehavior(),
        registerAsTransient: true,
      ),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Pipeline behaviors duplication t/s should throw", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: true,
    );

    expect(
      () => $mediator.registerPipelineBehavior(
        10,
        (get) => Priority20PipelineBehavior(),
        registerAsTransient: false,
      ),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Pipeline behaviors duplication t/t should throw", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: true,
    );

    expect(
      () => $mediator.registerPipelineBehavior(
        10,
        (get) => Priority20PipelineBehavior(),
        registerAsTransient: true,
      ),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Pipeline behaviors duplication s/t should throw", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: false,
    );

    expect(
      () => $mediator.registerPipelineBehavior(
        10,
        (get) => Priority20PipelineBehavior(),
        registerAsTransient: true,
      ),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Pipeline behaviors duplication s/s should throw", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: false,
    );

    expect(
      () => $mediator.registerPipelineBehavior(
        10,
        (get) => Priority20PipelineBehavior(),
        registerAsTransient: false,
      ),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Pipeline should short-circuit", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => CancelledPipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerPipelineBehavior(
      20,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
    );

    await SimpleArchitecture.initializeAsync();

    await $mediator.send(const TestRequest());

    expect(CancelledPipelineBehavior.runCount, 1);
    expect(Priority10PipelineBehavior.runCount, 0);
  });

  test("Pipeline should short-circuit with error", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => CancelledWithErrorPipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerPipelineBehavior(
      20,
      (get) => Priority10PipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerRequestHandler(
      (get) => TestRequestHandler(),
    );

    await SimpleArchitecture.initializeAsync();

    await $mediator.send(const TestRequest());

    expect(CancelledWithErrorPipelineBehavior.runCount, 1);
    expect(Priority10PipelineBehavior.runCount, 0);
  });

  test("Notifications should work without seed", () async {
    final lock1 = Completer<void>();
    final lock2 = Completer<void>();

    final subscription = $mediator.getChannel<TestNotification>().listen(
          expectAsync1(
            (notification) {
              expect(
                notification.value,
                inInclusiveRange(1, 2),
              );

              if (notification.value == 1) {
                lock1.complete();
              } else {
                lock2.complete();
              }
            },
            count: 2,
          ),
        );

    $mediator.publish(const TestNotification(value: 1));
    $mediator.publish(const TestNotification(value: 2));

    await Future.wait([lock1.future, lock2.future])
        .timeout(const Duration(milliseconds: 500));

    await subscription.cancel();
  });

  test("Notifications should work with seed", () async {
    $mediator.publish(const TestNotification(value: 1));

    final lock = Completer<void>();

    final subscription = $mediator.getChannel<TestNotification>().listen(
          expectAsync1(
            (notification) {
              expect(notification.value, 1);
              lock.complete();
            },
            count: 1,
          ),
        );

    await lock.future;

    await subscription.cancel();
  });

  test("Sync notifications listener should work", () async {
    final completer = Completer<int>();

    await $mediator.listenTo<TestNotification>(
      (notification) async => completer.complete(notification.value),
      () async {
        expect(completer.isCompleted, false);
        $mediator.publish(const TestNotification(value: 10));

        final value = await completer.future;

        expect(value, 10);
      },
    );
  });

  test("Transient IInitializable pipeline should work", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => InitializablePipelineBehavior(),
      registerAsTransient: true,
    );

    $mediator.registerRequestHandler(
      (get) => InitializableTestRequestHandler(),
      registerAsTransient: true,
    );

    await SimpleArchitecture.initializeAsync();
    await $mediator.send(const TestRequest());
    await $mediator.send(const TestRequest());

    expect(InitializablePipelineBehavior.initializeCount, 2);
  });

  test("Singleton IInitializable pipeline should work", () async {
    $mediator.registerPipelineBehavior(
      10,
      (get) => InitializablePipelineBehavior(),
      registerAsTransient: false,
    );

    $mediator.registerRequestHandler(
      (get) => InitializableTestRequestHandler(),
      registerAsTransient: true,
    );

    await SimpleArchitecture.initializeAsync();
    await $mediator.send(const TestRequest());
    await $mediator.send(const TestRequest());

    expect(InitializablePipelineBehavior.initializeCount, 1);
  });

  test("Transient IInitializable handler should work", () async {
    $mediator.registerRequestHandler(
      (get) => InitializableTestRequestHandler(),
      registerAsTransient: true,
    );

    await SimpleArchitecture.initializeAsync();
    await $mediator.send(const TestRequest());
    await $mediator.send(const TestRequest());

    expect(InitializableTestRequestHandler.initializeCount, 2);
  });

  test("Singleton IInitializable handler should work", () async {
    $mediator.registerRequestHandler(
      (get) => InitializableTestRequestHandler(),
      registerAsTransient: false,
    );

    await SimpleArchitecture.initializeAsync();
    await $mediator.send(const TestRequest());
    await $mediator.send(const TestRequest());

    expect(InitializableTestRequestHandler.initializeCount, 1);
  });
}

final class TestRequest implements IRequest<bool> {
  const TestRequest();
}

final class TestRequestHandler implements IRequestHandler<bool, TestRequest> {
  TestRequestHandler();

  static int runCount = 0;
  bool localValue = false;

  @override
  Future<bool> handle(TestRequest request) async {
    runCount++;

    return localValue = !localValue;
  }
}

final class InitializableTestRequestHandler extends TestRequestHandler
    implements IInitializable {
  InitializableTestRequestHandler();

  static int initializeCount = 0;

  @override
  void initialize() {
    initializeCount++;
  }
}

final class BootableTestRequestHandler extends TestRequestHandler
    implements IBootable {
  BootableTestRequestHandler();

  static int bootCount = 0;

  @override
  Future<void> initializeAsync() async {
    bootCount++;
  }
}

final List<int> pipelineBehaviorPriorityOrder = [];

final class CancelledWithErrorPipelineBehavior implements IPipelineBehavior {
  static int runCount = 0;

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) async {
    runCount++;

    cancellationToken.cancel(
      message: "Message",
      exception: UnsupportedError("Message"),
    );

    return false as TResponse;
  }
}

final class CancelledPipelineBehavior implements IPipelineBehavior {
  static int runCount = 0;

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) async {
    runCount++;

    cancellationToken.cancel();

    return false as TResponse;
  }
}

final class Priority10PipelineBehavior implements IPipelineBehavior {
  static int runCount = 0;

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) {
    runCount++;
    pipelineBehaviorPriorityOrder.add(10);

    return next(request);
  }
}

final class Priority20PipelineBehavior implements IPipelineBehavior {
  static int runCount = 0;

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) {
    runCount++;
    pipelineBehaviorPriorityOrder.add(20);

    return next(request);
  }
}

final class TestNotification implements INotification {
  const TestNotification({required this.value});

  final int value;

  @override
  String toString() {
    return "TestNotification($value)";
  }
}

final class InitializablePipelineBehavior
    implements IPipelineBehavior, IInitializable {
  static int runCount = 0;
  static int initializeCount = 0;

  @override
  void initialize() {
    initializeCount++;
  }

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) {
    runCount++;
    pipelineBehaviorPriorityOrder.add(10);

    return next(request);
  }
}

final class BootablePipelineBehavior implements IPipelineBehavior, IBootable {
  static int runCount = 0;
  static int bootCount = 0;

  @override
  Future<void> initializeAsync() async {
    bootCount++;
  }

  @override
  Future<TResponse> handle<TResponse, TRequest extends IRequest<TResponse>>(
    TRequest request,
    Future<TResponse> Function(TRequest request) next,
    CancellationToken cancellationToken,
  ) {
    runCount++;
    pipelineBehaviorPriorityOrder.add(10);

    return next(request);
  }
}
