import 'dart:async';
import 'dart:html';
import 'dart:math';

enum Color { RED, BLUE }
enum State { INIT, AUTON, TELEOP, DONE }
enum PowerUpState { INIT, ACTIVE, COMPLETE }
@deprecated
enum Source { SWITCH_10, SCALE_6, PORTAL_LEFT, PORTAL_RIGHT }

class Alliance {
  final Color color;
  final Match match;
  final Tally tally = new Tally();

  PowerCubeSource portalLeft = new PowerCubeSource(7, 'portal-red-left');
  PowerCubeSource portalRight = new PowerCubeSource(7, 'portal-red-right');
  PowerCubeSource switchSource = new PowerCubeSource(6, 'switch-red-right');
  PowerCubeSource allianceSource =
      new PowerCubeSource(10, 'alliance-red-right');

  Balance switch_;
  Vault vault;

  Alliance get oppositeAlliance => match.red == this ? match.blue : match.red;

  bool get isRed => color == Color.RED;

  bool get isBlue => color == Color.BLUE;

  Alliance(this.color, this.match) {
    vault = new Vault(this);
    switch_ = new Balance(
        match, (Alliance ally) => ally.vault.boost.isActiveForSwitch);
//    print('Creating alliance');
  }

  startAutonomous() {}

  startTeleop() {}
}

class Match {
  Alliance red;
  Alliance blue;
  Balance scale;
  State state = State.INIT;

  Match() {
    red = new Alliance(Color.RED, this);
    blue = new Alliance(Color.BLUE, this);
    scale = new Balance(
        this, (Alliance alliance) => alliance.vault.boost.isActiveForScale);
  }

  bool get isAuton => state == State.AUTON;

  bool get isInit => state == State.INIT;

  bool get isTeleop => state == State.TELEOP;

  bool get isDone => state == State.DONE;

  void startAutonomous() {
    state = State.AUTON;
    new Timer(new Duration(seconds: 15), startTeleop);
    red.startAutonomous();
    blue.startAutonomous();
  }

  void startTeleop() {
    state = State.TELEOP;
    new Timer(new Duration(minutes: 2, seconds: 15), endGame);
    red.startTeleop();
    blue.startTeleop();
  }

  void endGame() {
    state = State.DONE;
  }
}

class Tally {
  int matchPoints = 0;

  addPoints(int count) => matchPoints = matchPoints + count;
}

typedef bool PointMultiplier(Alliance alliance);

Random randomInstance = new Random();

class BalancePlate {
  int cubeCount = 0;
  final Balance balance;
  final Match match;
  Alliance _alliance;

  void set alliance(Alliance a) {
//    if (!(isRed && a.isRed)) {
//      otherPlate.alliance = a;
//      return;
//    }
    print('alliance is changing from $_alliance to $a');
    _alliance = a;
  }

  BalancePlate get otherPlate => isRed ? balance.bluePlate : balance.redPlate;

  Color get color => isRed ? Color.RED : Color.BLUE;

  Alliance get alliance {
    return _alliance;
  }

  bool get isRed => balance.redPlate == this;

  _addPoints() {
    int points = match.isAuton ? 2 : 1;
//    print('About to invoke multiplier ${alliance.color}');
    if (balance.pointMultiplier(alliance)) points = points * 2;
    alliance.tally.addPoints(points);
  }

  BalancePlate(this.balance, this.match);

  putCube(Robot robot, MouseEvent event, String sideClicked) {
    print(
        'clicked $sideClicked putCube in plate $color for alliance ${robot.alliance.color}');
    cubeCount++;
    _addPoints();
    balance.checkOwnership();
    robot.putCubeX(null, event);
  }
}

class Balance {
  final Match match;
  BalancePlate redPlate;
  BalancePlate bluePlate;
  BalancePlate owner;
  Timer timer = null;
  PointMultiplier pointMultiplier;
  bool redOnLeft = true;

