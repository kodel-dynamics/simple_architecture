# Services

In this folder you keep all concrete implementations of your services.

Often those classes are not unit-tested, since they have side effects (such as calling Firebase Auth to actually authenticate a user). Since those services implements an Interface, it's more common to use some mock package, such as https://pub.dev/packages/mockito, to unit test those.

You can, though, apply integration tests for these services, if you want.

Examples:

* `FirebaseCrashlyticsService`: If you have a pipeline behavior that grabs all mediator exceptions and then log them with a contract `IGlobalErrorService`, you can then implement that interface here, specific for Firebase Crashlytics use.
* Databases are also kept here (how you speak with the database is defined by the service interface). Usually, domain models are inadequate for database use (because databases classes often have configuration attributes (such as `@collection` for Isar), etc.). Those database specific details are encapsulated in this folder and nothing else knows about them. You usually have some wrapper or mapper to convert your database classes into domain models.
