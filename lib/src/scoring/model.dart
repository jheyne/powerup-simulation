import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'game_clock.dart';
import 'goal_spec.dart';

enum Color { RED, BLUE }
enum PowerUpState { INIT, ACTIVE, COMPLETE }
@deprecated
enum Source { SWITCH_10, SCALE_6, PORTAL_LEFT, PORTAL_RIGHT }

class Alliance {
  final Color color;
  final Match match;
  final Tally tally = new Tally();

  PowerCubeSource portalLeft = new PowerCubeSource(7, 'portal-red-left');
  PowerCubeSource portalRight = new PowerCubeSource(7, 'portal-red-right');
  PowerCubeSource switchSource = new PowerCubeSource(6, 'red-6-source');
  PowerCubeSource allianceSource = new PowerCubeSource(10, 'red-10-source');

  Balance switch_;
  Vault vault;

  Alliance get oppositeAlliance => match.red == this ? match.blue : match.red;

  bool get isRed => color == Color.RED;

  bool get isBlue => color == Color.BLUE;

  Alliance(this.color, this.match) {
    vault = new Vault(this, color == Color.RED ? 'red-vault' : 'blue-vault');
    switch_ = new Balance(
        match,
        (Alliance ally) => ally.vault.boost.isActiveForSwitch,
        color == Color.RED ? 'bottom-switch' : 'top-switch');
    if (color == Color.BLUE) {
      portalLeft._id = 'portal-blue-left';
      portalRight._id = 'portal-blue-right';
      switchSource._id = 'blue-6-source';
      allianceSource._id = 'blue-10-source';
    }
    match.gameClock.addStateChangeListener(gameStateChanged);
  }

  void gameStateChanged(State state) {}
}

class Match {
  Alliance red;
  Alliance blue;
  Balance scale;
  GameClock gameClock = GameClock.instance;

  Match() {
    red = new Alliance(Color.RED, this);
    blue = new Alliance(Color.BLUE, this);
    scale = new Balance(this,
        (Alliance alliance) => alliance.vault.boost.isActiveForScale, "scale");
  }
}

class Tally {
  int matchPoints = 0;

  addPoints(int count) {
    if (GameClock.instance.isGameActive) {
      matchPoints = matchPoints + count;
    }
  }
}

typedef bool PointMultiplier(Alliance alliance);

Random randomInstance = new Random();

class BalancePlate extends PowerCubeTarget {
  List<String> id(Robot robot) {
    List<String> list = [basicId];
    if (robot.isRed) {
      list.add(balance.redPlate == balance.rightPlate ? "right" : "left");
    } else {
      list.add(balance.bluePlate == balance.rightPlate ? "right" : "left");
    }
    return list;
  }

  String get basicId => balance.basicId;

  int cubeCount = 0;
  final Balance balance;
  final Match match;
  Alliance _alliance;

  int get pointMargin => cubeCount - otherPlate.cubeCount;

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
    int points = match.gameClock.isAuton ? 2 : 1;
//    print('About to invoke multiplier ${alliance.color}');
    if (balance.pointMultiplier(alliance)) points = points * 2;
    alliance.tally.addPoints(points);
  }

  BalancePlate(this.balance, this.match);

  addCube(Alliance alliance, [Robot robot]) {
    cubeCount++;
    print('cube count is now $cubeCount for ${id(robot)}');
    _addPoints();
    balance.checkOwnership();
  }

  putCube(Robot robot, MouseEvent event, String sideClicked) {
    print('clicked $sideClicked putCube in plate $color for alliance ${robot
        .alliance.color} with id ${id(robot)}');
    finished() {
      cubeCount++;
      _addPoints();
      balance.checkOwnership();
    }

    robot.putCubeX(null, event, finished);
  }
}

class Balance implements HasId {
  String _id;
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

  List<String> id(Robot robot) => [basicId];

  String get basicId => _id;

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

