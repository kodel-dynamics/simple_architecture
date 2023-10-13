Pub Package: https://pub.dev/packages/simple_architecture

Documentation: https://pub.dev/documentation/simple_architecture/latest/simple_architecture/simple_architecture-library.html

The Simple Architecture package provides four features to build apps upon:

# Settings

Settings are classes containing your application settings, such as `googleClientid` for authentication, a URL from a back-end server, etc.

Such settings are injected into the dependency injector and are updatable (can be used, for example, in conjunction with Firebase Remote Config).

Settings as classes are useful when you want to reuse your services (ex.: authentication service) among many different apps (each app will have different settings, such as `googleClientId`, `appleRedirectUri`, etc.). Separating the (variable) setting from the (fixed) services implementation eases up the reusability of those services.

You can register settings as this:

```dart
$settings.add(
    SampleSetting(
      string: "text",
      float: 3.14,
      integer: 42,
      boolean: true,
      dateTime: DateTime(2023, 10, 6, 21, 36),
    ),
  );
```

You can get the current setting value either by injecting it in some other constructor (ex.: `$services.registerTransient<IType>((get) => CType(get<SomeSetting>())))`) or using `$settings.get<SomeSettng>()`.

Settings are updatable with `$settings.replace<T>(T newValue)` (the `T` setting can (and should) be immutable, only the registration of the setting is replaceable).

# Services

Services are injectable and initializable classes that serve as implementations of external infrastructure or services, such as database repositories, firebase authentication services, etc.

These services have a contract described by an `abstract interface class` (or an `abstract base class` if you have shared/common code), containing all methods that must be implemented (eg:` login`, `logout`,` isAuthenticated`, etc.). Once the contracts are defined, you can inform the package which concrete class implements that functionality. This is useful for 3 reasons:

1) Your business classes will not know or need to deal with any implementation detail (not even exceptions).

2) You can reuse components (for example, if you do an authentication service that receives a configuration, you can use this same service as applications you want, just changing details, such as `googleClientId` in settings)

3) You can change certain system components at any time without much effort (for example, if any customer wishes authentication via Auth0 or Amazon Cognito instead of the Firebase Authentication).

Check more details about those patterns:

* Vertical Slice Architecture: https://www.jimmybogard.com/vertical-slice-architecture/
* Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
* Domain Model: https://martinfowler.com/eaaCatalog/domainModel.html
* Repository: https://martinfowler.com/eaaCatalog/repository.html
* MVVM: https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel
* DTO: https://martinfowler.com/eaaCatalog/dataTransferObject.html
* Plugin: https://martinfowler.com/eaaCatalog/plugin.html
* Transaction Script: https://martinfowler.com/eaaCatalog/transactionScript.html?ref=jimmybogard.com

You can register services in the `$services` shortcut (usually the first thing you do in your `main`).

```dart
Future<void> main() async {
  /// Register a CType as an instance of IType that receives an instance of an IOtherType
  /// Registration doesn't need to be in order
  $settings.registerSingleton<IType>(
    (get) = CType(get <IOtherType>()),
  );

  $settings.registerTransient<IOtherType>(
    (get) => COtherType(),
  )
}
```

You can get an instance of some service by calling `$services.get<IType>()`.

# Mediator Pattern

The mediator pattern is very simple and have only three parts:

1) Request/Response

  * Requests: you create a thin class that is your request (for instance `LoadCustomerByIdRequest(42)`). This class represents the action or feature your app is performing and can hold some additional information so that action can be performed (in this example, providing the id we want to load: 42). Requests also inform, by generics parameters, which type of response they should return (in this example, maybe a `Result<Customer?>` that contains a bool field for success or not, an exception field to hold the error, if any and a value field containing the Customer).

* Requests Handlers: those classes are injected using the same dependency injection system used in Services and have only one method: given some message (i.e.: `LoadCustomerByIdRequest`), what I need to do to answer it? Those classes are defined as `LoadCustomerByIdRequestHandler<TResponse, LoadCustomerByIdRequest>` and can inject services, so the business logic is pure and testable, because it doesn't have any side effects on it (all side effects are in the injected services, that can be mocked in an unit test).

2) Notifications

* Notifications are also messages, such as Requests (ex.: `CustomerWasLoaded(id: 42)`), but they don't have any handlers. They are stored in a behavior subject (a stream that holds the last value added) so none, one or more parts of your application can react to things that happened. This is useful, for example, audit log, plugins, etc.

3) Pipeline Behavior

* Every request can be intercepted and even be cancelled by a Pipeline Behavior. This is a special class that can execute some action before the next item in the pipeline is run (being the last item on this pipeline the actual RequestHandler). They are useful to implement things such as performance log (how much time a RequestHandler took to run?), exception handling (if the RequestHandler throws an error, report it to Firebase Crashlytics), etc.

Check more details:
* Mediator Pattern: https://en.wikipedia.org/wiki/Mediator_pattern
* CQRS: https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs
* Result: https://developer.apple.com/documentation/swift/result & https://github.com/Flutterando/result_dart