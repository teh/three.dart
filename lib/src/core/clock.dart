part of three;

class Clock {
  /// Returns the time when the clock was started.
  DateTime startTime;
  
  /// Returns wether the clock is currently running.
  bool running = false;
  
  /// Creates a new clock object. If [_autoStart] is set, the clock starts 
  /// automatically when [getDelta] is first called.
  Clock([this._autoStart = true]);
  
  DateTime _oldTime;
  double _elapsedTime = 0.0;
  bool _autoStart;
  
  /// Starts the clock.
  void start() {
    startTime = new DateTime.now();
    _oldTime = startTime;
    running = true;
  }
  
  /// Stops the clock.
  void stop() {
    getDelta();
    running = false;
  }
  
  /// If the clock is running, it returns elapsed seconds as a decimal number since the clock was called.
  double get elapsedTime {
    getDelta();
    return _elapsedTime;
  }

  /// Returns seconds passed a since the last call to this method.
  double getDelta() {
    var diff;

    if (_autoStart && !running) start();
    
    if (running) {
      var newTime = new DateTime.now();
      diff = 0.001 * newTime.difference(_oldTime).inMilliseconds;
      _oldTime = newTime;
      _elapsedTime += diff;
    }

    return diff;
  }
}