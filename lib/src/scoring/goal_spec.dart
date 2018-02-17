import 'autobot.dart';
import 'model.dart' as up;
import 'package:power_up_2018/src/services/index_db_service.dart';

class GoalSpec {
  String id = '';
  int startAt = 0;

  String get startAtStr => '$startAt';

  void set startAtStr(String input) => startAt = parse(input, startAt);
  int endAt = 150;

  String get endAtStr => '$endAt';

  void set endAtStr(String input) => endAt = parse(input, endAt);
  int priority = 1;

  String get priorityStr => '$priority';

  void set priorityStr(String input) => priority = parse(input, priority);

  /// list of source ids
  List<String> sources = [];

  /// for Balance
  int minMargin = 2;

  String get minMarginStr => '$minMargin';

  void set minMarginStr(String input) => minMargin = parse(input, minMargin);

  /// for Balance, Vault
  int maxCount = 20;

  String get maxCountStr => '$maxCount';

  void set maxCountStr(String input) => maxCount = parse(input, maxCount);

  int parse(String input, int existing) {
    try {
      return int.parse(input);
    } catch (e) {
      return existing;
    }
  }

  bool get isVault => id.contains('vault');

  bool get isScale => id.contains('scale');

  bool get isSwitch => id.contains('switch');

  bool get isBalance => isSwitch || isScale;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = id;
    json['startAt'] = startAt;
    json['endAt'] = endAt;
    json['sources'] = sources;
    json['minMargin'] = minMargin;
    json['maxCount'] = maxCount;
    return json;
  }

  fromJson(Map<String, dynamic> json, [bool isRed = true]) {
    id = json['id'] ?? json['target'];
    if (id == 'top-switch') {
      id = 'opposite switch';
    } else if (id == 'bottom-switch') {
      id = 'my switch';
    } else if (id.contains('vault')) {
      id = 'vault';
    }
    startAt = json['startAt'];
    endAt = json['endAt'];
    priority = json['priority'];
    final List<String> convertedSources = [];
    for (String source in json['sources'] ?? []) {
      convertedSources.add(convertSourceId(source, isRed));
    }
    sources = convertedSources;
    minMargin = json['minMargin'];
    maxCount = json['maxCount'];
  }

  /// converting from obsolete models
  @deprecated
  String convertSourceId(String id, bool isRed) {
    if(id == 'portal-red-right') return 'portal right';
    if(id == 'portal-red-left') return 'portal left';
    if(id == 'blue-6-source') return !isRed ? '6 by my switch' : '6 by opposite switch';
    if(id == 'portal-blue-right') return 'portal right';
    if(id == 'portal-blue-left') return 'portal left';

    if(id == 'red-6-source') return isRed ? '6 by my switch' : '6 by opposite switch';
    if(id == 'red-10-source') return 'my stack of 10';
    if(id == 'blue-10-source') return 'my stack of 10';
    return id;
  }

  String get description {
    up.Match match = new up.Match();
    return GoalFactory
        .createGoal(this, new up.Robot(match.red, null))
        .description;
  }
}

class Strategy implements Persistable {
  String label = 'unnamed';
  List<GoalSpec> goalSpecs = [];
  String dbKey;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    List<Map<String, dynamic>> list = [];
    for (GoalSpec goal in goalSpecs) {
      list.add(goal.toJson());
    }
    json['label'] = label;
    json['dbKey'] = dbKey;
    json['goalSpecs'] = list;
    return json;
  }

  void fromJson(Map<String, dynamic> json) {
    label = json['label'] ?? 'unnamed';
    dbKey = json['dbKey'];
    goalSpecs.clear();
    List<Map<String, dynamic>> _goals = json['goalSpecs'] ?? [];
    for (Map<String, dynamic> goal in _goals) {
      goalSpecs.add(new GoalSpec()..fromJson(goal));
    }
  }
}

class GoalFactory {
  static Goal createGoal(GoalSpec spec, up.Robot robot) {
    if (spec.id == null || spec.id == '') {
      spec.id = 'my switch';
    }
    if (spec.isVault) {
      return createVault(spec, robot);
    } else if (spec.isScale) {
      return createScale(spec, robot);
    } else if (spec.isSwitch) {
      return createSwitch(spec, robot);
    }
    print('Unknown goal spec id: ${spec.id}');
    throw spec;
  }

  static Goal createSwitch(GoalSpec spec, up.Robot robot) {
    var alliance = robot.alliance;
    target() {
      up.Balance aSwitch =
          ((spec.id.contains('bottom') || spec.id.contains('my')) &&
                  robot.isRed)
              ? alliance.switch_
              : alliance.oppositeAlliance.switch_;
      return alliance.isRed ? aSwitch.redPlate : aSwitch.bluePlate;
    }

    var goal = new BalanceGoal(target)..maxCount = spec.maxCount;
    _populateSharedValues(goal, spec, alliance);
    return goal;
  }

  static Goal createScale(GoalSpec spec, up.Robot robot) {
    var alliance = robot.alliance;
    var target = alliance.match.scale;
    var goal = new BalanceGoal(() => alliance.isRed
        ? target.redPlate
        : target.bluePlate)
      ..maxCount = spec.maxCount
      ..minMargin = spec.minMargin;
    _populateSharedValues(goal, spec, alliance);
    return goal;
  }

  static Goal createVault(GoalSpec spec, up.Robot robot) {
    var alliance = robot.alliance;
    var target =
        alliance.isRed ? alliance.vault : alliance.oppositeAlliance.vault;
    var goal = new VaultGoal(() => target)..maxCount = spec.maxCount;
    _populateSharedValues(goal, spec, alliance);
    return goal;
  }

  static void _populateSharedValues(
      TargetGoal goal, GoalSpec spec, up.Alliance alliance) {
    goal
      ..priority = spec.priority ?? 1
      ..startAt = spec.startAt
      ..endAt = spec.endAt;
    for (String source in spec.sources) {
      goal.sources.add(new SourceGoal(getSource(source, alliance)));
    }
  }

  static GetSource getSource(String id, up.Alliance alliance) {
    const sourceList = const [
      'portal left',
      'portal right',
      '6 by my switch',
      '6 by opposite switch',
      'my stack of 10'
    ];
    up.PowerCubeSource cubeSource = null;
    if (id.contains('6')) {
      cubeSource = id.contains('my')
          ? alliance.allianceSource
          : alliance.oppositeAlliance.allianceSource;
    } else if (id.contains('10')) {
      cubeSource = alliance.switchSource;
    } else
    if (id.contains('portal')) {
      if (id.contains('left')) {
        cubeSource =
            alliance.isRed ? alliance.portalLeft : alliance.portalRight;
      } else {
        cubeSource =
            alliance.isRed ? alliance.portalRight : alliance.portalLeft;
      }
    }
    return () => cubeSource;
  }
}
