import 'package:angular/angular.dart';

import '../../editor/robot_component/robot_component.dart';
import '../../services/robot_service.dart';


@Component(
  selector: 'main-page-component',
  templateUrl: 'main_page_component.html',
  styleUrls: const ['main_page_component.css'],
  directives: const [CORE_DIRECTIVES, NgClass, RobotComponent],
)
class MainPageComponent implements OnInit {

  final RobotService botz;
  MainPageComponent(this.botz);

  @override
  void ngOnInit() {
    botz.newMatch();
  }

}
