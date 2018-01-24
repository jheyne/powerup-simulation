import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../scoring/model.dart' as up;

@Component(
  selector: 'cube-operations',
  templateUrl: 'cube_operations.html',
  styleUrls: const ['cube_operations.css'],
  directives: const [
    CORE_DIRECTIVES,
    materialDirectives,
    MaterialButtonComponent,
    MaterialIconComponent
  ],
  providers: const [],
)
class CubeOperations {
  @Input()
  up.Robot robot;

  CubeOperations();

  x() {
    robot.alliance.switch_.leftCubeCount;
  }
}
