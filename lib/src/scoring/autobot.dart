import 'dart:async';

import 'game_clock.dart';
import 'model.dart';

//class AutoBot extends Robot {
//  AutoBot(Alliance alliance, LocationService locationService)
//      : super(alliance, locationService);
//}

class AutoBotBuilder {
  static AutoBot sampleNearField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies.add(GoalBuilder.nearField(robot.alliance,
        vaultMargin: 3, vaultMax: 3, switchMargin: 2, includeScale: true));
    return autoBot;
  }

  static AutoBot sampleMidField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies
        .add(GoalBuilder.midField(robot.alliance, switchMargin: 1));
    return autoBot;
  }

  static AutoBot sampleFarField(Robot robot) {
    AutoBot autoBot = new AutoBot(robot);
    autoBot.strategies
        .add(GoalBuilder.farField(robot.alliance, switchMargin: 1));
    return autoBot;
  }
}

class AutoBot {
  Robot robot;

  List<GoalStrategy> strategies = [];

  AutoBot(this.robot);

  runAuto() async {
    for (GoalStrategy strategy in strategies) {
      print('Running strategy: $strategy');
      await runStrategy(strategy);
    }
  }

  Future<bool> runStrategy(GoalStrategy goal) async {
    Completer<bool> completer = new Completer();
    if (!(goal is GoalStrategy)) {
      print('GoalStrategy is unexpected: ${goal.runtimeType}');
    }
    while (goal != null && goal.hasSources) {
      if (!GameClock.instance.isGameActive) {
        completer.complete(false);
      }
      await goal.fetchCube(robot);
      if (!GameClock.instance.isGameActive) {
        completer.complete(false);
      }
      if (robot.hasPowerCube) {
        await goal.placeCube(robot);
      }
    }
    return completer.future;
  }

  List<Map<String, dynamic>> toJson() {
    List<Map<String, dynamic>> list = [];
    for (GoalStrategy strategy in strategies) {
      list.add(strategy.toJson());
    }
    return list;
  }

  String get description {
    List<String> list = [];
    for (GoalStrategy strategy in strategies) {
      list.add(strategy.description);
    }
    return list.join('\n\n');
  }
}

typedef PowerCubeTarget GetTarget();
typedef PowerCubeSource GetSource();

class GoalStrategy {
  String label = "nameless";

  List<TargetGoal> goals = [];

