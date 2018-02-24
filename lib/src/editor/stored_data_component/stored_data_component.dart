import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:clippy/browser.dart' as clippy;
import 'package:power_up_2018/src/services/index_db_service.dart';

import '../../scoring/goal_spec.dart';
import '../../scoring/model.dart' as up;

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
      formDirectives,
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
  up.Robot robot;

  Map<String, dynamic> _selectedRobot;

  Map<String, dynamic> get selectedRobot => _selectedRobot;

  void set selectedRobot(Map<String, dynamic> map) {
    _selectedRobot = map;
  }

  Map<String, dynamic> selectedStrategy;

  List<Map<String, dynamic>> get savedRobots => _indexDbService.robots;

  List<Map<String, dynamic>> get savedStrategies => _indexDbService.strategies;

  String get emailStrategyHref {
    String subject =
        Uri.encodeFull("PowerUp Simulation Strategy '${robot.strategyLabel}'");
    Map<String, dynamic> json = robot.strategy.toJson();
    json.remove('dbKey');
    String body =
        Uri.encodeFull(new JsonEncoder.withIndent('  ').convert(json));
    return 'mailto:mail@example.org?subject=$subject&body=$body';
  }

  String get emailRobotHref => _emailHref('Robot', robot.label, robot.toJson());

  String _emailHref(
      String objectType, String label, Map<String, dynamic> json) {
    String subject = Uri.encodeFull("PowerUp Simulation $objectType '$label'");
    json.remove('dbKey');
    String body =
        Uri.encodeFull(new JsonEncoder.withIndent('  ').convert(json));
    return 'mailto:mail@example.org?subject=$subject&body=$body';
  }

  StoredDataComponent(this._indexDbService);

  Map<String, dynamic> pastedRobot = null;
  Map<String, dynamic> pastedStrategy = null;

  _handlePaste(String pasted) {
    try {
      var map = JSON.decode(pasted);
      if (map is Map<String, dynamic>) {
        if (map['goalSpecs'] is List<Map>) {
          new Strategy()..fromJson(map);
          pastedStrategy = map;
        } else if (map['travelSpeed'] is Map) {
          new up.Robot(new up.Match().red, null)..fromJson(map);
          pastedRobot = map;
        }
      }
    } catch (e) {
      print('Paste error: $e');
      print('Copy buffer: $pasted');
    }
  }

  @override
  void ngOnInit() {
    clippy.onPaste.listen(_handlePaste);
  }

  saveRobot() => _indexDbService.addRobot(robot);

  loadRobot() {
    robot.fromJson(selectedRobot);
  }

  copyRobot() => _copy(robot.toJson());

  pasteRobot() => robot.fromJson(pastedRobot);

  _copy(Map<String, dynamic> map) => clippy.write(JSON.encode(map));

  saveStrategy() {
    Strategy strategy = robot.strategy;
//    strategy.label = robot.strategyLabel;
    print('The robot label is ${robot.label} and strategy label is ${strategy
        .label}');
    _indexDbService.addStrategy(strategy);
  }

  loadStrategy() {
    _loadStrategy(selectedStrategy);
  }

  _loadStrategy(Map<String, dynamic> map) {
    Strategy strategy = new Strategy()..fromJson(map);
    robot.strategyLabel = strategy.label;
    robot.goalSpecs = strategy.goalSpecs;
  }

  deleteRobot() => _indexDbService.deleteRobot(selectedRobot);

  deleteStrategy() => _indexDbService.deleteStrategy(selectedStrategy);

  copyStrategy() => _copy(selectedStrategy);

  pasteStrategy() {
    try {
      _loadStrategy(pastedStrategy);
    } catch (e) {
      window.alert('Failure when attempting to paste strategy: $e');
    }
  }
}
