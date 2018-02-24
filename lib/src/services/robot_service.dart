import 'dart:math';

import "package:angular/angular.dart";

import '../scoring/goal_spec.dart';
import '../scoring/model.dart' as up;

enum Zone { Near, Mid, Far }

typedef up.LocationService LocationSupplier();

@Directive(selector: '[robot-service]')
@Injectable()
class RobotService {
  Random random = new Random();

  LocationSupplier _locationSupplier;

  LocationSupplier get locationSupplier => _locationSupplier;

  void set locationSupplier(LocationSupplier supplier) {
    _locationSupplier = supplier;
    robotRed1.hasLocationService = supplier;
    robotRed2.hasLocationService = supplier;
    robotRed3.hasLocationService = supplier;
    robotBlue1.hasLocationService = supplier;
    robotBlue2.hasLocationService = supplier;
    robotBlue3.hasLocationService = supplier;
  }

  bool manualDriveRed1 = false;

  up.Match match;
  up.Field field;
  up.Robot robotRed1;
  up.Robot robotRed2;
  up.Robot robotRed3;
  up.Robot robotBlue1;
  up.Robot robotBlue2;
  up.Robot robotBlue3;

  List<up.Robot> get robots =>
      [robotRed1, robotRed2, robotRed3, robotBlue1, robotBlue2, robotBlue3];

  List<up.Robot> get ones => [robotRed1, robotBlue1];

  List<up.Robot> get twos => [
        robotRed2,
        robotBlue2,
      ];

  List<up.Robot> get threes => [robotRed3, robotBlue3];

  RobotService() {
    newMatch();
  }

  void newMatch() {
    match = new up.Match();
    field = new up.Field(match);
    robotRed1 = buildBot(match.red, Zone.Near)..label = 'Red 1';
    robotRed2 = buildBot(match.red, Zone.Mid)..label = 'Red 2';
    robotRed3 = buildBot(match.red, Zone.Far)..label = 'Red 3';
    robotBlue1 = buildBot(match.blue, Zone.Near)..label = 'Blue 1';
    robotBlue2 = buildBot(match.blue, Zone.Mid)..label = 'Blue 2';
    robotBlue3 = buildBot(match.blue, Zone.Far)..label = 'Blue 3';
    match.gameClock.reset();
  }

  up.Robot buildBot(up.Alliance alliance, Zone zone) {
    up.Robot robot = new up.Robot(alliance, locationSupplier);
    buildSpecs(robot, zone);
    adjustCapability(robot);
    return robot;
  }

  adjustCapability(up.Robot robot) {
    robot.ranking = random.nextInt(100);
  }

  buildSpecs(up.Robot robot, zone) {
    Map<String, dynamic> map = {};
    if (zone == Zone.Near) {
      map = nearFieldSample;
    } else if (zone == Zone.Mid) {
      map = midFieldSample;
    } else {
      map = farFieldSample;
    }
    List<Map<String, dynamic>> specs = map['goalSpecs'];
    for (Map<String, dynamic> spec in specs) {
      robot.goalSpecs.add(new GoalSpec()..fromJson(spec));
    }
    robot.strategyLabel = map['label'];
  }

  final Map<String, dynamic> nearFieldSample = {
    "label": "near field",
    "dbKey": 1,
    "goalSpecs": [
      {
        "id": "my switch",
        "startAt": 0,
        "endAt": 15,
        "sources": ["my stack of 10"],
        "minMargin": 0,
        "maxCount": 1
      },
      {
        "id": "my switch",
        "startAt": 15,
        "endAt": 150,
        "sources": ["6 by my switch", "my stack of 10"],
        "minMargin": 2,
        "maxCount": 20
      },
      {
        "id": "vault",
        "startAt": 15,
        "endAt": 150,
        "sources": [
          "my stack of 10",
          "6 by my switch",
          "portal right",
          "portal left"
        ],
        "minMargin": null,
        "maxCount": 5
      }
    ]
  };

  final Map<String, dynamic> midFieldSample = {
    "label": "mid field",
    "dbKey": 1,
    "goalSpecs": [
      {
        "id": "my switch",
        "startAt": 15,
        "endAt": 150,
        "sources": ["6 by my switch", "my stack of 10"],
        "minMargin": 2,
        "maxCount": 20
      },
      {
        "id": "scale",
        "startAt": 15,
        "endAt": 150,
        "sources": ["6 by opposite switch", "my stack of 10"],
        "minMargin": 2,
        "maxCount": 2
      },
      {
        "id": "vault",
        "startAt": 15,
        "endAt": 150,
        "sources": [
          "my stack of 10",
          "6 by my switch",
          "portal left",
          "portal right",
          "6 by opposite switch"
        ],
        "minMargin": null,
        "maxCount": 5
      },
      {
        "id": "my switch",
        "startAt": 0,
        "endAt": 15,
        "sources": ["my stack of 10"],
        "minMargin": 0,
        "maxCount": 1
      }
    ]
  };

  final Map<String, dynamic> farFieldSample = {
    "label": "far field",
    "dbKey": 3,
    "goalSpecs": [
      {
        "id": "scale",
        "startAt": 0,
        "endAt": 15,
        "sources": ["6 by my switch"],
        "minMargin": 0,
        "maxCount": 1
      },
      {
        "id": "opposite switch",
        "startAt": 15,
        "endAt": 150,
        "sources": ["6 by opposite switch", "portal left", "portal right"],
        "minMargin": 2,
        "maxCount": 20
      },
      {
        "id": "scale",
        "startAt": 15,
        "endAt": 150,
        "sources": [
          "6 by opposite switch",
          "portal left",
          "portal right",
          "6 by my switch",
          "my stack of 10"
        ],
        "minMargin": 2,
        "maxCount": 2
      }
    ]
  };
}
