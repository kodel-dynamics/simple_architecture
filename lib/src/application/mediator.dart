// ignore_for_file: close_sinks

part of '../../simple_architecture.dart';

/// The [Mediator] allows registration of message handlers, so you can implement
/// all your app business logic as features, such as `AuthenticateUser`,
/// `CreateCustomer`, etc.
///
/// You must register all your handlers *before* [Services].[initializeAsync]
/// is called. All mediator handlers are dependency-injection-enabled.
final class Mediator {
  Mediator._();

  final _transientPipelines =
      <int, IPipelineBehavior Function(GetDelegate get)>{};

  final _singletonPipelines =
      <int, IPipelineBehavior Function(GetDelegate get)>{};

  final _pipeline =
      <(IPipelineBehavior Function() factory, bool isTransient)>[];

  final _pipelineInitialized = <bool>[];
  final _behaviorSubjects = <Type, BehaviorSubject<dynamic>>{};
  final _streams = <Type, Stream<dynamic>>{};
  final _logger = Logger<Mediator>();

  void _purgeAll() {
    _transientPipelines.clear();
    _singletonPipelines.clear();
    _pipeline.clear();
    _pipelineInitialized.clear();

    for (var value in _behaviorSubjects.values) {
      value.close();
    }

    _behaviorSubjects.clear();
    _streams.clear();
  }

  void _initialize() {
    _logger.config("Initializing");

    final priorities =
        _transientPipelines.keys.followedBy(_singletonPipelines.keys).toList();

    priorities.sort();

    for (final priority in priorities) {
      final singletonFactory = _singletonPipelines[priority];

      if (singletonFactory != null) {
        _logger.config("Instantiating singleton pipeline behavior #$priority");

        final instance = singletonFactory($services._get);

        _pipeline.add((() => instance, false));
      } else {
        final transientFactory = _transientPipelines[priority];

        _pipeline.add((() => transientFactory!($services._get), true));
      }

      _pipelineInitialized.add(false);
    }

    _logger.config(
      "${_pipeline.length} pipeline behavior${_pipeline.length > 1 ? "s" : ""} "
      "were registered",
    );
  }

  /// Register an [IRequest<TResponse>] handler that will be called whenever
  /// that kind of message is sent to the [Mediator].
  ///
  /// You can choose whether your handler is registered as a transient (when
  /// your request handler class hasn't state on it) or singleton (when your
  /// request handler class has global state on it).
  void registerRequestHandler<TResponse>(
    IRequestHandler<TResponse, IRequest<TResponse>> Function(GetDelegate get)
        handlerFactory, {
    bool registerAsTransient = true,
  }) {
    if (registerAsTransient) {
      _logger.config("Registering ${IRequest<TResponse>} as transient");

      $services
          .registerTransient<IRequestHandler<TResponse, IRequest<TResponse>>>(
        handlerFactory,
      );
    } else {
      _logger.config("Registering ${IRequest<TResponse>} as singleton");

      $services
          .registerSingleton<IRequestHandler<TResponse, IRequest<TResponse>>>(
        handlerFactory,
      );
    }
  }

  /// Register an [IPipelineBehavior] to intercept every request sent by this
  /// mediator.
  ///
  /// [priority] determines the priority of this pipeline behavior (and this
  /// priority must be unique. We recommend using values such as 10, 20, 30,
  /// etc. to allow inclusions on a later time).
  ///
  /// You can choose whether your handler is registered as a transient (when
  /// your request handler class hasn't state on it) or singleton (when your
  /// request handler class has global state on it).
  ///
  /// Throws:
  /// * [DuplicatedElementException] if there is already a pipeline behavior
  /// registered with the same [priority].
  void registerPipelineBehavior<TPipelineBehavior extends IPipelineBehavior>(
    int priority,
    TPipelineBehavior Function(GetDelegate get) handlerFactory, {
    bool registerAsTransient = true,
  }) {
    if (_transientPipelines.containsKey(priority)) {
      throw DuplicatedElementException(
        message: "There is already a pipeline registered as transient with "
            "priority $priority",
      );
    }

    if (_singletonPipelines.containsKey(priority)) {
      throw DuplicatedElementException(
        message: "There is already a pipeline registered as singleton with "
            "priority $priority",
      );
    }

    if (registerAsTransient) {
      _logger.config(
        "Registering $TPipelineBehavior as transient with priority $priority",
      );

      _transientPipelines[priority] = handlerFactory;
    } else {
      _logger.config(
        "Registering $TPipelineBehavior as singleton with priority $priority",
      );

      _singletonPipelines[priority] = handlerFactory;
    }
  }

