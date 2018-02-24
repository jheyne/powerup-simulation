import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';

import '../cube_operations/cube_operations.dart';
import '../editor/goal_component/goal_component.dart';
import '../editor/goal_list_component/goal_list_component.dart';
import '../editor/robot_component/robot_component.dart';
import '../field_diagram/field_diagram.dart';
import '../page/main_page_component/main_page_component.dart';
import '../scoring/autobot.dart';
import '../scoring/game_clock.dart';
import '../scoring/model.dart' as up;
import '../services/dialog_service.dart';
import '../services/robot_service.dart';

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
class PowerUpComponent implements OnInit, CanDeactivate {
  static PowerUpComponent myInstance = null;

  final RobotService botz;
  final DialogService dialogService;

  up.Match get match => botz.match;

  up.Field get field => botz.field;

  up.Robot get robot => botz.robotRed1;

  String get state => match.gameClock.state.toString().split('.').last;

  @ViewChild(FieldDiagram)
  FieldDiagram fieldDiagram;
  bool hasInitialized = false;

  factory PowerUpComponent(RobotService botz, DialogService dialogService) {
    if (myInstance == null) {
      myInstance = new PowerUpComponent._internal(botz, dialogService);
    }
    return myInstance;
  }

  PowerUpComponent._internal(this.botz, this.dialogService);

  @override
  Future<Null> ngOnInit() async {
    botz.locationSupplier = () => fieldDiagram;
    if (!hasInitialized) {
      print('Init POWER UP');
      initializeMatch();
//      hasInitialized = true;
    }
  }

  newMatch() {
    print('power_up.newMatch');
    fieldDiagram.resetRobots();
    botz.newMatch();
    initializeMatch();
  }

  void initializeMatch() {
    fieldDiagram.resetRobots();
    for (up.Robot robot in botz.robots) {
      fieldDiagram.addRobot(robot);
    }
    fieldDiagram.placeRobots();
    fieldDiagram.initializeScaleAndSwitches();
  }

  replay() {

  }

  startAutoBot() {
    print('power_up.startAutoBot manual drive is ${botz.manualDriveRed1}');
    List<up.Robot> bots = botz.robots;
    if (botz.manualDriveRed1) {
      bots.remove(botz.robotRed1);
    }
    for (up.Robot robot in bots) {
      registerAutobot(new AutoBot(robot));
    }
    match.gameClock.start();
  }

  void registerAutobot(AutoBot autobot) {
    listen(State state) {
      switch (state) {
        case State.INIT:
          break;
        case State.AUTON:
          print('${autobot.robot.label} is starting auton');
          autobot.runAuto();
          break;
        case State.TELEOP:
          break;
        case State.DONE:
          print('out of time for ${autobot.robot.label}');
          autobot.cancelled = true;
          break;
      }
    }

    print('addStateChangeListener ${autobot.robot.label}');
    autobot.robot.alliance.match.gameClock.addStateChangeListener(listen);
  }

  levitate() {
    var v = robot.alliance.vault;
    v.levitate.count = 3;
    v.levitate.trigger();
  }

  boost(int cubesToUse) {
    var v = robot.alliance.vault;
    v.boost.count = cubesToUse;
    v.boost.trigger();
  }

  force(int cubesToUse) {
    var v = robot.alliance.vault;
    v.force.count = cubesToUse;
    v.force.trigger();
  }

  @override
  FutureOr<bool> routerCanDeactivate(next, prev) => match.gameClock.isGameActive
      ? dialogService.confirm('Leaving this page will stop the simulation!')
      : true as FutureOr<bool>;
}
