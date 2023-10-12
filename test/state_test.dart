import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:simple_architecture/simple_architecture.dart';

void main() {
  setUp(() {
    SimpleArchitecture.purgeAll();
    TestState._persistedValue = 0;
  });

  test("States should be registered", () async {
    $states.registerState((get) => TestState());
    await $initializeAsync();

    final state = $states.get<TestState>();

    expect(state, isNotNull);
  });

  test("States should change", () async {
    $states.registerState((get) => TestState());
    await $initializeAsync();

    final state = $states.get<TestState>();

    expect(state.value, 0);
    state.change(1);
    expect(state.value, 1);
  });

  test("States should notify", () async {
    $states.registerState((get) => TestState());
    await $initializeAsync();

    final state = $states.get<TestState>();
    final completer = Completer<int>();

    state.addListener(() => completer.complete(state.value));
    state.change(1);

    expect(completer.isCompleted, true);

    final notifiedValue = await completer.future;

    expect(notifiedValue, 1);
  });

  test("States should persist", () async {
    $states.registerState((get) => TestState());
    await $initializeAsync();

    final state = $states.get<TestState>();

    state.change(1);
    expect(state.value, 1);
    expect(TestState._persistedValue, 1);

    SimpleArchitecture.purgeAll();

    $states.registerState((get) => TestState());
    await $initializeAsync();

    final hydratedState = $states.get<TestState>();

    expect(hydratedState.value, 1);
  });
}

final class TestState extends BaseState<int> {
  static int _persistedValue = 0;

  @override
  Future<int> load() async {
    return _persistedValue;
  }

  @override
  Future<void> save(int state) async {
    _persistedValue = state;
  }
}
