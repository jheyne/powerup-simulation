import 'dart:async';

import 'game_clock.dart';
import 'goal_spec.dart';
import 'model.dart';

class AutoBot {
  Robot robot;

  List<GoalStrategy> strategies = [];

  GoalStrategy get consolidatedStrategy {
    if (strategies.length == 1) {
      return strategies.first;
    }
    final List<TargetGoal> goals = [];
    for (GoalStrategy strategy in strategies) {
      goals.addAll(strategy.goals);
    }
    return new GoalStrategy(goals)..label = 'Combined';
  }

  AutoBot(this.robot) {
    List<TargetGoal> goals = [];
    for (GoalSpec spec in robot.strategy.goalSpecs) {
      print('Robot: ${robot.label}');
      print('Spec: ${spec.toJson()}');
      var goal = GoalFactory.createGoal(spec, robot);
      print('Goal: ${goal.toJson()}');
      goals.add(goal);
    }
    GoalStrategy strategy = new GoalStrategy(goals);
    strategy.label = robot.strategy.label;
    strategies.add(strategy);
  }

  runAuto() {
    if (robot.preloadFromVault) {
      robot.hasPowerCube = true;
      if (randomInstance.nextBool()) {
        robot.alliance.portalRight.count--;
      } else {
        robot.alliance.portalLeft.count--;
      }
    }
    _runStrategy(consolidatedStrategy, 0);
  }

  bool cancelled = false;

  FutureOr<bool> _runStrategy(GoalStrategy goal, final int count) async {
    int waitMilliseconds = 10;
    int counterIncrement = 1;
    if (cancelled) return false;
    if (robot.hasPowerCube) {
      print('${robot.label} place cube: ${count}');
      await goal.placeCube(robot);
    } else {
      if (goal.hasSources) {
        print('${robot.label} fetch cube: ${count}');
        try {
          await goal.fetchCube(robot);
        } catch (NO_SOURCE_GOAL) {
          if (!robot.alliance.match.gameClock.isDone) {
            /// if the game is not done, wait to see if something becomes available
            waitMilliseconds = 500;
            counterIncrement = 0;
          } else {
            return false;
          }
        }
      } else {
        // do defense
        print('${robot.label} do defense: ${count}');
        return false;
      }
    }
    new Timer(new Duration(milliseconds: waitMilliseconds),
        () => _runStrategy(goal, count + counterIncrement));
    return true;
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

final NO_SOURCE_GOAL = 'No source goal';

/// Virtualizes accessing cube targets
typedef PowerCubeTarget GetTarget();

/// Virtualizes accessing cube sources
typedef PowerCubeSource GetSource();

/// Encapsulates a named list of goals
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
      SourceGoal goal = _nextSourceGoal;
      if (goal != null) {
        var source = goal.item;
        await robot.getCube(source);
        return robot.hasPowerCube;
      } else {
        print('Robot ${robot.label} has no more source goals');
        throw NO_SOURCE_GOAL;
      }
    }
    return true;
  }

  FutureOr<bool> placeCube(Robot robot) async {
    if (robot.hasPowerCube) {
      TargetGoal goal = _nextTargetGoal;
      if (goal != null) {
        var target = goal.item;
        return await robot.putCube(target);
      } else {
        print('${robot.label} has no place to put its cube');
        // avoid looping
        robot.hasPowerCube = false;
      }
    }
    return true;
  }

  SourceGoal get _nextSourceGoal {
    TargetGoal target = _nextTargetGoal;
    if (target != null) {
      for (SourceGoal source in target.sources) {
        if (source.item.count > 0) return source;
      }
    }
    return null;
  }

  T p<T>(T t) {
    print(t);
    return t;
  }

  TargetGoal get _nextTargetGoal {
    int currentSeconds = GameClock.instance.currentSecond;
    var applies = goals.where((goal) =>
        goal.hasSources && goal.applies && goal.inTimeRange(currentSeconds));
    print('Applies: $applies');
    if (applies.isNotEmpty) {
      var atRisk = applies.where((goal) => goal.isAtRisk(currentSeconds));
      byPriority(TargetGoal prev, TargetGoal next) {
        return prev.priority >= next.priority ? prev : next;
      }

      if (atRisk.isNotEmpty) {
        return atRisk.reduce(byPriority);
      }
      return applies.reduce(byPriority);
    }
    return null;
  }
}

abstract class Goal<T> {
  static const int END_SECONDS = 150;
  int startAt = 0;
  int endAt = END_SECONDS;

  T get item;

  bool get applies;

  bool inTimeRange(int currentSeconds) {
    return startAt <= currentSeconds && currentSeconds <= endAt;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['startAt'] = startAt;
    json['endAt'] = endAt;
    json['type'] = runtimeType.toString();
    json['goalType'] = item.runtimeType.toString();
    json['priority'] = priority ?? 1;
    _buildJson(json);
    return json;
  }

  String get description {
    List<String> phrases = [];
    buildDescription(phrases);
    return _normalizeColorReferences(phrases).join(' ');
  }

  List<String> _normalizeColorReferences(List<String> phrases) {
    List<String> normalized = [];
    for (String string in phrases) {
      normalized.add(string
          .replaceAll('red-', 'myAlliance-')
          .replaceAll('blue-', 'oppositeAlliance-'));
    }
    return normalized;
  }

  buildDescription(phrases) {
    phrases
        .add('Between $startAt and $endAt seconds (with priority $priority)');
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

class EndGameGoal extends Goal implements HasId {
  int pointCount;
  String _id;
  bool isPlatform;

  EndGameGoal(this.pointCount, this._id, this.isPlatform);

  List<String> id(Robot robot) => [basicId];

  String get basicId => _id;

  void set basicId(String id) => _id = id;

  bool get applies => true;

  get item => this;

  void _buildJson(Map<String, dynamic> json) {
    isPlatform ? json['platform'] = _id : json['climb'] = _id;
  }

  void _buildDescription(List<String> phrases) =>
      phrases.add(isPlatform ? 'go to platform.' : 'climb');

//  TODO EndGameGoal
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

  bool get applies => item.pointMargin < maxCount;

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

  bool get applies => item.pointMargin < maxCount;

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
