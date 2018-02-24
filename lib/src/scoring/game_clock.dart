import 'dart:async';

/// indicates the phase of the game
enum State { INIT, AUTON, TELEOP, DONE }

typedef void StateChange(State state);

/// manages the lifecycle of the game
class GameClock {
  static GameClock instance = new GameClock();

  State _state = State.INIT;

  State get state => _state;

  set state(State state) {
    if (state != _state) {
      _state = state;
      for (StateChange function in stateChangedListeners) {
        function(_state);
      }
    }
  }

  int currentSecond = 0;

  Set<StateChange> stateChangedListeners = new Set();

  /// register functions to invoke when there are state changes
  addStateChangeListener(StateChange function) =>
      stateChangedListeners.add(function);

  /// defer execution to avoid changes during iteration
  removeStateChangeListener(StateChange function) => new Timer(
      new Duration(milliseconds: 1),
      () => stateChangedListeners.remove(function));

  /// counts seconds in the game
  Timer _secondTimer;

  start() {
    currentSecond = 0;
    incrementTime(Timer timer) {
      currentSecond++;
      if (currentSecond >= 150) {
        timer.cancel();
        endGame();
      }
    }

    _secondTimer = new Timer.periodic(new Duration(seconds: 1), incrementTime);
    startAutonomous();
  }

  bool get isAuton => state == State.AUTON;

  bool get isInit => state == State.INIT;

  bool get isTeleop => state == State.TELEOP;

  bool get isEndGame => currentSecond >= 120;

  bool get isDone => state == State.DONE;

  cancel() {
    state = State.DONE;
    if(_secondTimer != null) {
      _secondTimer.cancel();
    }
    currentSecond = 0;
    state = State.INIT;
  }

  startAutonomous() {
    state = State.AUTON;
    new Timer(new Duration(seconds: 15), startTeleop);
  }

  startTeleop() {
    state = State.TELEOP;
    new Timer(new Duration(minutes: 2, seconds: 15), endGame);
  }

  endGame() => state = State.DONE;

  reset() {
    cancel();
  }

  bool get isGameActive => isAuton || isTeleop;
}
