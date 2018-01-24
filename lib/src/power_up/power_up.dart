import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../cube_operations/cube_operations.dart';
import '../field_diagram/field_diagram.dart';
import '../scoring/model.dart' as up;

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

  String get state => match.state.toString().split('.').last;

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

  xxx() {
    robot.alliance.switch_;
  }
}
