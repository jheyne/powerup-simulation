import 'dart:async';

import 'model.dart';

//class AutoBot extends Robot {
//  AutoBot(Alliance alliance, LocationService locationService)
//      : super(alliance, locationService);
//}

class AutoBotBuilder {
  static AutoBot sampleNearField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies.add(StrategyBuilder.nearField(robot.alliance,
        vaultMargin: 3, vaultMax: 3, switchMargin: 2, includeScale: true));
    return autoBot;
  }

  static AutoBot sampleMidField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies
        .add(StrategyBuilder.midField(robot.alliance, switchMargin: 1));
    return autoBot;
  }
}

class AutoBot {
  Robot robot;

  List<Strategy> strategies = [];

  AutoBot(this.robot);

  runAuto() async {
    for (Strategy strategy in strategies) {
      await runStrategy(strategy);
    }
  }

  Future<bool> runStrategy(Strategy strategy) async {
    Completer<bool> completer = new Completer();
    while (strategy.hasSources) {
      bool hasCube = await strategy.fetchCube(robot);
      if (!hasCube) {
        print('runStrategy completing because no cube');
        completer.complete(false);
        break;
      }
      await strategy.placeCube(robot);
    }
    return completer.future;
  }

  Future<bool> fetchAndPlace(Robot robot, Strategy strategy) async {
    bool hasCube = await strategy.fetchCube(robot);
    if (!hasCube) {
      return false;
    }
    await strategy.placeCube(robot);
    return true;
  }
}

class StrategyBuilder {
  static Strategy nearField(Alliance alliance,
      {int vaultMargin: 3,
      vaultMax: 9,
      int switchMargin: 2,
      bool includeScale: false,
      int scaleMargin: 1,
      int scaleMax: 2}) {
    vault() => alliance.vault;
    plate() =>
        alliance.isRed ? alliance.switch_.redPlate : alliance.switch_.bluePlate;
    List<TargetSpec> targets = [
      new TargetSpec(plate, minMargin: switchMargin, priority: 10),
      new TargetSpec(vault,
          minMargin: vaultMargin, priority: 5, maxCount: vaultMax)
    ];
    if (includeScale) {
      scalePlate() => alliance.isRed
          ? alliance.match.scale.redPlate
          : alliance.match.scale.bluePlate;
      targets.add(new TargetSpec(scalePlate,
          minMargin: scaleMargin, maxCount: scaleMax, priority: 1));
    }
    return new Strategy(
        [() => alliance.switchSource, () => alliance.allianceSource], targets);
  }

  static Strategy midField(Alliance alliance,
      {int switchMargin: 2, int scaleMargin: 2, int scaleMax: 100}) {
    switchPlate() =>
        alliance.isRed ? alliance.switch_.redPlate : alliance.switch_.bluePlate;
    scalePlate() => alliance.isRed
        ? alliance.match.scale.redPlate
        : alliance.match.scale.bluePlate;
    List<TargetSpec> targets = [
      new TargetSpec(scalePlate,
          minMargin: scaleMargin, maxCount: scaleMax, priority: 10),
      new TargetSpec(switchPlate, minMargin: switchMargin, priority: 1),
    ];
    List<GetSource> sources = [
      () => alliance.oppositeAlliance.switchSource,
      () => alliance.switchSource,
      () => alliance.allianceSource,
    ];
    return new Strategy(sources, targets);
  }
}

typedef PowerCubeTarget GetTarget();
typedef PowerCubeSource GetSource();

class Strategy {
  List<GetSource> sources;

  /// the key is the target, and the value is the desired margin of points to maintain for the target
  List<TargetSpec> targets;

  Strategy(this.sources, this.targets);

  bool get hasSources {
    for (GetSource source in sources) {
      if (source().count > 0) {
        print('Source has count of ${source().count}');
        return true;
      }
    }
    return false;
  }

  FutureOr<bool> fetchCube(Robot robot) async {
    if (!robot.hasPowerCube) {
      PowerCubeSource source = nextSource;
      print('Got nextSource $source with id ${source.id(robot)}');
      if (source != null) {
//        print('Source $source : ${source.id(robot)}');
        bool success = await robot.getCube(source);
//        return success;
        return robot.hasPowerCube;
      }
    }
    return true;
  }

  FutureOr<bool> placeCube(Robot robot) async {
    if (robot.hasPowerCube) {
      PowerCubeTarget target = nextTarget;
      print('Got nextTarget $target with id ${target.id(robot)}');
      if (target != null) {
//        print('Target $target : ${target.id(robot)}');
        bool success = await robot.putCube(target);
        return success;
      }
    }
    return true;
  }

