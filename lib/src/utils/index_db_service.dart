import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';

import "package:angular/angular.dart";

import '../scoring/model.dart';
import '../scoring/goal_spec.dart';

@Directive(selector: '[index-db-service]')
@Injectable()
class IndexDbService {
  bool idbAvailable = IdbFactory.supported;
  Database _db;

  Future open() {
    return window.indexedDB
        .open('milestoneDB', version: 2, onUpgradeNeeded: _initializeDatabase)
        .then(_loadFromDB);
  }

  List<Map<String, dynamic>> robots = [];
  List<Map<String, dynamic>> strategies = [];

  static const String ROBOT_STORE = 'robotStore';
  static const String STRATEGY_STORE = 'strategyStore';

//  static const String MY_INDEX = 'my_index';

  void _initializeDatabase(VersionChangeEvent e) {
    Database db = (e.target as Request).result;

    db.createObjectStore(ROBOT_STORE, autoIncrement: true);
    db.createObjectStore(STRATEGY_STORE, autoIncrement: true);
//    objectStore.createIndex(MY_INDEX, 'myIndexField', unique: true);
  }

  Future _loadFromDB(Database db) {
    print('Loading from DB: $db');
    _db = db;
    _loadRobots(db);
    return _loadStrategies(db);
  }

  Future _loadRobots(Database db) {
    Transaction trans = db.transaction(ROBOT_STORE, 'readonly');
    ObjectStore store = trans.objectStore(ROBOT_STORE);

    Stream<CursorWithValue> cursors =
        store.openCursor(autoAdvance: true).asBroadcastStream();
    cursors.listen((cursor) {
      Map<String, dynamic> map = new Map.from(cursor.value);
      map['dbKey'] = cursor.key;
      print('loaded key: ${cursor.key} value: $map');
      robots.add(map);
    });

    return cursors.length.then((_) {
      print('Robots length: ${robots.length}');
      print('These are the robots: $robots');
      return robots.length;
    });
  }

  Future _loadStrategies(Database db) {
    Transaction trans = db.transaction(STRATEGY_STORE, 'readonly');
    ObjectStore store = trans.objectStore(STRATEGY_STORE);

    Stream<CursorWithValue> cursors =
    store.openCursor(autoAdvance: true).asBroadcastStream();
    cursors.listen((cursor) {
      Map<String, dynamic> map = new Map.from(cursor.value);
      map['dbKey'] = cursor.key;
      print('loaded key: ${cursor.key} value: $map');
      strategies.add(map);
    });

    return cursors.length.then((_) {
      print('Strategies length: ${strategies.length}');
      return strategies.length;
    });
  }

  Future<Robot> addRobot(Robot robot) {
    print('adding robot ${robot.label}');
    return add<Robot>(robot, robots, ROBOT_STORE);
  }

  Future<Map<String, dynamic>> deleteRobot(Map<String, dynamic> map) {
    print('delete robot ${map['label']}');
    return delete(map, robots, ROBOT_STORE);
  }

  Future<Map<String, dynamic>> deleteStrategy(Map<String, dynamic> map) {
    print('delete strategy ${map['label']}');
    return delete(map, strategies, STRATEGY_STORE);
  }

  Future<Strategy> addStrategy(Strategy strategy) {
    return add<Strategy>(strategy, strategies, STRATEGY_STORE);
  }

  Future<T> add<T extends Persistable>(T persistable, List<Map<String, dynamic>> cache, String storeName) {
    Map<String, dynamic> map = persistable.toJson();
    print('map to persist $map');
    Transaction trans = _db.transaction(storeName, 'readwrite');
    ObjectStore store = trans.objectStore(storeName);
    store.add(map).then((addedKey) => map['dbKey'] = addedKey);
    print('the added key is ${map['dbKey']}');
    return trans.completed.then((Database db) {
      cache.add(map);
      persistable.dbKey = map['dbKey'];
      return persistable;
    });
  }

  Future<Map<String, dynamic>> delete(Map<String, dynamic> map, List<Map<String, dynamic>> cache, String storeName) {
    print('map to delete $map');
    Transaction trans = _db.transaction(storeName, 'readwrite');
    trans.objectStore(storeName).delete(map['dbKey']);
    return trans.completed.then((Database db) {
      cache.remove(map);
      map['dbKey'] = null;
      return map;
    });
  }
}

abstract class Persistable {
  String dbKey;

  Map<String, dynamic> toJson();

  void fromJson(Map<String, dynamic> json);
}
