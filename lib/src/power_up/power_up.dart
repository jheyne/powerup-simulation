import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../cube_operations/cube_operations.dart';
import '../field_diagram/field_diagram.dart';
import '../scoring/model.dart' as up;
import '../scoring/autobot.dart';

@Component(
  selector: 'power-up',
  styleUrls: const ['power_up.css'],
  templateUrl: 'power_up.html',
  directives: const [
    CORE_DIRECTIVES,
    materialDirectives,
    MaterialButtonComponent,
    CubeOperations,
    FieldDiagram
  ],
  providers: const [],
)
class PowerUpComponent implements OnInit {
  up.Match match;
  up.Field field;
  up.Robot robot;

  String get state => match.gameClock.state.toString().split('.').last;

  @ViewChild(FieldDiagram)
  FieldDiagram fieldDiagram;

  PowerUpComponent() {
    newMatch();
  }

  @override
  Future<Null> ngOnInit() async {
    newMatch();
  }

  newMatch() {
    if (fieldDiagram != null) {
      fieldDiagram.resetRobots();
    }
    match = new up.Match();
    field = new up.Field(match);
    robot = new up.Robot(match.red, fieldDiagram);
    if (fieldDiagram != null) {
      fieldDiagram.addRobot(robot);
      fieldDiagram.ngAfterViewChecked();
    }
  }

  startAutoBot() {
    nearFieldAutoBot();
    midFieldAutoBot();
  }

  void nearFieldAutoBot() {
    var bot = new up.Robot(match.blue, fieldDiagram);
    AutoBot autobot = AutoBotBuilder.sampleNearField(bot);
    fieldDiagram.addRobot(bot);
    print(autobot);
    autobot.runAuto();
  }

  void midFieldAutoBot() {
    var bot = new up.Robot(match.blue, fieldDiagram);
    AutoBot autobot = AutoBotBuilder.sampleMidField(bot);
    fieldDiagram.addRobot(bot);
    print(autobot);
    autobot.runAuto();
  }
}
