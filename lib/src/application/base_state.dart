part of '../../simple_architecture.dart';

/// A non-generic decorator for any [BaseState<T>].
abstract interface class IState implements IBootable {}

/// A base class for state management. This class controls state by allowing
/// loading from some storage (or defining a new appropriated default state),
/// saving (persisting) a changed state, if needed, and changing it with
/// repeatable protection (as long as [TValue] implements value equality)
///
/// You can create concrete cases for this base case for each state or a generic
/// implementation with a specific persister, such as shared_preferences, hive,
/// isar, sqlite, etc.
///
/// This class is compatible with [ValueListenableBuilder<TValue>]
abstract base class BaseState<TValue> extends ChangeNotifier
    implements ValueListenable<TValue>, IBootable, IState {
  BaseState();

  final _logger = Logger<BaseState<TValue>>();

  TValue? _value;

  /// Gets the current value of this state.
  @override
  TValue get value => _value as TValue;

  /// Initializes this state by loading its initial value.
  ///
  /// You **must** call super at the beginning if you override this method.
  @override
  @mustCallSuper
  Future<void> initializeAsync() async {
    _logger.config("Initializing");
    _value = await load();
  }

  /// Loads the initial value of this state (either by creating a new default
  /// instance or by loading it from some storage)
  @protected
  Future<TValue> load();

  /// Saves this state to some storage for hydration the next time the app
  /// boots up.
  @protected
  Future<void> save(TValue state);

  void change(TValue newState) {
    if (newState == _value) {
      return;
    }

    _logger.info("State is changing");
    _logger.debug(() => toString());

    _value = newState;
    save(newState);
    notifyListeners();
  }

  // coverage:ignore-start
  @override
  String toString() => "${describeIdentity(this)}($_value)";
  // coverage:ignore-end
}
