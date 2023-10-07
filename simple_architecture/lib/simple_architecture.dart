library simple_architecture;

import 'dart:developer' as Dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

part 'src/application/mediator.dart';
part 'src/exceptions/duplicated_element_exception.dart';
part 'src/exceptions/element_not_found_exception.dart';
part 'src/infrastructure/logger.dart';
part 'src/services/i_bootable.dart';
part 'src/services/i_initializable.dart';
part 'src/services/services.dart';
part 'src/settings/settings.dart';

final class $ {
  // coverage:ignore-start
  const $._();
  // coverage:ignore-end

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
