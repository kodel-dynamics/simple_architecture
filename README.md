# A simple architecture for Flutter apps

https://pub.dev/packages/simple_architecture

https://github.com/kodel-dynamics/simple_architecture

![image](https://github.com/kodel-dynamics/simple_architecture/assets/379339/92ea94ad-d95c-4d34-87b1-6b86076c9cbf)

## Objectives

### Reusability

Certain parts of an application are common to multiple applications, such as authentication. What differs are only certain settings, such as `clientId` or `redirectUri` that are specific to each application. Therefore, there is no reason to write the same code for different applications.

It is necessary that common parts of an application are reusable in other applications with *no* changes and, at the same time, allow the parts that actually perform the service to be interchangeable, that is, if authentication is done with the `sign_in_with_apple packages ` and `firebase_auth` and, for any reason (such as a better package being built in the future, or a customer requirement needing to use Amazon Cognito or Auth0), these parts must be replaceable without any other part of the application or of reusable code is changed.

This is possible through the concept of repositories. Although the repository definition is specific to databases (https://martinfowler.com/eaaCatalog/repository.html), nothing prevents the same concept from being used for any operation that performs I/O, such as reading and writing files, remote calls via REST or GraphQL and access to third-party packages such as `firebase_auth`. So, any part of the system that communicates in any way to any external part of the system is done through a contract (interface) that specifies what that component does (for authentication, basically it is necessary to know the authenticated user, enter and leave one account). So the parts of the system that are interchangeable are just implementations of such interfaces and adaptations to the entities that the system understands (for example, there is a class that stores user information such as id, name, email and photo url (avatar )). The authentication interface asks for this class of representation of a user, so it is the implementation's job to turn what it considers a user into the entity that the application understands (i.e., it is the repository's job to convert what represents a user to it (e.g. .: `User` to `firebase_auth`) in the entity that the application understands.

This objective is met with two library features: services and dependency injection.

### Feature units

When we talk about S.O.L.I.D., the "S" refers to **single responsibility**. Unfortunately, "responsibility" is a very vague thing. Is authentication a single responsibility? Authentication typically has several components such as logging into an account, logging out of an account, checking the authenticated user if present, persisting the authenticated user, taking care of tokens, etc.

To make things extremely clear, it is necessary that such responsibilities are truly unique: instead of one big "authentication" responsibility, it is necessary to create a folder to group all the small features that make up an authentication system. Each feature being something to be implemented that does only that thing (that is, in an application that has an authentication system, we have *features* such as *sign in*, *log out*, *change user name*, *change user photo *, etc. These are distinct features that do not interfere with other features and, ideally, can be implemented at different times (i.e.: I don't need to complete *sign in* to *change user name* and vice versa).

This objective is achieved with a granulation of *features* through organized folders and files, an event system to specify what is desired (e.g.: `SignInUser(AuthProvider.google)`) to request to sign in with a user, using the Google for this, or `ChangeUserName(user.id, newName)` to request a user's name change and a mediator to understand and implement such events. This mediator has access to the same dependency injection system used in services, so it becomes a simple cake recipe on how to implement such a *feature*, using external services to guarantee this (i.e., at this point, there are only rules business, no knowledge of external services, such as Firebase Auth, and injectable dependencies, so that such an implementation can be easily tested).

### Settings

When parts of the system are reusable, generally what differs in use are configurations. For example, in an authentication system, we have certain settings such as *Google Client Id*, *Apple Service Id*, *Apple Redirect Uri*, etc.

While such settings can be injected into dependencies via parameters (during dependency registration), we can often have variable settings (e.g. a preference saved in `shared_preferences` or mutable settings via Firebase Remote Config.

This objective is achieved with a dependency injection system for classes that store configurations and that have mechanisms for updating these configurations in the dependency injector.

### State

There is a lot of discussion about state management in Flutter. Huge (and extremely complex) frameworks are built around this, like BLoC and Riverpod. The problem is that state is something simple: you don't even need a framework for state management in Flutter, as the library provides countless ways to maintain global and local states without needing external packages, such as `InheritedWidget`, `InheritedModel`, ` ChangeNotifier`, `ValueNotifier<T>` and `Stream<T>`. For example, in Firebase Auth, there is a `Stream<User?>` that fires during startup and whenever a user signs in or out. Any part of the system that depends on a user being authenticated or that displays information about that user (such as, for example, their photo) only needs to listen to the changes written to this stream, with a `StreamBuilder`. And states are that simple. Nothing more advanced is necessary in the vast majority of cases.

This goal is accomplished with a simple state management system based on `ValueNotifier<T>` (usable in the UI with a `ValueListenableBuilder<T>(valueListenable: $state.get<AuthState>(), builder: (context, authenticatedUser) => authenticatedUser == null ? LoginPage() : HomePage())`). Because the state manager participates in the dependency injection system, it can have dependencies injected and can be injected into other services.

To ensure that a state has a valid value during app initialization, these states must be initialized during app initialization and their initial values must be loaded. To fulfill this requirement, the state manager has `load` and `save` methods, where `load` loads a state (which can be a fixed default value or a value read from a local database, e.g. to maintain the state the app had during the last run) and `save` which can be implemented (or ignored) to save the current state of the application so that it returns to the same previous state when restarted. Additionally, a `change` method is used to change the state that the manager has (thus triggering the necessary events for the `ValueListenableBuiler<T>` to generate a rebuild, in case the state is different from the previous one.

### Overseers

Many times, we need to see or take care of certain things that our services cannot do (or should not do, due to the single responsibility principle, or because it is cumbersome to add monitoring to every existing call or *feature*, thus creating duplication of code).

Things that would be interesting to implement: central exception management, where every exception is shown, both locally and remotely (with services like Sentry or Firebase Crashlytics). A system that allows you to measure how long each *feature* of the system takes to execute, to check for bottlenecks or even anomalies, perhaps with remote services, such as Firebase Performance. Audit logs, to know exactly what was called, what the inputs and outputs were for that call, etc.

To accomplish this goal, there are classes called `PipelineBehavior` that intercept each system call to add such features. Each pipeline has a priority number (from 0 to infinity, with 0 running first). Then we can create pipelines that encapsulate all service calls in a `try/catch` and, if an exception occurs, send it, for example, to Firebase Crashlytics. Similarly, a pipeline with very high priority (say 1000), running immediately before the *handler* of the call actually has a time meter using `Stopwatch`.

### S.O.L.I.D.

The S.O.L.I.D. principles They are very common in projects written by more senior and experienced people. Although not every aspect of each part of this principle makes sense today, some are extremely indispensable:

1) **S**: *Single responsibility*: As described above, each written business rule must take care of one and only one responsibility. The more granular you are, the more classes there are, but the easier it is to find and fix problems. The less granular, the more responsibilities a module will have and the greater chance of problems, although fewer classes will exist. The final amount of useful code (that implements the solution to the problem) does not differ by grain.
2) **O**: *Open-Closed principle*: Basically, a system must be open to modifications (e.g.: implementing Auth0 instead of Firebase Auth) without anything else in the system changing. For nothing else in the system to change, the *features* need to be closed (*closed*). In this library, we use the *Polymorphic open-closed principle* which is nothing more than the freedom (*open*) to implement things as you wish, but have a fixed contract so that the application does not need to change to accommodate such changes (*closed*) through interfaces injected into business rules.
3) **L**: *Liskov substitution principle*: Basically it says that a class can be replaced by another class that is part of its inheritance chain without the system breaking as a result. This principle is used in the example of authentication due to a limitation of the dependency system: we have a part of the authentication system that is OAuth authentication with an external provider (Google, Facebook, Apple, etc.). Each provider has to be registered, but we cannot have an interface for both (as the dependency injector registers an interface type for each implementation). Therefore, we need to create an interface of type `IOAuthService` and two interfaces that inherit it such as `IGoogleOAuthService` and `IAppleOAuthService`. All of these interfaces can be interchanged without anything breaking, as they will not add or remove features (at least in terms of whoever uses them: the library). This represents exactly the same as covariance in Dart, most commonly implemented in `InheritedWidgets`, where the method that must be overridden `updateShouldNotify` comes with a covariance (i.e.: the new type you are creating can - and should - be replaced in this *override* and nothing will break so: `bool updateShouldNotify(covariant InheritedWidget oldWidget)`.
4) **I**: *Interface segregation principle*: This principle is about breaking down certain functionalities that certain classes have in a granular way: instead of a large contract that specifies several functionalities that may not even be usable by a target, segregation breaks such functionalities into smaller parts. For example, in services, we have purely decorative interfaces that follow this principle, such as `IInitializable` which requires the implementation of `void initialize()` and `IBootable` which requires the implementation of `Future<void> initializeAsync()` in parts distinct from the system (the first is executed every time an injected class is instantiated, the second is specific to *singletons* and is executed during the library initialization process). An example of not following this principle would be to place both initialization methods in the same interface, causing the classes that implement them to ignore such decorations by implementing empty methods (that is, if you have an empty method in a class just because one interface requires this, this interface is not following the interface segregation principle).
5) **D**: *Dependency inversion principle*: This principle is what allows you to write modular code, meaning that the common parts (logic) can be shared and written only once and the implementation details are free to be implemented differently for each project or even be changed in the same project without compromising functionality or rewriting. Dependency injection is used in all aspects of this library.

### Y.A.G.N.I.

*You ain't gonna need it* is a principle that says that you shouldn't implement something (or leave tips to implement in the future) of something that you won't use at the moment. This requirement is met with granular *features* that implement little and are independent, so that it is not necessary to implement other parts just for the sake of implementing or leaving future implementation tips in a *feature*.

### D.R.Y.

*Don't Repeat Yourself* is a principle that says that you should not repeat a single line of code to implement more than one functionality. This requirement is met with *pipeline behaviors* to implement features used at multiple points once (as opposed to, for example, adding error handling to each of the *features* separately). What if one is forgotten? What if you want to add functionality like reporting an error to Firebase Crashlytics? If more than one point in the code must be changed to accomplish this objective, then the code is not D.R.Y.

### Exceptions as flow control

Exceptions are almost always used as flow control, rather than representing an error from which we cannot recover. For example, the `sign_in_with_apple` package generates an exception of type `SignInWithAppleAuthorizationException` with the code `AuthorizationErrorCode.canceled` when the user cancels the authentication flow. This is not a good thing as this is not a mistake. The program flow is interrupted and transferred to a `catch` clause or, worse, if no `catch` is in the context, the application simply stops working, just because the user gave up signing in with an Apple account!

In Flutter, there is an additional problem in using exceptions when we are working with Flutter Web: certain exceptions, such as `SocketException` are present in a module that we should not import in this environment (`dart:io`). Making our reusable code depend on extra checks whether we are in web mode or not can become quite laborious.

Additionally, there are exceptions that represent the same error, but are triggered by different exceptions: for example, when there is no internet available and we try to access something remote, we may receive a `SocketException`, a `DioException` if we are using `dio` or, in the case of authentication, a `FirebaseAuthException` or even a `PlatformException`. It all boils down to the same failure: `networkRequestFailed` and it should be easier to deal with this in the UI: instead of handling 4 different types of exceptions (and others in the future when more functionality is implemented), services could just return a " result loader", i.e., a class that contains a success state, with the value returned by the service (e.g., the authenticated user), or a failure state, which contains only a description of the failure (e.g., a `SignInFailure` enum which contains all problems that may occur during authentication and an `unknown` for anything else unexpected). So, in our UI (or at any other point), we don't depend on classes and exceptions, but a simple enum (which is very interesting because Dart warns us when we try to use an enum in a `switch` and we don't cover all the possibilities existing).

To do this, we can use a class like `Result<TValue, TFailure extends Enum>()` with the constructors `Result.success(TValue value)` and `Result.failure(TFailure failure, [Object? exception, StackTrace? stackTrace ])`.

## A practical example

As an example, we will implement a complete authentication system, using this library and all existing concepts.

## Specification

* Authentication will be done exclusively through OAuth using Google or Apple (as everyone who has a cell phone must have a Google (Android) or Apple (iOS) account). Apple authentication should work on Android and vice versa (if the user had an iPhone at the time of first use and in the future decided to exchange the device for an Android or vice versa).
* At the moment, the packages chosen for authentication are `sign_in_with_apple`, `google_sign_in` and `firebase_auth`, but we want these packages to be implemented as *plugins*, that is, if one day `sign_in_with_apple` is discontinued or another better package is released, we can make the change without having to change absolutely anything in the system.
* Business rules must be reusable for other applications written in the future.
* Authentication must be persisted in a local database, storing the date/time the user entered the application, as well as the data that was used (such as user ID and authentication method).
* As authentication can take a long time, the UI must report each stage of it (waiting for OAuth provider, waiting for Firebase, waiting for database, etc.)

## Project structure

![image](https://github.com/kodel-dynamics/simple_architecture/assets/379339/c6c83ee5-b585-4f5e-928d-883186fde411)

The `features` folder will contain all the features of our system (currently, we only have the *feature* **AUTH**).

Within each feature, we have:

* Domain - Everything that is in the application domain, that is, business rules, entities, etc. These parties have no knowledge of anything (other than contracts), do not generate I/O (i.e., do not create records in databases, do not call remote services, etc., all being implemented through contracts so that these I/O S are testable and do not generate *side-effects* (side effects - changing the physical state of an application by writing to a database, calling a web service, etc.). In this example, we have two entities: ` AuthServiceCredential` which contains the result of an OAuth authentication (containing user data, access token and id token) and `Principal`, which represents an authenticated user. We have a notification `SignInAuthStageNotification` which will emit the current state of an authentication (i.e.: waiting for google, waiting for firebase, waiting for local database, etc.) Additionally, we have two initial *features*: `SignIn` and `SignOut`.
* Infrastructure - All service contracts that must be implemented. Here we have contracts for the OAuth service (authentication via Google or Apple), the authentication service (Firebase Auth) and our repository to store information (database to record logins). There is no defined rule whether such contracts are interfaces (`abstract interface class`) or abstract classes (`abstract base class`). Interfaces just say that such methods or fields should be implemented. It only has the signature of such methods and absolutely no other code (not even constructors). There are cases, however, where certain features are standard for any implementation (for example, if we implemented authentication via email, it would be interesting to validate that email, so we could have a base authentication contract (`BaseAuthService`) that would implement this validation and then call an abstract method (no-code, signature-only method, just like interfaces).The D.R.Y. principle is more important than rules at this point.
* Presentation - Here is everything related to Flutter: login-specific components (such as widgets that draw the Google or Apple logo to add to buttons), the authentication page itself, etc.
* Settings: As the chosen packages have settings, we created a class that maintains these settings for access.
* States: Finally, a state manager that maintains the current user or `null` if no user is authenticated.

Additionally, we have a more generic feature for monitoring errors and performance, through pipeline behaviors.

In the `infrastructure` folder outside of `features` we have the actual implementation of the contracts we need (which are login implementation with `google_sign_in`, `sign_in_with_apple` and `firebase_auth`, in addition to our login registration repository with package `isar`).

Everything under `features` can be safely copied and pasted into other projects.

Everything under `infrastructure` can be copied and pasted, if the implementation is the same (i.e. if other projects also use Firebase Auth, etc.).

## Initialization

The app launch will look like this:

```dart
Future<void> main() async {
  _registerSettings();
  _registerServices();
  _registerStates();
  _registerHandlers();
  _registerPipelines();
  await $initializeAsync();
  runApp(const App());
}

void _registerSettings() {
  $settings.add(
    AuthSettings(
      googleClientId: DefaultFirebaseOptions.ios.androidClientId!,
      appleServiceId: "TODO:",
      appleRedirectUri: Uri.parse("https://somewhere"),
      isGame: true,
    ),
  );
}

void _registerServices() {
  $services.registerBootableSingleton(
    (get) => const FirebaseApp(),
  );

  $services.registerTransient<IAuthService>(
    (get) => const FirebaseAuthService(),
  );

  $services.registerTransient<IAuthRepository>(
    (get) => const IsarAuthRepository(),
  );

  $services.registerTransient<IGoogleOAuthService>(
    (get) => GoogleSignInService(authSettings: get<AuthSettings>()),
  );

  $services.registerTransient<IAppleOAuthService>(
    (get) => AppleSignInService(authSettings: get<AuthSettings>()),
  );
}

void _registerStates() {
  $states.registerState(
    (get) => AuthState(authService: get<IAuthService>()),
  );
}

void _registerHandlers() {
  $mediator.registerRequestHandler(
    (get) => SignInRequestHandler(
      authService: get<IAuthService>(),
      googleOAuthService: get<IGoogleOAuthService>(),
      appleOAuthService: get<IAppleOAuthService>(),
      authRepository: get<IAuthRepository>(),
    ),
  );

  $mediator.registerRequestHandler(
    (get) => SignOutRequestHandler(
      authService: get<IAuthService>(),
      googleOAuthService: get<IGoogleOAuthService>(),
      appleOAuthService: get<IAppleOAuthService>(),
      authRepository: get<IAuthRepository>(),
    ),
  );
}

void _registerPipelines() {
  $mediator.registerPipelineBehavior(
    0,
    (get) => const ErrorMonitoringPipelineBehavior(),
    registerAsTransient: false,
  );

  $mediator.registerPipelineBehavior(
    1000,
    (get) => const PerformancePipelineBehavior(),
  );
}
```

This code adds the authentication settings that are specific to each project (the GoogleClientId is obtained from the file generated by the Firebase CLI, the AppleServiceId is obtained from the settings generated on the website where we configure login via Apple (developer.apple.com) and the AppleRedirectUri Specifies the Uri that OAuth authentication uses to complete authentication.

Afterwards, the services are registered:

* There is a special service called `FirebaseApp` registered as `IBootable` that is only used to start Firebase (all Firebase packages need this initialization, so adding it as an `IBootable` causes it to be initialized at the beginning, before any other service is called).
* We register our implementations linked to each necessary contract, that is, every time we need an `IAuthService`, a `FirebaseAuthService` will be returned. Note that some services may require other registered classes, for example, we must pass an `AuthSettings` to `GoogleSignInService`. By doing this via dependency injection, we guarantee that these values are defined in just one place.
* We then register our state manager for authentication, `AuthState`
* For each *feature*, there is a message (`SignInRequest` and `SignOutRequest`). These messages are received and implemented by a *handler*, which is a class of pure business rules that will orchestrate (or apply a cake recipe) exactly how a *sign in* or a *sign out* is done. To do this, we register two `RequestHandlers`, one for each message.
* Finally, we registered two pipeline behaviors to send all unhandled exceptions to Firebase Crashlytics and one to measure how long each *request* takes to complete.

## Sign In

This is the complete code for the *feature* *sign in*:

```dart
@MappableEnum()
enum SignInFailure {
  unknown,
  cancelledByUser,
  userDisabled,
  networkRequestFailed,
  notSupported,
}

typedef SignInResponse = Response<Principal?, SignInFailure>;

final class SignInRequest implements IRequest<SignInResponse> {
  const SignInRequest(this.authProvider);

  final AuthProvider authProvider;
}

final class SignInRequestHandler
    implements IRequestHandler<SignInResponse, SignInRequest> {
  const SignInRequestHandler({
    required IAuthService authService,
    required IGoogleOAuthService googleOAuthService,
    required IAppleOAuthService appleOAuthService,
    required IAuthRepository authRepository,
  })  : _authService = authService,
        _googleOAuthService = googleOAuthService,
        _appleOAuthService = appleOAuthService,
        _authRepository = authRepository;

  final IAuthService _authService;
  final IGoogleOAuthService _googleOAuthService;
  final IAppleOAuthService _appleOAuthService;
  final IAuthRepository _authRepository;

  static const _logger = Logger<SignInRequestHandler>();

  @override
  Future<SignInResponse> handle(SignInRequest request) async {
    final IOAuthService oAuthService =
        request.authProvider == AuthProvider.apple
            ? _appleOAuthService
            : _googleOAuthService;

    $mediator.publish(
      SignInAuthStageNotification(
        request.authProvider == AuthProvider.apple
            ? AuthStage.signingInWithApple
            : AuthStage.signingInWithGoogle,
      ),
    );

    _logger.info("Signing in with ${request.authProvider}");

    final oAuthResponse = await oAuthService.signIn();

    if (oAuthResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return SignInResponse.fromFailure(oAuthResponse);
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.authorizing),
    );

    _logger.info("Authorizing");

    final authResponse = await _authService.signIn(oAuthResponse.value);

    if (authResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return authResponse;
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.registering),
    );

    _logger.info("Persisting");

    final repoResponse = await _authRepository.signIn(authResponse.value!);

    if (repoResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return repoResponse;
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.idle),
    );

    Future<void>.delayed(const Duration(milliseconds: 500))
        .then(
          (_) => $mediator.publish(
            const SignInAuthStageNotification(AuthStage.idle),
          ),
        )
        .ignore();

    if (repoResponse.isSuccess) {
      $states.get<AuthState>().change(repoResponse.value);
    }

    return repoResponse;
  }
}
```

First, we implement equality by value for events, requests, entities, etc. using the great `dart_mappable` library. This is necessary to avoid rebuilds in our interface or triggering services when nothing has changed. Dart makes a comparison by reference, that is, one object is only equal to another if they point to the same object in memory. When we use immutability, we always generate a copy of an object, with possible changes. This copy, for Dart, is always different from the first (even if the values are the same). `dart_mappable` then implements value comparison (i.e., compares each field within a class to verify that they represent exactly the same entity). We use `dart_mappable` because it doesn't influence what you can do with your class (`freezed` for example prevents or hinders certain features like inheritance, generics, methods, etc.) and it also implements several other useful features, like `copyWith` and serialization (`toMap` and `toJson`).

Using the principles described in Vertical Slice Architecture (https://www.jimmybogard.com/vertical-slice-architecture/), we try to keep everything related to a *feature* within the same file (only separating implementations that cannot be copied and glued securely to other projects or entities that are generally used without needing everything else). So our file contains:

1) A `SignInFailure` enum that represents the possible errors that can occur during a sign in.
2) A `Request` that represents the desire to sign in (the UI will trigger this Request, informing whether you want to authenticate via Google or Apple, and everything will be done "automatically").
3) A handler for this request, which will implement the sign in logic per se. This logic emits events of type `SignInAuthStageNotification` so that the UI can show what is happening and then tries to authenticate with the specified provider (Google or Apple), which will emit an error or a credential (containing user data and access tokens ). If successful, this will be sent to Firebase Auth to generate a truly authenticated user. Finally, we send this almost ready-made user to the repository, so that we can write information about the user and the login made to the database.

Note that some things are still missing, such as reporting this login to Firebase Analytics, correcting the fact that signing in with Apple only sends the user name on the first authentication (our logic must consider this provider limitation and adjust the authenticated user accordingly , as a business rule).

But, basically, we have here all the requirements that we defined, such as reusability, granularity of *features*, testability, etc. and we can add or remove features very simply without even having to change the parts that are already ready. For example, to implement login logging in Firebase Analytics, we can simply write an `IBootable` service that registers itself as an `listener` of the authentication state (`AuthState`) and, when it occurs, does what it needs to do (which is basically calling a method saying that the user with ID *X* has authenticated). We can, additionally, emit a specific event at the end of the authentication process (such as `UserHasSignedIn(Principal)`), so any module that may be written in the future can listen to this event and do what it wants, without the rest of the application have this knowledge.

The possibilities and freedoms of implementation are open.

### Implementations

Some extra details on implementations or usage:

`google_sign_in_service`

```dart
final class GoogleSignInService implements IGoogleOAuthService {
  const GoogleSignInService({
    required AuthSettings authSettings,
  }) : _authSettings = authSettings;

  final AuthSettings _authSettings;

  static GoogleSignIn? __googleSignIn;

  GoogleSignIn get _googleSignIn => __googleSignIn ??= GoogleSignIn(
        clientId: kIsWeb || Platform.isAndroid == false
            ? _authSettings.googleClientId
            : null,
        hostedDomain: kIsWeb || Platform.isAndroid == false
            ? _authSettings.googleClientUrl
            : null,
        scopes: ["email"],
        signInOption:
            _authSettings.isGame ? SignInOption.games : SignInOption.standard,
      );

  @override
  Future<AuthServiceCredentialResponse> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        return const AuthServiceCredentialResponse.failure(
          SignInFailure.cancelledByUser,
        );
      }

      final auth = await account.authentication;

      return AuthServiceCredentialResponse.success(
        AuthServiceCredential(
          accessToken: auth.accessToken ?? "",
          idToken: auth.idToken ?? "",
          userName: account.displayName,
          userEmail: account.email,
          userAvatarUrl: account.photoUrl,
          authProvider: AuthProvider.google,
        ),
      );
    } catch (ex, stackTrace) {
      return AuthServiceCredentialResponse.failure(
        SignInFailure.unknown,
        ex,
        stackTrace,
      );
    }
  }

  @override
  Future<SignOutResponse> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }

    return const SignOutResponse.success(null);
  }
}
```

`firebase_auth_service.dart`:

```dart
final class FirebaseAuthService implements IAuthService {
  const FirebaseAuthService();

  static const _logger = Logger<FirebaseAuthService>();

  @override
  Future<SignInResponse> getCurrentPrincipal() async {
    final cu = FirebaseAuth.instance.currentUser;

    if (cu == null) {
      _logger.debug(() => "No user authenticated");
      return const SignInResponse.success(null);
    }

    AuthProvider? authProvider;

    for (final data in cu.providerData) {
      if (data.providerId == AppleAuthProvider.PROVIDER_ID) {
        authProvider = AuthProvider.apple;
        break;
      }

      if (data.providerId == GoogleAuthProvider.PROVIDER_ID) {
        authProvider = AuthProvider.google;
        break;
      }
    }

    assert(authProvider != null, "AuthProvider should have a value");

    final principal = Principal.normalize(
      id: cu.uid,
      name: cu.displayName,
      avatarUrl: cu.photoURL,
      email: cu.email,
      authProvider: authProvider!,
    );

    _logger.debug(() => "Authenticated user: ${principal}");

    return SignInResponse.success(principal);
  }

  @override
  Future<SignInResponse> signIn(
    AuthServiceCredential authServiceCredential,
  ) async {
    try {
      final credential =
          authServiceCredential.authProvider == AuthProvider.apple
              ? AppleAuthProvider.credential(
                  authServiceCredential.accessToken,
                )
              : GoogleAuthProvider.credential(
                  accessToken: authServiceCredential.accessToken,
                  idToken: authServiceCredential.idToken,
                );

      final auth = await FirebaseAuth.instance.signInWithCredential(credential);

      if (auth.user == null) {
        _logger.error(
          "auth.user should not be null after signInWithCredential!",
        );

        return const SignInResponse.failure(SignInFailure.cancelledByUser);
      }

      return getCurrentPrincipal();
    } on FirebaseAuthException catch (ex, stackTrace) {
      switch (ex.code) {
        case "user-disabled":
          return SignInResponse.failure(
            SignInFailure.userDisabled,
            ex,
            stackTrace,
          );
        case "network-request-failed":
          return SignInResponse.failure(
            SignInFailure.networkRequestFailed,
            ex,
            stackTrace,
          );
        default:
          return SignInResponse.failure(
            SignInFailure.unknown,
            ex,
            stackTrace,
          );
      }
    }
  }

  @override
  Future<SignOutResponse> signOut() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    return const SignOutResponse.success(null);
  }
}
```

`login_page`:
```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signIn(BuildContext context, AuthProvider authProvider) async {
    final response = await $mediator.send(SignInRequest(authProvider));

    if (response.isSuccess) {
      return;
    }

    switch (response.failure) {
      case SignInFailure.cancelledByUser:
        break;
      case SignInFailure.networkRequestFailed:
        await context.showOKDialog(
          title: "No internet connection",
          message: "There were a failure while trying to reach the "
              "authentication service.\n\nPlease, check your internet connection.",
        );
      case SignInFailure.userDisabled:
        await context.showOKDialog(
          title: "User is disabled",
          message: "Your user is disabled, please, contact support.",
        );
      default:
        await context.showOKDialog(
          title: "Oops",
          message: "An unknown error has ocurred!\n\n"
              "(Details: ${response.exception})",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: $mediator.getChannel<SignInAuthStageNotification>(),
      initialData: const SignInAuthStageNotification(AuthStage.idle),
      builder: (context, snapshot) {
        final currentAuthStage = snapshot.data?.stage ?? AuthStage.idle;

        final authMessage = switch (currentAuthStage) {
          AuthStage.idle => "Sign in with",
          AuthStage.signingInWithApple => "Awaiting Apple...",
          AuthStage.signingInWithGoogle => "Awaiting Google...",
          AuthStage.authorizing => "Authorizing...",
          AuthStage.registering => "Registering...",
        };

        final isBusy = currentAuthStage != AuthStage.idle;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  const AppLogo(dimension: 200),
                  const SizedBox.square(dimension: 16),
                  Text(
                    "App Name",
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Text(
                    authMessage,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox.square(dimension: 8),
                  isBusy
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 48,
                            child: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _AuthProviderButton(
                              onPressed: () =>
                                  _signIn(context, AuthProvider.google),
                              icon: const GoogleLogo(dimension: 16),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -2),
                              child: Text(
                                " or ",
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                            _AuthProviderButton(
                              onPressed: () =>
                                  _signIn(context, AuthProvider.apple),
                              icon: const AppleLogo(
                                dimension: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "PRIVACY POLICY",
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "ABOUT",
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "TERMS OF USE",
                            style: theme.textTheme.labelSmall,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.onPressed,
    required this.icon,
  });

  final void Function() onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      isSelected: true,
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
            )
          ],
        ),
        child: icon,
      ),
    );
  }
}
```
