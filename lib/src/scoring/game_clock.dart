import 'dart:async';

enum State { INIT, AUTON, TELEOP, DONE }

typedef void StateChange(State state);

class GameClock {
  static GameClock instance = new GameClock();

  State _state = State.INIT;

  State get state => _state;

  set state(State state) {
    _state = state;
    for (StateChange function in stateChangedListeners) {
      function(_state);
    }
  }

  int currentSecond = 0;

  Set<StateChange> stateChangedListeners = new Set();

  addStateChangeListener(StateChange function) => stateChangedListeners.add(function);

  start() {
//    GameClock.instance = this;
    currentSecond = 0;
    incrementTime(Timer timer) {
      currentSecond++;
      if (currentSecond >= 150) {
        timer.cancel();
        endGame();
      }
    }

    new Timer.periodic(new Duration(seconds: 1), incrementTime);
    startAutonomous();
  }

  bool get isAuton => state == State.AUTON;

  bool get isInit => state == State.INIT;

  bool get isTeleop => state == State.TELEOP;

  bool get isDone => state == State.DONE;

  startAutonomous() {
    state = State.AUTON;
    new Timer(new Duration(seconds: 15), startTeleop);
  }

  startTeleop() {
    state = State.TELEOP;
    new Timer(new Duration(minutes: 2, seconds: 15), endGame);
  }

  endGame() {
    state = State.DONE;
  }

  reset() {
    state = State.INIT;
  }

  bool get isGameActive => isAuton || isTeleop;
}
