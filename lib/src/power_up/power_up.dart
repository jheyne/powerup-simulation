import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../cube_operations/cube_operations.dart';
import '../field_diagram/field_diagram.dart';
import '../scoring/autobot.dart';
import '../scoring/game_clock.dart';
import '../scoring/model.dart' as up;
import '../scoring/goal_spec.dart';
import '../utils/index_db_service.dart';
import '../editor/goal_component/goal_component.dart';
import '../editor/goal_list_component/goal_list_component.dart';
import '../editor/robot_component/robot_component.dart';
import '../page/main_page_component/main_page_component.dart';

@Component(
  selector: 'power-up',
  styleUrls: const ['power_up.css'],
  templateUrl: 'power_up.html',
  directives: const [
    CORE_DIRECTIVES,
    materialDirectives,
    MaterialButtonComponent,
    CubeOperations,
    FieldDiagram,
    GoalComponent,
    GoalListComponent,
    RobotComponent,
    MainPageComponent
  ],
  providers: const [],
)
class PowerUpComponent implements OnInit {
  up.Match match;
  up.Field field;
  up.Robot robot;
  IndexDbService _indexDbService;

  String get state => match.gameClock.state.toString().split('.').last;

  @ViewChild(FieldDiagram)
  FieldDiagram fieldDiagram;

  PowerUpComponent(this._indexDbService) {
    newMatch();
  }

  @override
  Future<Null> ngOnInit() async {
    newMatch();
    _indexDbService.open();
  }

  newMatch() {
    if (fieldDiagram != null) {
      fieldDiagram.resetRobots();
    }
    match = new up.Match();
    field = new up.Field(match);
    robot = new up.Robot(match.red, ()=>fieldDiagram);
    if (fieldDiagram != null) {
      fieldDiagram.addRobot(robot);
      fieldDiagram.ngAfterViewChecked();
    }
  }

  startAutoBot() {
    nearFieldAutoBot(match.blue);
//    midFieldAutoBot(match.blue);
//    farFieldAutoBot(match.blue);

    nearFieldAutoBot(match.red);
//    midFieldAutoBot(match.red);
//    farFieldAutoBot(match.red);

    fieldDiagram.placeRobots();
  }

  void nearFieldAutoBot(up.Alliance alliance) {
    up.Robot bot = new up.Robot(alliance, ()=>fieldDiagram)..label = 'near field';
    AutoBot autobot = AutoBotBuilder.sampleNearField(bot);
    registerRobot(bot, autobot, alliance);
  }

  void registerRobot(up.Robot bot, AutoBot autobot, up.Alliance alliance) {
    fieldDiagram.addRobot(bot);
    listen(State state) {
      switch (state) {
        case State.INIT:
          break;
        case State.AUTON:
          autobot.runAuto();
          break;
        case State.TELEOP:
          break;
        case State.DONE:
          break;
      }
    }

    alliance.match.gameClock.addStateChangeListener(listen);
    print(JSON.encode(bot.toJson()));
    print(autobot.toJson());
    print(JSON.encode(autobot.toJson()));
    print(autobot.description);
  }

  void midFieldAutoBot(up.Alliance alliance) {
    var bot = new up.Robot(alliance, ()=>fieldDiagram)..label = 'mid field';
    AutoBot autobot = AutoBotBuilder.sampleMidField(bot);
    registerRobot(bot, autobot, alliance);
  }

  void farFieldAutoBot(up.Alliance alliance) {
    var bot = new up.Robot(alliance, ()=>fieldDiagram)..label = 'far field';
    AutoBot autobot = AutoBotBuilder.sampleFarField(bot);
    registerRobot(bot, autobot, alliance);
  }

  List<GoalSpec> get specs => [selectedSpec, selectedSpec];

  GoalSpec selectedSpec = new GoalSpec()..fromJson({
    "startAt": 0,
    "endAt": 150,
    "type": "BalanceGoal",
    "goalType": "BalancePlate",
    "priority": 10,
    "sources": [
      "6 by my switch",
      "my stack of 10"
    ],
    "id": "my switch",
    "minMargin": 2,
    "maxCount": 20,
    "target": "my switch"
  });
}
