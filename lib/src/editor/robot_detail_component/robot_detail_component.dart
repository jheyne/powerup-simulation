import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../../scoring/model.dart';

@Component(
    selector: 'robot-detail-component',
    templateUrl: 'robot_detail_component.html',
    styleUrls: const ['robot_detail_component.css'],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialCheckboxComponent,
      ReorderListComponent,
      MaterialExpansionPanel,
      MaterialExpansionPanelSet,
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class RobotDetailComponent implements OnInit {

  @Input()
  Robot robot;

  RobotDetailComponent();

  @override
  void ngOnInit() {}

  xxxx() {
//    robot.runtimeType.travelSpeedRange.asLabel;
  }
}
