library simple_architecture;

import 'dart:async';
import 'dart:developer' as Dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:rxdart/rxdart.dart';

part 'src/application/base_state.dart';
part 'src/application/i_notification.dart';
part 'src/application/i_pipeline_behavior.dart';
part 'src/application/i_request.dart';
part 'src/application/mediator.dart';
part 'src/application/states.dart';
part 'src/exceptions/duplicated_element_exception.dart';
part 'src/exceptions/element_not_found_exception.dart';
part 'src/infrastructure/logger.dart';
part 'src/services/i_bootable.dart';
part 'src/services/i_initializable.dart';
part 'src/services/services.dart';
part 'src/settings/settings.dart';
part 'src/shared/cancellation_token.dart';
part 'src/shared/response.dart';

const $initializeAsync = SimpleArchitecture.initializeAsync;
final $settings = SimpleArchitecture.settings;
final $services = SimpleArchitecture.services;
final $mediator = SimpleArchitecture.mediator;
final $states = SimpleArchitecture.states;

final class SimpleArchitecture {
  // coverage:ignore-start
  const SimpleArchitecture._();
  // coverage:ignore-end

  static final settings = Settings._();
  static final services = Services._();
  static final mediator = Mediator._();
  static final states = States._();

  @visibleForTesting
  static void purgeAll() {
    _isInitialized = false;
    settings._purgeAll();
    services._purgeAll();
    mediator._purgeAll();
  }

  static bool _isInitialized = false;

  /// Initializes [Services], instantiating every [IBootable] singletons and
  /// initializing them as well. Also initializes [Mediator], instantiating
  /// every pipeline behavior registered as singleton.
  ///
  /// This function is safe to run multiple times, as [Services] will only be
  /// initialized once.
  ///
  /// After initialization, you can't register types anymore.
  static Future<void> initializeAsync() async {
    if (_isInitialized) {
      return;
    }

    const logger = Logger<SimpleArchitecture>();

    logger.config("Initializing");

    $mediator._initialize();
    _isInitialized = true;

    final bootables = <IBootable>[];

    for (final entry in $services._bootableFactories.entries) {
      final instance = $services._createSingletonInstance(
        entry.key,
        entry.value,
      ) as IBootable;

      bootables.add(instance);
    }

    for (final bootable in bootables) {
      logger.config("Booting ${bootable.runtimeType}");
      await bootable.initializeAsync();
    }
  }
}
