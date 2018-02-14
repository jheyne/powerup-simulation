import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../../scoring/model.dart';
import '../../scoring/goal_spec.dart';
import '../../utils/index_db_service.dart';

@Component(
    selector: 'stored-data-component',
    templateUrl: 'stored_data_component.html',
    styleUrls: const [
      'stored_data_component.css'
    ],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialButtonComponent,
      IndexDbService,
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class StoredDataComponent implements OnInit {
  final IndexDbService _indexDbService;

  @Input()
  Robot robot;

  Map<String, dynamic> _selectedRobot;

  Map<String, dynamic> get selectedRobot => _selectedRobot;

  void set selectedRobot(Map<String, dynamic> map) {
    print('selectedRobot: $map');
    _selectedRobot = map;
  }

  Map<String, dynamic> selectedStrategy;

  List<Map<String, dynamic>> get savedRobots => _indexDbService.robots;

  List<Map<String, dynamic>> get savedStrategies => _indexDbService.strategies;

  StoredDataComponent(this._indexDbService);

  @override
  void ngOnInit() {}

  xxx() {
    robot.strategyLabel;
  }

  saveRobot() => _indexDbService.addRobot(robot);

  loadRobot() {
    print('loading selected robot : $selectedRobot');
    print('loading selected TYPE : ${selectedRobot.runtimeType}');
    robot.fromJson(selectedRobot);
  }

  saveStrategy() => _indexDbService.addStrategy(robot.strategy);

  loadStrategy() {
    Strategy strategy = new Strategy()..fromJson(selectedStrategy);
    robot.strategyLabel = strategy.label;
    robot.goalSpecs = strategy.goalSpecs;
  }

  emailRobot() {}

  emailAllRobots() {}

  emailStrategy() {}

  emailAllStrategies() {}

  deleteRobot() => _indexDbService.deleteRobot(selectedRobot);

  deleteStrategy() => _indexDbService.deleteStrategy(selectedStrategy);
}
