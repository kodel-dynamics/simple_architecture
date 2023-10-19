part of '../../simple_architecture.dart';

/// Manages all state management in your app. Register state holders (classes
/// extending [BaseState<TState>]) and use them as a [ValueNotifier<TState>],
/// with persistence and boot support.
final class States {
  States._();

  final _logger = const Logger<States>();

  /// Register a state manager as a bootable singleton.
  ///
  /// You can inject dependencies into your state and it will automatically
  /// call the `loadState` method when the app initializes.
  ///
  /// You can then use a `ValueListenableBuilder<TState>` on this state class
  /// to listen to state changes.
  void registerState<TState extends IState>(
    TState Function(GetDelegate get) stateFactory,
  ) {
    _logger.config("Registering state for $TState");
    $services.registerBootableSingleton(stateFactory);
  }

  /// Gets the current state of type [T].
  TState get<TState extends IState>() {
    return $services.get<TState>();
  }
}