  BalancePlate get leftPlate => redOnLeft ? redPlate : bluePlate;

  BalancePlate get rightPlate => redOnLeft ? bluePlate : redPlate;

  int get leftCubeCount => leftPlate.cubeCount;

  int get rightCubeCount => rightPlate.cubeCount;

  BalancePlate get winningPlate {
    if (redPlate.cubeCount == bluePlate.cubeCount) return null;
    return redPlate.cubeCount > bluePlate.cubeCount ? redPlate : bluePlate;
  }

  bool switchOwner() {
    var newOwner = winningPlate;
    if (owner != newOwner) {
      owner = newOwner;
      return true;
    }
    return false;
  }

  Balance(this.match, this.pointMultiplier) {
    redPlate = new BalancePlate(this, match);
    bluePlate = new BalancePlate(this, match);
    newMatch();
  }

  int cubeCount(Alliance alliance) =>
      alliance.color == Color.RED ? redPlate.cubeCount : bluePlate.cubeCount;

//  @override
//  void addCube(Alliance alliance) {
  checkOwnership() {
    if (leftCubeCount == rightCubeCount) {
      owner = null;
      _stopTimer();
      return;
    }
    if (switchOwner()) {
      _stopTimer();
      _startTimer();
    }
  }

  _addPoints([Timer ignore]) {
    if (owner == null) return;
    int points = owner.alliance.match.isAuton ? 2 : 1;
    if (pointMultiplier(owner.alliance)) points = points * 2;
    owner.alliance.tally.addPoints(points);
  }

  _stopTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  _startTimer() {
    timer = new Timer.periodic(new Duration(seconds: 1), _addPoints);
  }

  newMatch() {
    owner = null;
    redOnLeft = randomInstance.nextBool();
    redPlate.cubeCount = 0;
    bluePlate.cubeCount = 0;
  }
}

class Field {
  Match match;

  Field(this.match);
}

class PowerUp {
  int count = 0;
  bool triggered = false;
  PowerUpState state = PowerUpState.INIT;
  bool isLevitate;
  Alliance alliance;

  /// awaiting power up completion of other team
  bool _isSuspended = false;

  bool get isSuspended => _isSuspended;

  void set isSuspended(bool suspended) {
    bool needsToTrigger =
        !isLevitate && state == PowerUpState.ACTIVE && isSuspended;
    _isSuspended = suspended;
    if (needsToTrigger) {
      powerUpForTenSeconds();
    }
  }

  PowerUp(this.alliance, {this.isLevitate = false});

  /// Return true if scoring is doubled. Only applies to boost and force
  bool get isActiveForSwitch =>
      state == PowerUpState.ACTIVE && (count == 1 || count == 3);

  /// Return true if scoring is doubled. Only applies to boost and force
  bool get isActiveForScale =>
      state == PowerUpState.ACTIVE && (count == 2 || count == 3);

  bool get canTrigger =>
      state == PowerUpState.INIT && (isLevitate ? count >= 3 : count >= 1);

  PowerUp get oppositeAliancePowerUp => alliance.vault.boost == this
      ? alliance.oppositeAlliance.vault.boost
      : alliance.oppositeAlliance.vault.force;

  trigger() {
    state = PowerUpState.ACTIVE;
    if (!isLevitate && !isSuspended) {
      powerUpForTenSeconds();
    }
  }

  void powerUpForTenSeconds() {
    oppositeAliancePowerUp.isSuspended = true;
    new Timer(new Duration(seconds: 10), () {
      state = PowerUpState.COMPLETE;
      oppositeAliancePowerUp.isSuspended = false;
    });
  }
}

class Vault implements PowerCubeTarget {
  PowerUp force;
  PowerUp levitate;
  PowerUp boost;
  Alliance alliance;

  Vault(this.alliance) {
    force = new PowerUp(alliance);
    levitate = new PowerUp(alliance, isLevitate: true);
    boost = new PowerUp(alliance);
  }

