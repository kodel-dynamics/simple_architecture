part of '../../simple_architecture.dart';

final _loggers = <Type, Logger<dynamic>>{};

/// Listens to notifications emitted by the Mediator and rebuild the
/// child widget using:
/// [waitingBuilder]: builder if there is no notification available (
/// it is optional and it defaults to `SizedBox.shrink()`)
/// [builder]: builder when a new notification is emitted
///
/// You can access the value of this notification with the
/// [NotificationContext<TNotification extends INotification>.of(context)]
/// inherited model (a specialized inherited widget).
final class MediatorNotificationListener<TNotification extends INotification>
    extends StatelessWidget {
  const MediatorNotificationListener({
    super.key,
    this.waitingBuilder,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
  )? waitingBuilder;

  final Widget Function(
    BuildContext context,
    TNotification notification,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final logger = _loggers[TNotification] ??
        (_loggers[TNotification] =
            Logger<MediatorNotificationListener<TNotification>>());

    logger.debug(() => "Rebuilding");

    return StreamBuilder<TNotification>(
      stream: $.mediator.listenTo<TNotification>(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error!;

          switch (error) {
            case FlutterError():
              logger.error(
                error.runtimeType.toString(),
                error,
                error.stackTrace,
              );

              return ErrorWidget.withDetails(error: error);
            case PlatformException():
              StackTrace? stackTrace;

              try {
                if (error.stacktrace != null) {
                  stackTrace = StackTrace.fromString(error.stacktrace!);
                }
              } catch (_) {}

              logger.error(
                error.message ?? error.runtimeType.toString(),
                error,
                stackTrace,
              );

              return ErrorWidget.withDetails(message: error.message ?? "");
            default:
              logger.error(
                error.runtimeType.toString(),
                error,
              );

              return ErrorWidget(snapshot.error!);
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          logger.debug(() => "Waiting for notification");

          if (waitingBuilder != null) {
            return waitingBuilder!(context);
          }

          return const SizedBox.shrink();
        }

        final notification = snapshot.data!;

        logger.info("Rebuilding child for notification");
        logger.debug(() => notification.toString());

        return NotificationContext<TNotification>(
          notification: notification,
          child: builder(context, notification),
        );
      },
    );
  }
}

/// Allows access to
final class NotificationContext<T extends INotification>
    extends InheritedModel<Type> {
  const NotificationContext({
    super.key,
    required super.child,
    required this.notification,
  });

  final T notification;

  static NotificationContext<TNotification>
      of<TNotification extends INotification>(BuildContext context) {
    final im = InheritedModel.inheritFrom<NotificationContext<TNotification>>(
      context,
      aspect: TNotification,
    );

    if (im == null) {
      throw ElementNotFoundException(
        message: "NotificationContext.of<$TNotification>() called with a "
            "context that does not contain a NotificationContext with this "
            "specific type.",
      );
    }

    return im;
  }

  @override
  bool updateShouldNotifyDependent(
    NotificationContext<T> oldWidget,
    Set<Type> dependencies,
  ) {
    final shouldNotify = dependencies.contains(T);

    if (kDebugMode) {
      final logger = _loggers[T] ??
          (_loggers[T] = Logger<MediatorNotificationListener<T>>());

      logger.debug(
        () =>
            "NotificationContext<$T>.updateShouldNotifyDependent = $shouldNotify",
      );
    }

    return shouldNotify;
  }

  @override
  bool updateShouldNotify(NotificationContext<T> oldWidget) {
    final shouldNotify = oldWidget.notification != notification;

    if (kDebugMode) {
      final logger = _loggers[T] ??
          (_loggers[T] = Logger<MediatorNotificationListener<T>>());

      logger.debug(
        () => "NotificationContext<$T>.updateShouldNotify = $shouldNotify",
      );
    }

    return shouldNotify;
  }
}
