library simple_architecture;

import 'dart:developer' as Dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

part 'src/shared/duplicated_element_exception.dart';
part 'src/shared/element_not_found_exception.dart';
part 'src/shared/logger.dart';
part 'src/shared/mediator.dart';
part 'src/shared/services.dart';
part 'src/shared/settings.dart';

final class $ {
  const $._();

  static final settings = Settings._();
  static final services = Services._();
  static final mediator = Mediator._();

  @visibleForTesting
  static void purgeAll() {
    settings._purgeAll();
    services._purgeAll();
    mediator._purgeAll();
  }
}