  PowerCubeSource get nextSource {
    for (GetSource source in sources) {
      var src = source();
      if (src.count > 0) return src;
    }
    return null;
  }

  PowerCubeTarget get nextTarget {
    TargetSpec best = TargetSpec.nextTarget(targets);
    return best?.target();
  }
}

class TargetSpec {
  GetTarget target;
  int priority;
  int minMargin;
  int maxCount;

  TargetSpec(this.target,
      {this.priority = 1, this.minMargin = 1, this.maxCount = 100});

  bool get hasMax => target().cubeCount >= maxCount;

  int get marginDeficit => minMargin - target().pointMargin;

  static TargetSpec nextTarget(List<TargetSpec> specs) {
    specs.removeWhere((spec) => spec.hasMax);
    if (specs.isEmpty) {
      return null;
    }
    // assess risks
    // re-evaluate goals
    // goals:
    // levitate by 90 secs
    // overwhelming control of my switch until 60 sec
    // just-in-time my switch starting at 60 sec
    TargetSpec emergency = handleEmergency(specs);
    if (emergency != null) {
      return emergency;
    }
    return specs.reduce((spec1, spec2) => spec1.bestCubeCandidate(spec2));
  }

  static TargetSpec handleEmergency(List<TargetSpec> specs) {}

  TargetSpec bestCubeCandidate(TargetSpec other) {
    if (other.hasMax) {
      return this;
    }
    if (hasMax) {
      return other;
    }
    PowerCubeTarget me = target();
    PowerCubeTarget you = other.target();
    int myDeficit = marginDeficit;
    int yourDeficit = other.marginDeficit;
    print('My deficit: $myDeficit yours: $yourDeficit');
    if (myDeficit == 0 && yourDeficit > 0) {
      return other;
    }
    if (myDeficit == yourDeficit) {
      return priority > other.priority ? this : other;
    }
    return myDeficit < yourDeficit ? this : other;
  }
}

class GoalStrategy {
  List<TargetGoal> goals = [];

  GoalStrategy(this.goals);

  bool get hasSources {
    for (TargetGoal goal in goals) {
      if (goal.hasSources) {
        return true;
      }
    }
    return false;
  }

  FutureOr<bool> fetchCube(Robot robot) async {
    if (!robot.hasPowerCube) {
      SourceGoal goal = nextSourceGoal;
      if (goal != null) {
        var source = goal.item;
        print('Source $source : ${source.id(robot)}');
        bool success = await robot.getCube(source);
        return robot.hasPowerCube;
      }
    }
    return true;
  }

  FutureOr<bool> placeCube(Robot robot) async {
    if (robot.hasPowerCube) {
      TargetGoal goal = nextTargetGoal;
      if (goal != null) {
        var target = goal.item;
        print('Got nextTarget $target with id ${target.id(robot)}');
        return await robot.putCube(target);
      }
    }
    return true;
  }

  SourceGoal get nextSourceGoal {
    TargetGoal target = nextTargetGoal;
    if (target != null) {
      for (SourceGoal source in target.sources) {
        if (source.item.count > 0) return source;
      }
    }
    return null;
  }

  TargetGoal get nextTargetGoal {
//    TODO time
    var currentSeconds = 100;
    var applies =
        goals.where((goal) => goal.applies && goal.inTimeRange(currentSeconds));
    if (applies.isNotEmpty) {
      var atRisk = applies.where((goal) => goal.isAtRisk(currentSeconds));
      byPriority(TargetGoal prev, TargetGoal next) =>
          prev.priority >= next.priority ? prev : next;
      if (atRisk.isNotEmpty) {
        return atRisk.reduce(byPriority);
      }
      return atRisk.reduce(byPriority);
    }
    return null;
  }
}

class GoalBuilder {
  static GoalStrategy nearField(Alliance ally,
      {int vaultMargin: 3,
      vaultMax: 9,
      int switchMargin: 2,
      bool includeScale: false,
      int scaleMargin: 1,
      int scaleMax: 2}) {
    var switchGoal = getBalance(ally, ally.switch_, minMargin: switchMargin)
      ..priority = 10
      ..addSource(getSource(ally.switchSource))
      ..addSource(getSource(ally.allianceSource));
    var vaultGoal =
        new VaultGoal(() => ally.vault, maxCount: vaultMax..priority = 5)
          ..addSource(getSource(ally.allianceSource))
          ..addSource(getSource(ally.switchSource));
    List<Goal> targets = [switchGoal, vaultGoal];
    if (includeScale) {
      var scale = getBalance(ally, ally.match.scale,
          minMargin: scaleMargin, maxCount: scaleMax)
        ..priority = 1
        ..addSource(getSource(ally.oppositeAlliance.switchSource))
        ..addSource(getSource(ally.allianceSource));
      targets.add(scale);
    }
    return new GoalStrategy(targets);
  }

