import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../../scoring/model.dart';
import '../gauge_component/gauge_component.dart';
import '../goal_list_component/goal_list_component.dart';
import '../robot_detail_component/robot_detail_component.dart';
import '../stored_data_component/stored_data_component.dart';
import '../../services/robot_service.dart';

@Component(
    selector: 'robot-component',
    templateUrl: 'robot_component.html',
    styleUrls: const [
      'robot_component.css'
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
class RobotComponent implements OnInit {

  final RobotService botz;

  @Input()
  Robot robot;

  bool showDetails = false;
  bool showMoreDetails = false;

//  TODO get values from robot
  int get ranking => robot.ranking;
  int get speed => robot.speed;
  int get agility => robot.agility;

  String get strategyLabel => robot.strategyLabel;

  @ViewChild(MaterialProgressComponent)
  MaterialProgressComponent progressBar;

  RobotComponent(this.botz) {
    rankLabelFunction =
        () => "'${robot.label}' ranks ${ranking}th percentile. Strategy: ${robot
        .strategyLabel}";
    rankClickFunction = (MouseEvent event) => setRanking(event);
    rankPercentileFunction = () => ranking;

    speedLabelFunction =
        () => "Speed and turning rank ${speed}th percentile.";
    speedClickFunction = (MouseEvent event) => setSpeed(event);
    speedPercentileFunction = () => speed;

    agilityLabelFunction =
        () => "Cube handling agility rank ${agility}th percentile.";
    agilityClickFunction = (MouseEvent event) => setAgility(event);
    agilityPercentileFunction = () => agility;
  }

  @override
  void ngOnInit() {}

  setRanking(MouseEvent event) {
    DivElement box = querySelector('#progressBox');
    Rectangle rect = box.getBoundingClientRect();
    Element div = event.target;
    robot.ranking = (((event.client.x - rect.left) / div.clientWidth) * 100).round();
  }

  setSpeed(MouseEvent event) {
    DivElement box = querySelector('#speedBox');
    Rectangle rect = box.getBoundingClientRect();
    Element div = event.target;
    robot.speed = (((event.client.x - rect.left) / div.clientWidth) * 100).round();
  }

  setAgility(MouseEvent event) {
    DivElement box = querySelector('#agilityBox');
    Rectangle rect = box.getBoundingClientRect();
    Element div = event.target;
    robot.agility = (((event.client.x - rect.left) / div.clientWidth) * 100).round();
  }

  LabelFunction rankLabelFunction;
  ClickFunction rankClickFunction;
  PercentileFunction rankPercentileFunction;

  LabelFunction speedLabelFunction;
  ClickFunction speedClickFunction;
  PercentileFunction speedPercentileFunction;

  LabelFunction agilityLabelFunction;
  ClickFunction agilityClickFunction;
  PercentileFunction agilityPercentileFunction;
}