  int count = 0;

  @override
  addCube(Alliance alliance) {
    count++;
    alliance.tally.addPoints(5);
  }
}

class PowerCubeSource implements HasId {
  int count;
  String id;

  PowerCubeSource(this.count, this.id);

  bool getCube() {
    if (count > 0) {
      count--;
      return true;
    }
    return false;
  }
}

abstract class PowerCubeTarget {
  void addCube(Alliance alliance);
}

class Variable {
  static final Random random = new Random();

  num _value;
  num _variationPercent;
  num _failurePercent;

  Variable(this._value, this._variationPercent, this._failurePercent);

  num get sampleValue {
    final num delta = random.nextInt(_value * _variationPercent ~/ 100);
    var result = random.nextBool() ? _value + delta : _value - delta;
//    print(
//        'Given: $_value Variation: $_variationPercent Delta: $delta Result: $result');
    return result;
  }
}

class Robot {
  Alliance alliance;
  LocationService locationService;

  /// in milliseconds
  Variable graspBall = new Variable(4000, 60, 30);

  /// in milliseconds
  Variable turn = new Variable(2000, 60, 5);

  /// in centimeter per second
  Variable travelSpeed = new Variable(100, 60, 0);

  /// in milliseconds
  Variable deliverBall = new Variable(2000, 60, 30);
  int autonFailurePercent = 70;

  bool hasPowerCube = false;
  bool hasCrossedLine = false;
  bool hasParked = false;
  bool hasClimbed = false;

  Point currentLocation = new Point(0, 0);

  /// default is to do nothing on move
  OnRobotMove onRobotMove = (bot, start, stop, doNothing) => null;

  doNothing() => null;

  Robot(this.alliance, this.locationService);

  crossLine() {
    if (!hasCrossedLine) {
      hasCrossedLine = true;
      alliance.tally.addPoints(5);
    }
  }

  parkOnPlatform() {
    if (!hasParked) {
      hasParked = true;
      alliance.tally.addPoints(5);
    }
  }

  climb() {
    if (!hasClimbed) {
      hasClimbed = true;
      alliance.tally.addPoints(30);
    }
  }

  getCube(PowerCubeSource source, [bool isPrematch = false]) {
//    if (isPrematch) return;
    final Location location = locationService.getLocation(source);
    hasPowerCube = source.getCube();
//    print('Move from ${currentLocation} to ${location.origin}');
    onRobotMove(this, currentLocation, location.origin,
        () => currentLocation = location.origin);
  }

  getCubeX(PowerCubeSource source, MouseEvent event,
      [bool isPrematch = false]) {
//    if (isPrematch) return;
    final Location location = locationService.getLocationX(event);
    hasPowerCube = source.getCube();
//    print('Move from ${currentLocation} to ${location.origin}');
    onRobotMove(this, currentLocation, location.origin,
        () => currentLocation = location.origin);
  }

  putCube(PowerCubeTarget target) {
    target.addCube(alliance);
    hasPowerCube = false;
  }

  putCubeX(PowerCubeTarget target, MouseEvent event) {
    if (target != null) {
      target.addCube(alliance);
    }
    hasPowerCube = false;
    final Location location = locationService.getLocationX(event);
//    print('Move from ${currentLocation} to ${location.origin}');
    onRobotMove(this, currentLocation, location.origin,
        () => currentLocation = location.origin);
  }
}

typedef void OnRobotMove(
    Robot robot, Point start, Point end, Function whenFinished);

abstract class LocationService {
  Location getLocation(HasId source);

  Location getLocationX(MouseEvent event);
}

class Location {
  Point origin;
  num width;
  num depth;

  Location(num x, num y, this.width, this.depth) {
    origin = new Point(x, y);
  }

  Point get center => new Point(origin.x + width / 2, origin.y + depth / 2);

  @override
  String toString() => '$origin, $width x $depth';
}

abstract class HasId {
  String get id;
}
