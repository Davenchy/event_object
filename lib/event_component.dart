import 'event_object.dart';

abstract class EventComponent<P> {
  EventComponent({String name = 'event', int historyLimit = -1})
      : event = Event<P>(name: name, historyLimit: historyLimit);

  late final Event<P> event;

  /// get the latest payload if exists else returns null
  P? get lastPayload => event.lastPayload;

  /// fires a null payload without using history
  ///
  /// use [delay] to delay payload firing
  ///
  /// __only use when__ the payload type is __dynamic__
  ///
  /// for more information check docs for [Event.notify]
  void notify([Duration? delay]) => event.notify(delay);

  /// Fire the [payload] to all listeners.
  ///
  /// if [useHistory] is __true__ then the [payload] will be added to history
  ///
  /// use [delay] to delay fire
  ///
  /// set [silent] to __true__ to only add payload to lists without calling listeners
  ///
  /// for more information check docs for [Event.fire]
  void fire(
    P payload, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) =>
      event.fire(payload, useHistory: useHistory, delay: delay, silent: silent);

  /// add [listener] to the current [event]
  ///
  /// use [filter] to filter this [listener]
  ///
  /// for more information check docs for [Event.addListener] and [Event.addFilteredListener]
  ListenerKiller on(
    EventListener<P> listener, {
    bool useHistory = true,
    ListenerFilter<P>? filter,
  }) {
    if (filter == null) {
      return event.addListener(listener, useHistory: useHistory);
    } else {
      return event.addFilteredListener(
        listener,
        filter,
        useHistory: useHistory,
      );
    }
  }

  /// Add typed [listener] to the current [event] to be called only if payload type is [T] which is a subtype of [P]
  ///
  /// for more information check docs for [Event.addTypedListener]
  ListenerKiller onType<T extends P>(
    EventListener<T> listener, {
    bool useHistory = true,
  }) =>
      event.addTypedListener<T>(listener, useHistory: useHistory);

  /// Remove [listener] from the current [event]
  ///
  /// for more information check docs for [Event.removeListener]
  void off(EventListener<P> listener) => event.removeListener(listener);

  /// add listener with [converter] callback to convert payload of type [P] to payload of type [R]
  /// then fires the new payload using [event]
  ///
  /// for more information check docs for [Event.linkTo]
  ListenerKiller linkTo<R>(
    Event<R> event,
    PayloadConverter<P, R> converter, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) =>
      this.event.linkTo<R>(
            event,
            converter,
            useHistory: useHistory,
            delay: delay,
            silent: silent,
          );

  /// listens to another [Event] of the same type
  ///
  /// for more information check docs for [Event.listenTo]
  ListenerKiller listenTo(
    Event<P> event, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) =>
      this.event.listenTo(
            event,
            useHistory: useHistory,
            delay: delay,
            silent: silent,
          );
}
