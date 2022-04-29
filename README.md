# Events

This package will help you to create and manage events, by creating event objects that fires with payload.

## Usage

```dart
import 'package:event_object/event_object.dart';
```

## Examples

### Example 1

This example shows how to use __Event.historyLimit__ to control history mode.

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

```
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

This example shows how to use __Event.convertTo__ method
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
  event1.convertTo<String>(event2, (payload) => payload.toString());

  event1.fire(5); // fire event1 with payload 5
}
```

results:

```
event1 listener: 5, type: int
event1 listener: 5, type: String
```

### Example 3

This example shows how to use __Event.notify__ and __Event.onNext__ methods to create notification events
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

```
waiting for notification...
notification received // after 5 seconds
```

### Example 4

This example shows how to use __Events__ to create reactive variable

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

```
name changed to Doe
name changed to John Doe // after 5 seconds
new name is John Doe
```
