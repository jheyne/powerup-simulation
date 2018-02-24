import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import '../../editor/robot_summary_component/robot_summary_component.dart';

import '../../scoring/model.dart' as up;

@Component(
  selector: 'home-component',
  templateUrl: 'home_component.html',
  styleUrls: const ['home_component.css'],
  directives: const [
    materialDirectives,
    ROUTER_DIRECTIVES,
    CORE_DIRECTIVES,
    RobotSummaryComponent,
    MaterialToggleComponent,
  ],
  providers: const [
    materialProviders,
  ],
)
class HomeComponent implements OnInit {
  up.Robot sampleRobot;

  final Router router;

  HomeComponent(this.router);

  @override
  void ngOnInit() {
    up.Match match = new up.Match();
    sampleRobot = new up.Robot(match.red, null);
  }
}
