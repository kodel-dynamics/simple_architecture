[Pub Package: https://pub.dev/packages/simple_architecture](https://pub.dev/packages/simple_architecture)

The Simple Architecture package provides three pillars to build apps upon:

> THIS LIBRARY IS IN DEVELOPMENT AND CURRENTLY NOT FUNCTIONAL

# Settings

Settings are classes that contains your app settings, such as Google Client Id for Google Sign In, or some remote server URL, etc.

These settings are aways available through `$.settings.get<TypeOfSetting>()` and they can be also injected in any class registered in the dependency injector (ex.: `$.services.registerTransient((get) => MyTransientClass(injectedSetting: get<TypeOfSetting>()))`).

# Services

Services are classes that are registered in a dependency injection mechanism. Each registration can inject other registration (even if they aren't registered yet) or even settings.

Example:

```dart
$.services.registerSingleton<ISomeInterface>((get) => SomeSingletonClass(argument: get<SomeOtherInjectableClass>()));

...

final myClass = $.services.get<ISomeInterface>();

myClass is ISomeInterface == true;
```

You can only register classes before calling `$.services.initializeAsync()` and you can only get registered classes (including mediator handlers and registered settings) after initialization. The best place for initialization is right after all registration (settings, services and mediator handlers), in your Flutter's main app, right before `runApp()`.

## Initializers

There are two interfaces for service's initialization: `IInitializable` and `IBootable`.

`IInitializable` can be used both for transient or singleton registration. The `void initialize()` will run once the class is initialized (that occurs each time a transient class is instantiated or only once per singleton instance created).

`IBootable` only has effect in singletons registered with `registerBootableSingleton`. This interface has a `Future<void> initializeAsync()` that will be called once you run `$.service.initializeAsync()`. All bootable singletons will be instantiated at that point and they will be initialized (if they implement `IInitializable`) and run `initializeAsync` once. That is useful for async initializators, such as Firebase, databases migration, etc.

# Mediator

Finally, a mediator pattern mechanism is implemented with the dependency injector enabled so you can send requests, queries and notifications.

## Requests

Requests are commands represented by a class (ex.: `SaveCustomerCommand(customer: someInstance)``). You then register a handler for that particular message. The handler will get all dependencies that it needs and will receive your command instance, so you can implement some business logic and returning a response.

## Queries

Queries are the same as commands, but they output responses in a stream (so you can use a `StreamBuilder` to update the UI when a new response is available). For instance: you can create a query `LoadCustomerByIdQuery(customerId: 42)` and send it through the mediator: `$.mediator.query(myQuery)`. The stream `$.mediator.getQueryStream<LoadCustomerByIdQuery>()` is a behavior subject stream (meaning it keep the last value available so you don't need to refetch the data in different widgets). Also, it is smart enough to not rebuild when the same response is given (considering you are using some value equatable library, such as [Dart Mappable](https://pub.dev/packages/dart_mappable).)

## Notifications

Notifications are messages sent to whomever wants to listen to it. It's used, for instance, to respond to some system behavior (such as: whenever the authenticated user has changed, do something, since the authentication service will emit an notification of type `AuthenticatedUserChangedNotification`)
