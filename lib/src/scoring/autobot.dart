import 'dart:async';

import 'model.dart';
import 'game_clock.dart';

//class AutoBot extends Robot {
//  AutoBot(Alliance alliance, LocationService locationService)
//      : super(alliance, locationService);
//}

class AutoBotBuilder {
  static AutoBot sampleNearField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies.add(GoalBuilder.nearField(robot.alliance,
        vaultMargin: 3, vaultMax: 3, switchMargin: 2, includeScale: true));
//    autoBot.strategies.add(StrategyBuilder.nearField(robot.alliance,
//        vaultMargin: 3, vaultMax: 3, switchMargin: 2, includeScale: true));
    return autoBot;
  }

  static AutoBot sampleMidField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies
        .add(GoalBuilder.midField(robot.alliance, switchMargin: 1));
//    .add(StrategyBuilder.midField(robot.alliance, switchMargin: 1));
    return autoBot;
  }
}

class AutoBot {
  Robot robot;

  List<GoalStrategy> strategies = [];

  AutoBot(this.robot);

  runAuto() async {
    for (GoalStrategy strategy in strategies) {
      await runStrategy(strategy);
    }
  }

  Future<bool> runStrategy(GoalStrategy goal) async {
    Completer<bool> completer = new Completer();
    print('about to start while');
    int count = 0;
    while (goal.hasSources && count++ < 100) {
      print('about to fetch cube count $count');
      bool hasCube = await goal.fetchCube(robot);
      if (!hasCube) {
        print('runStrategy completing because no cube');
        completer.complete(false);
        break;
      }
      print('about to place cube');
      await goal.placeCube(robot);
    }
    return completer.future;
  }

}


typedef PowerCubeTarget GetTarget();
typedef PowerCubeSource GetSource();

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
    print('about to fetch cube');
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
    print('about to nextSourceGoal');
    TargetGoal target = nextTargetGoal;
    print('target for nextSourceGoal is $target');
    if (target != null) {
      for (SourceGoal source in target.sources) {
        if (source.item.count > 0) return p(source);
      }
    }
    return null;
  }

  T p<T>(T t) {
    print(t);
    return t;
  }

  TargetGoal get nextTargetGoal {
    print('about to nextTargetGoal');
    int currentSeconds = GameClock.instance.currentSecond;
    var applies =
        goals.where((goal) => goal.applies && goal.inTimeRange(currentSeconds));
    print('applies $applies');
    if (applies.isNotEmpty) {
      var atRisk = applies.where((goal) => goal.isAtRisk(currentSeconds));
      byPriority(TargetGoal prev, TargetGoal next) {
        print('byPriority $prev, $next');
        return prev.priority >= next.priority ? prev : next;
      }

      if (atRisk.isNotEmpty) {
        return p(atRisk.reduce(byPriority));
      }
      return p(applies.reduce(byPriority));
    }
    print('return null');
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
    var vaultGoal = new VaultGoal(() => ally.vault, maxCount: vaultMax)
      ..priority = 5
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

  bool inTimeRange(int currentSeconds) => true;

//  TODO
//      currentSeconds > startAt && endAt < currentSeconds;

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
