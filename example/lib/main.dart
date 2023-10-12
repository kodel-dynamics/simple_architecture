import 'package:flutter/material.dart';

import 'package:example/features/auth/domain/base_authentication_service.dart';

import 'package:simple_architecture/simple_architecture.dart';

import 'app.dart';
import 'features/auth/services/fake_authentication_service.dart';
import 'features/error_handling/domain/global_error_handler_pipeline_behavior.dart';
import 'features/error_handling/domain/i_global_error_handler_service.dart';
import 'features/error_handling/services/fake_global_error_handler_service.dart';

Future<void> main() async {
  // Register settings, services and mediators

  // This pipeline behavior will add a try/catch into every request made, so
  // it can be used, for example, as a Crashlytics/Sentry exception log.
  $.mediator.registerPipelineBehavior(
    // a 0 priority means that this will be the first behavior to run in the
    // pipeline (meaning that any other behavior and the actual request message
    // handling will occur inside this behavior, perfect for a global try/catch)
    0,
    (get) => GlobalErrorHandlerPipelineBehavior(
      // We need an instance of [IGlobalErrorHandlerService] here. That will
      // be registered in some other place and we don't need to worry with
      // anything (except that MUST be registered eventualy)
      globalErrorHandlerService: get<IGlobalErrorHandlerService>(),
    ),
    registerAsTransient: false,
  );

  // Whomever needs a [IGlobalErrorHandlerService], we give it an instance of
  // [FakeGlobalErrorHandlerService]
  $.services.registerSingleton<IGlobalErrorHandlerService>(
    (get) => const FakeGlobalErrorHandlerService(),
  );

  // Check [BaseAuthenticationService] for explanation why this class is
  // registered using `registerBootableSingleton`
  $.services.registerBootableSingleton<BaseAuthenticationService>(
    (get) => const FakeAuthenticationService(),
  );

  // Initialize
  await $.initializeAsync();

  // Run
  runApp(const App());
}
