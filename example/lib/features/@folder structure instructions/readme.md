# Features

Features are things that your app does.

For example: Create a customer, authenticate an user, List a customer's orders, Delete the user account, etc.

You have two choices for implementing those features:

## Clean Architecture

There is a clean separation between different parts of your application (domain (business & logic), presentation (widgets), services (concrete implementations) and "other stuff").

Each feature has some folders to separate domain, presentation, services and shared code (see the readme.md for each folder for details).

If you like separating things for organization, go for it.

## Vertical Slice Architecture

You have the same separation of concerns of Clean Architecture (domain, presentation, services and shared), but you create less files with more contents on it. For example: you can create a `create_customer.dart` file that contains service contracts, domain models, mediator requests and mediator request handlers. All things related to "create a customer" is inside one file.

You still need to separate the service implementation and shared stuff into another file (or folders).

If you like having all related things nearby, that's your option.

## Create your own mechanics

If you follow these basic rules for your architecture, it doesn't really matter how you organize your files. You are free to use whatever method you feel most confortable.

But these rules should NOT be broken:

1) Your domain should be able to make your app work entirely in a test environment, without calling any package, database, I/O or anything that is considered a "side-effect". A side-effect is something that changes something in your environment or app state (such as writing a file, updating a database, calling a package that deals with unknown data, such as GPS or Firebase, etc.).

2) Your domin should be tested. Your domain contains the cake recipe of how your application do stuff. Most of time, reading and writing to databases are your entire app logic and no code is required. Even so, you need to write your domain with no database calls at all (delegating this to a service or repository). Tests are paramount.

3) (DRY) Don't repeat yourself: sometimes, we have some service that have some specific logic in it that will be the same, regardless of concrete implementations (for example: if you are building a log service, all code related to log level configuration and prevention of logging when that level is not enabled doesn't depend on concrete implementations, so you can write code to implement that without have to talking with anything else in your app). In those cases, an `abstract base class` with some code can be more useful than an `abstract interface class`, which can only have methods/properties contracts. DRY is more important than "you should always use interfaces".

4) All your services must be mockable. Your app should work with fake services implementation and libraries such as https://pub.dev/packages/mockito. Service Locator and Dependency Injection are paramount for this purpose. Learn what you can about those patterns.

5) Flutter is reactive. That means: it's often a bad choice to use the request/response pattern to deal with Flutter's interface. Instead, create a Request/RequestHandler to initiate some job (ex.: CreateCustomer), then use notifications to inform changes made by the handlers. For example: a `CustomerCreatedNotification` that contains information about the new customer can be used to refresh a list of custoemrs, to show some information about him/her, etc. Same can be applied for authentication: an `AuthenticateUserRequest` is sent to the mediator, then a `AuthenticateUserRequestHandler` deals with the logic about how to authenticate a user and it emits a `AuthenticatedUserChangedNotification` that can be listened by whomever wants to know about it (for example: a `StreamBuilder` that renders a login page when the authenticated user is null or a home page when there is an user available). Same thing can be used to react to a user name change: rebuilding specific widgets when needed.

6) Try to write shareable code: if you create some authentication service, make sure you can use that service, mediator requests and handlers in any future apps, without changing. Features should be isolated to the point that you can freely copy'n'paste entire folders inside other projects and make then work as easy as creating just a different setting for them.

7) Whatever is not a business logic, must be treated as a plugin: you should write your services contracts without any kind of knowledge about the infrastructure behind it. Example: if you want to change Firebase Authentication with Auth0 or Amazon Cognito, only one class should change: your concrete implementation. Try to write your services contracts as you didn't know what kind of service you'll use to write the implementation (example: you can write services for databases using SQLite, Hive, Isar, etc. Those are completely different, but your domain should not care about it: it should only care for "I need to load a customer with id X"). Make all services replacable.

8) Make each class, method, etc. have a single responsability: don't mix things. Do the least amount of work for each class so when that specific feature fails, you know exactly what has failed and changing it would not affect any other feature, because each feature do its own thing. (that's the *S* and part of the *O* of SOLID principle).

9) KISS: Keep It Simple, Stupid: keep your code simple. Don't overengineer it. Don't overcomplicate. Simple stuff is hard. Complicated stuff is easy. Complicated stuff is not "professional".

10) YAGNI: You Aren't Gonna Need It: If you don't need a feature or detail right now, don't write it. Keep it in your mind for a possible future implementation, but don't worry about things you don't need right now. Build your app as a lego: create small pieces, make them work together without the need of reengineering and you can build huge things easier. 