  /// Creates or fetch a stream to listen to notifications of type
  /// [TNotification].
  Stream<TNotification> getChannel<TNotification extends INotification>() {
    _logger.debug(() => "Listening to $TNotification");

    final stream = _streams[TNotification];

    if (stream == null) {
      final subject = _getBehaviorSubject<TNotification>();

      return _streams[TNotification] = subject.stream;
    }

    return stream as Stream<TNotification>;
  }

  /// Listens to the stream of [TNotification] notifications while the closure
  /// is active, then drops the channel
  Future<void> listenTo<TNotification extends INotification>(
    Future<void> Function(TNotification notification) handler,
    Future<void> Function() closure,
  ) async {
    StreamSubscription<TNotification>? subscription;

    try {
      final subject = _getBehaviorSubject<TNotification>();
      final stream = subject.stream;

      subscription = stream.listen(handler);
      await closure();
    } finally {
      await subscription?.cancel();
    }
  }

  BehaviorSubject<TNotification>
      _getBehaviorSubject<TNotification extends INotification>([
    TNotification? seed,
  ]) {
    final subject = _behaviorSubjects[TNotification];

    if (subject == null) {
      return _behaviorSubjects[TNotification] = seed == null
          ? BehaviorSubject<TNotification>()
          : BehaviorSubject<TNotification>.seeded(seed);
    }

    return subject as BehaviorSubject<TNotification>;
  }

  /// Publishes a notification to be listened by the [listenTo<TNotification>]
  /// method.
  void publish<TNotification extends INotification>(
    TNotification notification,
  ) {
    _logger.info("Publishing $TNotification");
    _logger.debug(() => notification.toString());

    final bs = _getBehaviorSubject<TNotification>(notification);

    if (bs.valueOrNull == notification) {
      return;
    }

    bs.add(notification);
  }

  /// Send a message to a registered handler of type [TRequest].
  ///
  /// The appropriated [IRequestHandler<TRespone, TRequest>] will be called
  /// to handle this message.
  ///
  /// The pipeline will run in the order specify by priority (the lower, the
  /// sooner) and the rest of pipeline (and even the registered handler) can
  /// be skipped when [cancellationToken] is cancelled.
  Future<TResponse> send<TResponse>(
    IRequest<TResponse> request,
  ) async {
    _logger.info("Sending ${request.runtimeType}");
    _logger.debug(() => request.toString());

    final handler =
        $services.get<IRequestHandler<TResponse, IRequest<TResponse>>>();

    if (_pipeline.isEmpty) {
      return handler.handle(request);
    }

    final cancellationToken = CancellationToken(
      operationName: "Pipeline for ${IRequest<TResponse>}",
    );

    TResponse? currentResponse;

    Future<TResponse> runner(int index) async {
      if (cancellationToken.isCancelled && currentResponse != null) {
        return currentResponse as TResponse;
      }

      if (index == _pipeline.length) {
        return handler.handle(request);
      }

      final (pipeline, isTransient) = _pipeline[index];
      final pipelineHandler = pipeline();

      if (pipelineHandler is IInitializable) {
        if (isTransient) {
          (pipelineHandler as IInitializable).initialize();
        } else {
          if (_pipelineInitialized[index] == false) {
            (pipelineHandler as IInitializable).initialize();
            _pipelineInitialized[index] = true;
          }
        }
      }

      currentResponse = await pipelineHandler.handle(
        request,
        (_) => runner(index + 1),
        cancellationToken,
      );

      return currentResponse as TResponse;
    }

    return runner(0);
  }
}
