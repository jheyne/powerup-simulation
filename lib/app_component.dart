import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import 'src/power_up/power_up.dart';
import 'src/services/index_db_service.dart';
import 'src/services/robot_service.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, PowerUpComponent],
  providers: const [materialProviders, IndexDbService, RobotService],
)
class AppComponent {}