  Balance(this.match, this.pointMultiplier, this._id) {
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
    int points = owner.alliance.match.gameClock.isAuton ? 2 : 1;
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
  String _id;
  PowerUp force;
  PowerUp levitate;
  PowerUp boost;
  Alliance alliance;

//  int get pointMargin => force.count + levitate.count + boost.count;
  int get pointMargin => count;

  int get cubeCount => count;

  List<String> id(Robot robot) => [basicId];

  String get basicId => _id;

  Vault(this.alliance, this._id) {
    force = new PowerUp(alliance);
    levitate = new PowerUp(alliance, isLevitate: true);
    boost = new PowerUp(alliance);
  }

  int count = 0;

  @override
  addCube(Alliance alliance, [Robot robot]) {
    count++;
    alliance.tally.addPoints(5);
  }
}

class PowerCubeSource implements HasId {
  int count;
  String _id;

  PowerCubeSource(this.count, this._id);

  List<String> id(Robot robot) => [basicId];

  String get basicId => _id;

  bool getCube() {
    if (count > 0) {
      count--;
      return true;
    }
    return false;
  }
}

abstract class PowerCubeTarget implements HasId {
  void addCube(Alliance alliance, [Robot robot]);

  int get pointMargin;

  int get cubeCount;
}

class Variable {
  static final Random random = new Random();

  num value;
  num variationPercent;
  num failurePercent;

  Variable(this.value, this.variationPercent, this.failurePercent);

  num get sampleValue {
    final num delta = random.nextInt(value * variationPercent ~/ 100);
    var result = random.nextBool() ? value + delta : value - delta;
//    print(
//        'Given: $_value Variation: $_variationPercent Delta: $delta Result: $result');
    return result;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['value'] = value;
    json['variation'] = variationPercent;
    json['failure'] = failurePercent;
    return json;
  }
}

class VariableRange {
  Variable worst;
  Variable best;

  VariableRange(this.worst, this.best);

  adjust(Variable variable, int rank) {
    variable.value = adjustRange(best.value, worst.value, rank);
//    variable.variationPercent =
//        adjustRange(best.variationPercent, worst.variationPercent, rank);
//    variable.failurePercent =
//        adjustRange(best.failurePercent, worst.failurePercent, rank);
  }

  num adjustRange(num bestValue, num worstValue, int rank) {
    num range = (bestValue - worstValue).abs();
    num delta = range * rank / 100;
    bool betterIsSmaller = bestValue < worstValue;
    var x = betterIsSmaller ? worstValue - delta : worstValue + delta;
    print('Best $bestValue Worst $worstValue Delta: $delta Computed Value: $x');
    return x.round();
  }
}

typedef LocationService HasLocationService();

class Robot {
  String label = "unnamed";
  Alliance alliance;
  HasLocationService hasLocationService;
  String strategy;

  /// in milliseconds
  Variable graspCube = new Variable(3500, 60, 30);
  static VariableRange graspCubeRange =
      new VariableRange(new Variable(12000, 60, 80), new Variable(750, 20, 10));

  /// in milliseconds
  Variable turn = new Variable(3000, 60, 5);
  static VariableRange turnRange =
      new VariableRange(new Variable(5000, 60, 50), new Variable(750, 20, 5));

  /// in centimeter per second
  Variable travelSpeed = new Variable(300, 60, 0);
  static VariableRange travelSpeedRange =
      new VariableRange(new Variable(50, 60, 30), new Variable(500, 20, 5));

  /// in milliseconds
  Variable deliverCube = new Variable(2000, 30, 30);
  static VariableRange deliverCubeRange =
      new VariableRange(new Variable(15000, 60, 30), new Variable(1000, 20, 5));

  /// in milliseconds
  Variable deliverCubeHigh = new Variable(9000, 30, 30);
  static VariableRange deliverCubeHighRange =
      new VariableRange(new Variable(25000, 60, 30), new Variable(3000, 20, 5));
  int autonFailurePercent = 70;

