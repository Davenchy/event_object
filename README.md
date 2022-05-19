# EventObject

This package will help you to create and manage events, by creating event objects that fires with payload.

## Usage

```dart
import 'package:event_object/event_object.dart';
```

## Examples

[Example 1](#example-1): Control History using **Event.historyLimit**

[Example 2](#example-2): How to use **Event.linkTo** method

[Example 3](#example-3): How to use **Event.notify** and **Event.onNext**

[Example 4](#example-4): Create reactive variables

[Example 5](#example-5): How to use **Typed Listeners** and **EventComponent** abstract class

### Example 1

This example shows how to use **Event.historyLimit** to control history mode.

```dart
void main() {
  // by setting [historyLimit] to 0 we enable history mode with unlimited payloads
  final event = Event<String>(name: 'event', historyLimit: 0);

  print('add listener 1');
  event.addListener((payload) {
    print('event listener 1: $payload');
  });

  print('fire payload 1');
  event.fire('payload 1');

  print('fire payload 2');
  event.fire('payload 2');

  print('add listener 2');
  event.addListener((payload) {
    print('event listener 2: $payload');
  });

  print('fire payload 3');
  event.fire('payload 3');

  print('add listener 3');
  event.addListener((payload) {
    print('event listener 3: $payload');
  });
}
```

results:

```text
add listener 1
fire payload 1
event listener 1: payload 1

fire payload 2
event listener 1: payload 2

add listener 2
event listener 2: payload 1
event listener 2: payload 2

fire payload 3
event listener 1: payload 3
event listener 2: payload 3

add listener 3
event listener 3: payload 1
event listener 3: payload 2
event listener 3: payload 3
```

### Example 2

This example shows how to use **Event.linkTo** method
This method is useful when you want to convert payload of a type to another type

```dart
void main() {
  final event1 = Event<int>(name: 'event1');
  final event2 = Event<String>(name: 'event2');

  // add listener for the first event
  event1.addListener((payload) {
    print('event1 listener: $payload, type: ${payload.runtimeType}');
  });

  // add listener for the seconds event
  event2.addListener((payload) {
    print('event2 listener: $payload, type: ${payload.runtimeType}');
  });

  // convert payload from String to int
  event1.linkTo<String>(event2, (payload) => payload.toString());

  event1.fire(5); // fire event1 with payload 5
}
```

results:

```text
event1 listener: 5, type: int
event1 listener: 5, type: String
```

### Example 3

This example shows how to use **Event.notify** and **Event.onNext** methods to create notification events
and how to delay notifications

```dart
void main() async {
  final event = Event(); // the payload type is dynamic

  // because payload type is dynamic then we can use [Event.notify] method
  event.notify(Duration(seconds: 5)); // will fire after 5 seconds

  print('waiting for notification...');

  // !Note: the fired payload value is null
  await event.onNext(); // waiting for the fired payload

  print('notification received');
}
```

results:

```text
waiting for notification...
notification received // after 5 seconds
```

### Example 4

This example shows how to use **Events** to create reactive variable

```dart
void main() async {
  // set [historyLimit] to 1 to just save 1 copy (the latest value)
  final name = Event<String>(name: 'name', historyLimit: 1);

  // set silent to true to prevent calling listeners with the initial value
  name.fire('John', silent: true);

  // add listener to be called when the value changes
  name.addListener((payload) {
    print('name changed to $payload');
  });

  name.fire('Doe'); // set value to 'Doe'

  // set value to 'John Doe' after 5 seconds
  name.fire('John Doe', delay: Duration(seconds: 5));
  
  // ignore 1 fire call
  final newName = await name.onNext(1); // ignores 'Doe' and wait for 'John Doe'

  print('new name is $newName');
}
```

results:

```text
name changed to Doe
name changed to John Doe // after 5 seconds
new name is John Doe
```

### Example 5

This example will show you how to use **EventComponent** class and **typed listeners** step by step

This is an example for a **fake** session object that can start, receive messages and end

Lets define our abstract event type

```dart
abstract class SessionEvent {
  const SessionEvent();
}
```

Now lets extend  `SessionEvent` and create `start` and `end` events

```dart
class OnStartSessionEvent extends SessionEvent {
  const OnStartSessionEvent();
}

class OnEndSessionEvent extends SessionEvent {
  const OnEndSessionEvent();
}
```

Lets add subclass for `OnEndSessionEvent`

```dart
class OnErrorEndSessionEvent extends OnEndSessionEvent {
  const OnErrorEndSessionEvent();
}
```

Lets create one more event to handle messages

```dart
class OnMessageSessionEvent extends SessionEvent {
  const OnMessageSessionEvent(this.message);
  final String message;
}
```

Now lets modify our `SessionEvent` class to define some aliases for our events using the **factory** keyword

```dart
abstract class SessionEvent {
  const SessionEvent();

+  const factory SessionEvent.start() = OnStartSessionEvent;
+  const factory SessionEvent.onMessage(String message) = OnMessageSessionEvent;
+  const factory SessionEvent.errorEnd() = OnErrorEndSessionEvent;
+  const factory SessionEvent.end() = OnEndSessionEvent;
}
```

Cool, now lets define our session class

```dart
class Session extends EventComponent<SessionEvent> {
  Session() : super(name: 'session_event');

  void start() {
    fire(const SessionEvent.start());
  }

  void receiveMessage(String message) {
    fire(SessionEvent.onMessage(message));
  }

  void end() {
    fire(const SessionEvent.end());
  }
}

```

Now lets use it

```dart
void main() {
  final session = Session();

  // lets handle session events
  session.onType<OnStartSessionEvent>((_) => print('session started'));

  // `OnErrorEndSessionEvent` is a subclass of `OnEndSessionEvent`
  // so to only listen to `OnEndSessionEvent` set `useRuntimeType` to true
  // by default `useRuntimeType` is false means we listen to `OnEndSessionEvent` and `OnErrorEndSessionEvent`
  session.onType<OnEndSessionEvent>(
    (_) => print('session ended'),
    useRuntimeType: true,
  );

  // lets try to fire `OnErrorEndSessionEvent`
  session.fire(SessionEvent.errorEnd());

  session.onType<OnMessageSessionEvent>(
    (payload) => print('received message: ${payload.message}'),
  );

  // lets start the session
  session.start();

  // lets receive message
  session.receiveMessage('hello world');

  // lets end the session
  session.end();
}
```

results:

```text
session started
received message: hello world
session ended
```

We fired `OnEndSessionEvent` by calling `session.end()` and `OnErrorEndSessionEvent` which a subclass for `OnEndSessionEvent`
but we got `session ended` printed only once because the listener only listens for `OnEndSessionEvent` as a runtime type

example for default type checking:

```dart
void check<T>(Function callback) {
  addListener((event) {
    if (event is T) callback(event);
  });
}
```

example for runtime type checking:

```dart
void check<T>(Function callback) {
  addListener((event) {
    if (event.runtimeType is T) callback(event);
  });
}
```
