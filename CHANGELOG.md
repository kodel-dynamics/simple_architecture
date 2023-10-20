## 0.231006.1
* Initial release with Services (dependency injection), Settings (injectable app environment variables) and Mediator (a mediator pattern with pipeline behavior).

## 0.231007.1
* Services implemented

## 0.231007.2
* Refactorings to please Pana

## 0.231010.1
* Mediator pattern implemented

## 0.231010.2
* Fixed missing markdown features on pub.dev

## 1.231012.1
* States implemented
* Initial non-debug release

## 1.231012.2
* Docs link

## 1.231012.3
* Lint issues

## 1.231012.4
* Abstract interfaces for `registerBootableSingleton` no longer required to inherit `IBootable` (but the concrete class must)

## 1.231012.5
* Initializing mediator before finishing booting `IBootable` instances

## 1.231012.6
* Fixed for nullable states

## 1.231012.7
* Short lived notification listeners

## 1.231012.8
* Short lived notification listeners with return values

## 1.231012.9
* Less verbosity on services log

## 1.231016.1
* Const Logger, so more classes can be registered as const as well
* Better documentation (I hope)

## 1.231019.1
* Added `Response<TValue, TFailure extends Enum>` as an union class for mediator responses that can be either success (where value = TValue) or failure (where failure is an Enum)

## 1.231019.2
* Added some extension methods to publish `INotification` and `IRequest<TResponse>`

## 1.231019.3
* Fixed logging for `INotification.publish()`

## 1.231019.4
* Fixed initialization order

## 1.231019.5
* Fixed states not being emitted on load

## 1.231020.1
* Loggers are no longer instantiated, but rather used as an extension method on `Object` (`this._logger`);