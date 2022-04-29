import 'dart:async';

typedef EventListener<P> = void Function(P payload);
typedef PayloadConverter<P, R> = R Function(P payload);
typedef ListenerKiller = void Function();

class Event<P> {
  /// New event of payload type [P] with [name]
  ///
  /// if [historyLimit] is __less than zero__, then the history mode will not be enabled
  ///
  /// if [historyLimit] is __equal to zero__, then the history mode will be enabled without payloads limit
  ///
  /// if [historyLimit] is __greater than zero__, then the history mode will be enabled with [historyLimit] payloads limit
  Event({this.name = 'event', this.historyLimit = -1});

  /// event name
  final String name;

  /// if value is 0 then no history limit
  /// if value is -1 then no history
  /// if value is > 0 then history limit
  final int historyLimit;

  final List<P> _history = [];
  final List<EventListener<P>> _listeners = [];
  final List<P> _payloadsQueue = [];
  bool _isBusy = false;

  int get historyLength => _history.length;
  int get listenersCount => _listeners.length;
  List<P> get history => List.unmodifiable(_history);

  /// get the latest payload if exists else returns null
  P? get lastPayload => _history.last;

  /// fires a null payload without using history
  ///
  /// use [delay] to delay payload firing
  ///
  /// __only use when__ the payload type is __dynamic__
  void notify([Duration? delay]) =>
      fire(null as P, useHistory: false, delay: delay);

  /// Fire the [payload] to all listeners.
  ///
  /// if [useHistory] is __true__ then the [payload] will be added to history
  ///
  /// use [delay] to delay fire
  ///
  /// set [silent] to __true__ to only add payload to lists without calling listeners
  void fire(
    P payload, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) async {
    // delay fire
    if (delay != null) await Future.delayed(delay);

    _payloadsQueue.add(payload); // add payload to queue

    // add payload to history if enabled
    if (historyLimit >= 0 && useHistory) _history.add(payload);

    // remove first payload if history length exceeds limit
    if (historyLimit > 0 && _history.length > historyLimit) {
      _history.removeAt(0);
    }

    loop();
  }

  /// call all listeners with the payloads queue
  void loop() {
    // if current event is busy then return;
    if (_isBusy) return;
    _isBusy = true; // set current event in busy mode

    // fire all listeners
    while (_payloadsQueue.isNotEmpty) {
      final P currentPayload = _payloadsQueue.removeAt(0);
      for (var listener in _listeners) {
        listener(currentPayload);
      }
    }

    _isBusy = false; // set current event in idle mode
  }

  /// add [listener] to listeners
  ///
  /// if history is enabled then [listener] will be called with all history payloads
  ///
  /// if [useHistory] is __false__ [listener] will be added only even if history is enabled
  ///
  /// returns [ListenerKiller] as an alias for `remove(listener)`
  ListenerKiller addListener(
    EventListener<P> listener, {
    bool useHistory = true,
  }) {
    _listeners.add(listener); // add listener to listeners list

    // if history is enabled then fire all old payloads
    if (historyLimit >= 0 && useHistory) {
      for (final payload in _history) {
        listener(payload);
      }
    }

    return () => removeListener(listener);
  }

  /// add listener with [converter] callback to convert payload of type [P] to payload of type [R]
  /// then fires the new payload using [event]
  ListenerKiller convertTo<R>(
    Event<R> event,
    PayloadConverter<P, R> converter, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) =>
      addListener(
        (payload) => event.fire(
          converter(payload),
          useHistory: useHistory,
          delay: delay,
          silent: silent,
        ),
      );

  /// listens to another [Event] of the same type
  ListenerKiller listenTo(
    Event<T> event, {
    bool useHistory = true,
    Duration? delay,
    bool silent = false,
  }) =>
      event.addListener(
        (payload) => fire(
          payload,
          useHistory: useHistory,
          delay: delay,
          silent: silent,
        ),
      );

  /// remove [listener]
  void removeListener(EventListener<P> listener) => _listeners.remove(listener);

  /// clear listeners list
  ///
  /// use [filter] to select which listener to be removed
  void clear([
    bool Function(EventListener<P> listener)? filter,
  ]) =>
      filter != null ? _listeners.clear() : _listeners.removeWhere(filter!);

  /// clear payloads history
  void clearHistory() => _history.clear();

  /// returns future that completes on next fire
  ///
  /// use [ignoreCount] value to ignore number of fires
  ///
  /// `onNext(1)` completes after second fire because it ignore 1 fire
  Future<P> onNext([int? ignoreCount]) async {
    final completer = Completer<P>();
    final killer = addListener((payload) {
      if ((ignoreCount ?? 0) <= 0) completer.complete(payload);
      ignoreCount = (ignoreCount ?? 0) - 1;
    });
    return completer.future.whenComplete(killer);
  }
}