  List<GoalSpec> goalSpecs = [];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['graspCube'] = graspCube.toJson();
    json['turn'] = turn.toJson();
    json['travelSpeed'] = travelSpeed.toJson();
    json['deliverCube'] = deliverCube.toJson();
    json['deliverCubeHigh'] = deliverCubeHigh.toJson();
    json['autonFailure'] = autonFailurePercent;
    List<Map<String, dynamic>> specs = [];
    for (GoalSpec spec in goalSpecs) {
      specs.add(spec.toJson());
    }
    json['goalSpecs'] = specs;
    return json;
  }

  bool hasPowerCube = false;
  bool hasCrossedLine = false;
  bool hasParked = false;
  bool hasClimbed = false;

  bool get isRed => alliance.isRed;

  Point currentLocation = new Point(0, 0);

  /// default is to do nothing on move
  OnRobotMove onRobotMove = (bot, start, stop, doNothing) => null;

  doNothing() => null;

  Robot(this.alliance, this.hasLocationService);

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

  Future<bool> getCube(PowerCubeSource source, [bool isPrematch = false]) {
//    if (isPrematch) return;
    final Location location = hasLocationService().getLocation(source, this);
    Completer<bool> completer = new Completer();
    finished() {
      currentLocation = location.origin;
      hasPowerCube = source.getCube();
      completer.complete(true);
    }

    onRobotMove(this, currentLocation, location.origin, finished);
    return completer.future;
  }

  getCubeX(PowerCubeSource source, MouseEvent event,
      [bool isPrematch = false]) {
//    if (isPrematch) return;
    final Location location = hasLocationService().getLocationX(event);
    finished() {
      currentLocation = location.origin;
      hasPowerCube = source.getCube();
    }

    onRobotMove(this, currentLocation, location.origin, finished);
  }

  Future<bool> putCube(PowerCubeTarget target) {
    final Location location = hasLocationService().getLocation(target, this);
    Completer<bool> completer = new Completer();
    print('Going to target: $target at: $location from $currentLocation');
    finished() {
      if (target != null) {
        target.addCube(alliance, this);
      }
      currentLocation = location.center;
      hasPowerCube = false;
//      locationService.detectChanges();
      completer.complete(true);
    }

    onRobotMove(this, currentLocation, location.center, finished);
    return completer.future;
  }

  putCubeX(PowerCubeTarget target, MouseEvent event, [Function whenFinished]) {
    final Location location = hasLocationService().getLocationX(event);
    finished() {
      if (whenFinished != null) {
        whenFinished();
      }
      if (target != null) {
        target.addCube(alliance);
      }
      currentLocation = location.origin;
      hasPowerCube = false;
    }

    onRobotMove(this, currentLocation, location.origin, finished);
  }

  /// adjust the overall performance of the robot to reflect the given ranking
  void set ranking(int rank) {
    travelSpeedRange.adjust(travelSpeed, rank);
    turnRange.adjust(turn, rank);
    graspCubeRange.adjust(graspCube, rank);
    deliverCubeRange.adjust(deliverCube, rank);
    deliverCubeHighRange.adjust(deliverCubeHigh, rank);
  }

  void set speed(int rank) {
    travelSpeedRange.adjust(travelSpeed, rank);
    turnRange.adjust(turn, rank);
  }

  void set agility(int rank) {
    graspCubeRange.adjust(graspCube, rank);
    deliverCubeRange.adjust(deliverCube, rank);
    deliverCubeHighRange.adjust(deliverCubeHigh, rank);
  }
}

typedef void OnRobotMove(
    Robot robot, Point start, Point end, Function whenFinished);

abstract class LocationService {
  Location getLocation(HasId source, Robot robot);

  Location getLocationX(MouseEvent event);

  void detectChanges();
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
  List<String> id(Robot robot);

  String get basicId;
}