  static GoalStrategy midField(Alliance ally,
      {int switchMargin: 2, int scaleMargin: 1, int scaleMax: 2}) {
    var switchGoal =
        getBalance(ally, ally.switch_, minMargin: switchMargin, priority: 10)
          ..addSource(getSource(ally.switchSource))
          ..addSource(getSource(ally.allianceSource));
    var scaleGoal = getBalance(ally, ally.match.scale,
        minMargin: scaleMargin, maxCount: scaleMax, priority: 1)
      ..addSource(getSource(ally.oppositeAlliance.switchSource))
      ..addSource(getSource(ally.allianceSource));
    List<Goal> targets = [switchGoal, scaleGoal];
    return new GoalStrategy(targets);
  }

  static GoalStrategy farField(Alliance ally,
      {int switchMargin: 2, int scaleMargin: 1, int scaleMax: 2}) {
    var switchGoal = getBalance(ally, ally.oppositeAlliance.switch_,
        minMargin: switchMargin, priority: 10)
      ..addSource(getSource(ally.oppositeAlliance.switchSource))
//      TODO prefer the portal matching switch color
      ..addSource(getSource(ally.portalLeft))
      ..addSource(getSource(ally.portalRight));
    var scaleGoal = getBalance(ally, ally.match.scale,
        minMargin: scaleMargin, maxCount: scaleMax, priority: 1)
      ..addSource(getSource(ally.oppositeAlliance.switchSource))
      ..addSource(getSource(ally.portalLeft))
      ..addSource(getSource(ally.portalRight))
      ..addSource(getSource(ally.allianceSource));
    List<Goal> targets = [switchGoal, scaleGoal];
    return new GoalStrategy(targets);
  }

  static SourceGoal getSource(PowerCubeSource powerCubeSource) {
    return new SourceGoal(() => powerCubeSource);
  }

  static BalanceGoal getBalance(Alliance alliance, Balance balance,
      {int maxCount: 20, int minMargin: 2, int priority: 1}) {
    getPlate() => alliance.isRed ? balance.redPlate : balance.bluePlate;
    var goal =
        new BalanceGoal(getPlate, maxCount: maxCount, minMargin: minMargin);
    goal.priority = priority;
    return goal;
  }
}

abstract class Goal<T> {
  static const int END_SECONDS = 150;
  int startAt = 0;
  int endAt = END_SECONDS;

  T get item;

  bool get applies;

  bool inTimeRange(int currentSeconds) =>
      currentSeconds > startAt && endAt < currentSeconds;

  /// higher number => higher priority
  int priority = 1;

  /// seconds until the end of the match
  int timeLeft(int currentSeconds) {
    return END_SECONDS - currentSeconds;
  }

  /// seconds until end game phase
  int timeUntilClimb(int currentSeconds) {
    return END_SECONDS - 30 - currentSeconds;
  }
}

abstract class EndGameGoal extends Goal {
  // platform +5 , climb +30
}

abstract class TargetGoal<T extends PowerCubeTarget> extends Goal {
  bool isAtRisk(int currentSeconds);

  List<SourceGoal> sources = [];

  bool get hasSources {
    for (SourceGoal source in sources) {
      if (source.item.count > 0) return true;
    }
    return false;
  }

  void addSource(SourceGoal goal) => sources.add(goal);

}

class BalanceGoal extends TargetGoal<BalancePlate> {
  GetTarget target;
  int minMargin = 2;
  int maxCount = 20;

  bool isAtRisk(int currentSeconds) => item.pointMargin <= 1;

  BalancePlate get item => target();

  bool get applies => item.pointMargin <= maxCount;

  BalanceGoal(this.target, {this.maxCount: 20, this.minMargin: 2});
}

class VaultGoal extends Goal<Vault> {
  GetTarget target;
  bool hasRun = false;
  int maxCount = 3;

  List<SourceGoal> sources = [];

  void addSource(SourceGoal goal) => sources.add(goal);

  bool isAtRisk(int currentSeconds) =>
      (timeUntilClimb(currentSeconds) - (item.pointMargin * 15)) < 0;

  Vault get item => target();

  bool get applies => item.pointMargin <= maxCount;

  VaultGoal(this.target, {this.maxCount: 20});
}

class SourceGoal extends Goal<PowerCubeSource> {
  GetSource source;

  bool get applies => item.count > 0;

  PowerCubeSource get item => source();

  SourceGoal(this.source);
}