  GoalStrategy(this.goals);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    List<Map<String, dynamic>> list = [];
    for (TargetGoal goal in goals) {
      list.add(goal.toJson());
    }
    json['label'] = label;
    json['goals'] = list;
    return json;
  }

  String get description {
    List<String> descriptions = [];
    for (TargetGoal goal in goals) {
      descriptions.add(goal.description);
    }
    return descriptions.join('\n');
  }

  bool get hasSources {
    for (TargetGoal goal in goals) {
      if (!(goal is TargetGoal)) {
        print('TargetGoal is unexpected: ${goal.runtimeType}');
      }
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
        await robot.getCube(source);
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
        return await robot.putCube(target);
      }
    }
    return true;
  }

  SourceGoal get nextSourceGoal {
    TargetGoal target = nextTargetGoal;
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
    int currentSeconds = GameClock.instance.currentSecond;
    var applies =
        goals.where((goal) => goal.applies && goal.inTimeRange(currentSeconds));
    if (applies.isNotEmpty) {
      var atRisk = applies.where((goal) => goal.isAtRisk(currentSeconds));
      byPriority(TargetGoal prev, TargetGoal next) {
        return prev.priority >= next.priority ? prev : next;
      }

      if (atRisk.isNotEmpty) {
        return p(atRisk.reduce(byPriority));
      }
      return p(applies.reduce(byPriority));
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
    var vaultGoal = new VaultGoal(() => ally.vault, maxCount: vaultMax)
      ..priority = 5
      ..addSource(getSource(ally.allianceSource))
      ..addSource(getSource(ally.switchSource))
      ..addSource(getSource(ally.portalRight))
      ..addSource(getSource(ally.portalLeft));
    List<Goal> targets = [switchGoal, vaultGoal];
    if (includeScale) {
      var scale = getBalance(ally, ally.match.scale,
          minMargin: scaleMargin, maxCount: scaleMax)
        ..priority = 1
        ..addSource(getSource(ally.oppositeAlliance.switchSource))
        ..addSource(getSource(ally.allianceSource));
      targets.add(scale);
    }
    return new GoalStrategy(targets)..label = 'near field';
  }

  static GoalStrategy midField(Alliance ally,
      {int switchMargin: 2,
      int scaleMargin: 1,
      int scaleMax: 2,
      int vaultMargin: 3,
      vaultMax: 9}) {
    var switchGoal =
        getBalance(ally, ally.switch_, minMargin: switchMargin, priority: 10)
          ..addSource(getSource(ally.switchSource))
          ..addSource(getSource(ally.allianceSource));
    var scaleGoal = getBalance(ally, ally.match.scale,
        minMargin: scaleMargin, maxCount: scaleMax, priority: 5)
      ..addSource(getSource(ally.oppositeAlliance.switchSource))
      ..addSource(getSource(ally.allianceSource));
    var vaultGoal = new VaultGoal(() => ally.vault, maxCount: vaultMax)
      ..priority = 1
      ..addSource(getSource(ally.allianceSource))
      ..addSource(getSource(ally.switchSource));
    List<Goal> targets = [switchGoal, scaleGoal, vaultGoal];
    return new GoalStrategy(targets)..label = 'mid field';
  }

  static GoalStrategy farField(Alliance ally,
      {int switchMargin: 2, int scaleMargin: 1, int scaleMax: 2}) {
    var switchGoal = getBalance(ally, ally.oppositeAlliance.switch_,
        minMargin: switchMargin, priority: 1)
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
    return new GoalStrategy(targets)..label = "far field";
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

  bool inTimeRange(int currentSeconds) {
    print('inTimeRange: $currentSeconds start: $startAt end: $endAt');
    return startAt <= currentSeconds && currentSeconds <= endAt;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['startAt'] = startAt;
    json['endAt'] = endAt;
    json['type'] = runtimeType.toString();
    json['goalType'] = item.runtimeType.toString();
    json['priority'] = priority;
    _buildJson(json);
    return json;
  }

  String get description {
    List<String> phrases = [];
    buildDescription(phrases);
    return normalizeColorReferences(phrases).join(' ');
  }

  List<String> normalizeColorReferences(List<String> phrases) {
    List<String> normalized = [];
    for (String string in phrases) {
      normalized.add(string
          .replaceAll('red-', 'myAlliance-')
          .replaceAll('blue-', 'oppositeAlliance-'));
    }
    return normalized;
  }

  buildDescription(phrases) {
    phrases.add('Between $startAt and $endAt seconds (with priority $priority)');
    _buildDescription(phrases);
  }

  _buildDescription(List<String> phrases);

  void _buildJson(Map<String, dynamic> json);

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

  void _buildJson(Map<String, dynamic> json) {
    List<String> sourceNames = [];
    for (SourceGoal source in sources) {
      sourceNames.add(source.item.basicId);
    }
    json['sources'] = sourceNames;
    _buildJson_(json);
  }

  void _buildJson_(Map<String, dynamic> json);

  _buildDescription(List<String> phrases) {
    _buildDescription_(phrases);
    List<String> sourceNames = [];
    for (SourceGoal source in sources) {
      sourceNames.add(source.item.basicId);
    }
    phrases.add('Fetch cubes from ${sourceNames.join(" and ")}.');
  }

  _buildDescription_(List<String> phrases);
}

class BalanceGoal extends TargetGoal<BalancePlate> {
  GetTarget target;
  int minMargin = 2;
  int maxCount = 20;

  bool isAtRisk(int currentSeconds) => item.pointMargin <= 1;

  BalancePlate get item => target();

  bool get applies => item.pointMargin <= maxCount;

  BalanceGoal(this.target, {this.maxCount: 20, this.minMargin: 2});

  void _buildJson_(Map<String, dynamic> json) {
    json['id'] = item.basicId;
    json['minMargin'] = minMargin;
    json['maxCount'] = maxCount;
    json['target'] = target().basicId;
  }

  _buildDescription_(List<String> phrases) {
    phrases.add('place up to $maxCount cubes in ${item.basicId}');
    phrases.add("attempting to exceed opponent's cubes by $minMargin.");
  }
}

class VaultGoal extends TargetGoal<Vault> {
  GetTarget target;
  bool hasRun = false;
  int maxCount = 3;

  bool isAtRisk(int currentSeconds) =>
      (timeUntilClimb(currentSeconds) - (item.pointMargin * 15)) < 0;

  Vault get item => target();

  bool get applies => item.pointMargin <= maxCount;

  VaultGoal(this.target, {this.maxCount: 9});

  void _buildJson_(Map<String, dynamic> json) {
    json['id'] = item.basicId;
    json['maxCount'] = maxCount;
    json['target'] = item.basicId;
  }

  _buildDescription_(List<String> phrases) {
    phrases.add('place up to $maxCount cubes in ${item.basicId}.');
  }
}

class SourceGoal extends Goal<PowerCubeSource> {
  GetSource source;

  bool get applies => item.count > 0;

  PowerCubeSource get item => source();

  SourceGoal(this.source);

  void _buildJson(Map<String, dynamic> json) {
    json['source'] = item.basicId;
  }

  _buildDescription(List<String> phrases) {
    phrases.add('fetch from ${item.basicId}');
  }
}
