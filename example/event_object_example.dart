import 'package:event_object/event_object.dart';

void main() {
  // uncomment to see example in action

  // example1();
  // example2();
  // example3();
  // example4();
  // example5();
}

/// Example 1
///
/// This example shows how to use [Event.historyLimit] to control history mode
void example1() {
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

/// Example 2
///
/// This example shows how to use [Event.linkTo] method
///
/// This method is useful when you want to convert payload of a type to another type
void example2() {
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

/// Example 3
///
/// This example shows how to use [Event.notify] and [Event.onNext] methods to create notification events
/// and how to delay notifications
Future<void> example3() async {
  final event = Event(); // the payload type is dynamic

  // because payload type is dynamic then we can use [Event.notify] method
  event.notify(Duration(seconds: 5)); // will fire after 5 seconds

  print('waiting for notification...');

  // !Note: the fired payload value is null
  await event.onNext(); // waiting for the fired payload

  print('notification received');
}

/// Example 4
///
/// This example shows how to use [Event] to create reactive variable
void example4() async {
  // set [historyLimit] to 1 to just save 1 copy of the old values
  final name = Event<String>(name: 'name', historyLimit: 1);

  // set silent to true to prevent calling listeners with the default value
  name.fire('John', silent: true);

  // add listener to be called when the value changes
  name.addListener((payload) {
    print('name changed to $payload');
  });

  name.fire('Doe'); // set value to 'Doe'

  // set value to 'John Doe' after 5 seconds
  name.fire('John Doe', delay: Duration(seconds: 5));

  final newName = await name.onNext(1); // ignores 'Doe' and wait for 'John Doe'

  print('new name is $newName');
}

/// Example 5
///
/// This example shows how to use typed listeners and [EventComponent] object
void example5() {
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

abstract class SessionEvent {
  const SessionEvent();

  const factory SessionEvent.start() = OnStartSessionEvent;
  const factory SessionEvent.onMessage(String message) = OnMessageSessionEvent;
  const factory SessionEvent.errorEnd() = OnErrorEndSessionEvent;
  const factory SessionEvent.end() = OnEndSessionEvent;
}

class OnStartSessionEvent extends SessionEvent {
  const OnStartSessionEvent();
}

class OnMessageSessionEvent extends SessionEvent {
  const OnMessageSessionEvent(this.message);
  final String message;
}

class OnEndSessionEvent extends SessionEvent {
  const OnEndSessionEvent();
}

class OnErrorEndSessionEvent extends OnEndSessionEvent {
  const OnErrorEndSessionEvent();
}

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
