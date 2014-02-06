part of three;

class EventEmitterEvent {
  String type;
  String message;
  var content;
  EventEmitterEvent({this.type, this.message, this.content});
}

class EventEmitter {
  Map listeners = {};

  addEventListener(String type, Function listener) {
    if (!listeners.containsKey(type)) {
      listeners[type] = [];
    }
    if (!listeners[type].contains(listener)) {
      listeners[type].add(listener);
    }
  }

  dispatchEvent(EventEmitterEvent event) {
    if (listeners.containsKey(event.type)) {
      listeners[event.type].forEach((listener) => listener(event));
    }
  }

  bool removeEventListener(String type, Function listener) => listeners[type].remove(listener);
}