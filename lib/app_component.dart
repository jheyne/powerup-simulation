import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';

import 'src/page/home_component/home_component.dart';
import 'src/page/main_page_component/main_page_component.dart';
import 'src/power_up/power_up.dart';
import 'src/services/index_db_service.dart';
import 'src/services/robot_service.dart';

@RouteConfig(const [
  const Redirect(path: '/', redirectTo: const ['Home']),
  const Redirect(path: '/index.html', redirectTo: const ['Home']),
  const Route(path: '/home', name: 'Home', component: HomeComponent),
  const Route(
      path: '/prepareRobots', name: 'Configure', component: MainPageComponent),
  const Route(
      path: '/powerup', name: 'RunSimulation', component: PowerUpComponent),
])
@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [
    materialDirectives,
    PowerUpComponent,
    MainPageComponent,
    HomeComponent,
    RouterLink,
    ROUTER_DIRECTIVES,
    CORE_DIRECTIVES
  ],
  providers: const [materialProviders, IndexDbService, RobotService],
)
class AppComponent {}
