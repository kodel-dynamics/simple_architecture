# Domain

In this folder you keep all things related to your application, what it does, the "domain" of the application.

You should apply 100% code coverage in unit tests for all things in this folder.

Examples:

* `User(id, name, photo)`: a class that represents the currently authenticated user (a domain model, anaemic or not).
* `CreateCustomerRequest`: a class that represents a request to create a new customer.
* `CreateCustomerRequestHandler`: a class that handles the above message and contains code *only* specific for that purpose (any I/O are made by services, injected in the constructor)
* `AuthenticateRequest(AuthProvider.google)`: a class that contains a message to request an authentication through Google Sign In.
* `AuthenticateRequestHandler`: a handler for the above message that deals with authentication job, delegating specifics (Apple Sign In, Google Sign In, Firebase Auth, etc.) to services.
* `GlobalErrorHandlerPipelineBehavior`: a pipeline that envelopes all mediator calls in a try/catch to be used with Firebase Crashlytics or Sentry.

Usually, these classes contain only unit-testable code that makes your app do what it does.

It does not handle databases (such as Isar), external services (such as Firebase Auth), etc. Those are services, in the infrastructure folder, injected by the dependency injector.

The interfaces that specify the contract of those services belong to this folder.