import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../../scoring/model.dart';
import '../../services/robot_service.dart';
import '../gauge_component/gauge_component.dart';
import '../goal_list_component/goal_list_component.dart';
import '../robot_detail_component/robot_detail_component.dart';
import '../stored_data_component/stored_data_component.dart';

@Component(
    selector: 'robot-detail-popup',
    templateUrl: 'robot_detail_popup.html',
    styleUrls: const [
      'robot_detail_popup.css'
    ],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialCheckboxComponent,
      ReorderListComponent,
      MaterialExpansionPanel,
      MaterialExpansionPanelSet,
      MaterialProgressComponent,
      MaterialToggleComponent,
      RobotDetailComponent,
      GoalListComponent,
      GaugeComponent,
      StoredDataComponent,
      MaterialTabComponent,
      MaterialTabPanelComponent,
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class RobotDetailPopup implements OnInit {
  final RobotService botz;

  @Input()
  Robot robot;

  int get speed => robot.speed;

  int get agility => robot.agility;

  RobotDetailPopup(this.botz) {
    speedLabelFunction = () => "Speed and turning rank ${speed}th percentile.";
    speedClickFunction = (MouseEvent event) => setSpeed(event);
    speedPercentileFunction = () => speed;

    agilityLabelFunction =
        () => "Cube handling agility rank ${agility}th percentile.";
    agilityClickFunction = (MouseEvent event) => setAgility(event);
    agilityPercentileFunction = () => agility;
  }

  @override
  void ngOnInit() {}

  setSpeed(MouseEvent event) {
    DivElement box = querySelector('#speedBox');
    Rectangle rect = box.getBoundingClientRect();
    Element div = event.target;
    robot.speed =
        (((event.client.x - rect.left) / div.clientWidth) * 100).round();
  }

  setAgility(MouseEvent event) {
    DivElement box = querySelector('#agilityBox');
    Rectangle rect = box.getBoundingClientRect();
    Element div = event.target;
    robot.agility =
        (((event.client.x - rect.left) / div.clientWidth) * 100).round();
  }

  LabelFunction speedLabelFunction;
  ClickFunction speedClickFunction;
  PercentileFunction speedPercentileFunction;

  LabelFunction agilityLabelFunction;
  ClickFunction agilityClickFunction;
  PercentileFunction agilityPercentileFunction;
}
