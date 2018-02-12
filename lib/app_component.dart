import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import 'src/power_up/power_up.dart';
import 'src/utils/index_db_service.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, PowerUpComponent],
  providers: const [materialProviders, IndexDbService],
)
class AppComponent {
  // Nothing here yet. All logic is in TodoListComponent.
}
