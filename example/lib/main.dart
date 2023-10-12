import 'package:flutter/material.dart';

import 'package:simple_architecture/simple_architecture.dart';

Future<void> main() async {
  // Register state management
  $states.registerState((get) => CounterState());

  // Register mediator handler
  $mediator.registerRequestHandler(
    (get) => IncrementCounterRequestHandler(counterState: get<CounterState>()),
  );

  // Initialize
  await SimpleArchitecture.initializeAsync();

  // Run
  runApp(const _App());
}

final class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const _HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

final class _HomePage extends StatelessWidget {
  const _HomePage();

  void _incrementCounter() {
    $mediator.send(const IncrementCounterRequest());
  }

  @override
  Widget build(BuildContext context) {
    final state = $states.get<CounterState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Simple Architecture State/Mediator example"),
      ),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: state,
          builder: (context, state, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "You have pushed the button this many times:",
              ),
              Text(
                state.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: "Increment",
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Requests represents an action in the app...
final class IncrementCounterRequest implements IRequest<void> {
  const IncrementCounterRequest();
}

/// ...handled by a class specific for that message
final class IncrementCounterRequestHandler
    implements IRequestHandler<void, IncrementCounterRequest> {
  const IncrementCounterRequestHandler({required CounterState counterState})
      : _counterState = counterState;

  final CounterState _counterState;

  @override
  Future<void> handle(IncrementCounterRequest request) async {
    _counterState.increment();
  }
}

/// A state holds a value available for the lifetime of the app
final class CounterState extends BaseState<int> {
  CounterState();

  @override
  Future<int> load() async {
    // Not using state persistence, so we just create a default value
    return 0;
  }

  @override
  Future<void> save(int state) async {
    // Not using state persistence
  }

  /// A good practice is to create a method to describe what means to change
  /// this state.
  void increment() {
    change(value + 1);
  }
}
