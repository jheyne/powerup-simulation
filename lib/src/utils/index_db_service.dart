import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';

import "package:angular/angular.dart";

@Directive(selector: '[index-db-service]')
@Injectable()
class IndexDbService {
  bool idbAvailable = IdbFactory.supported;
  Database _db;
  Map<Object, Object> storedValues = {};

  Future open() {
    return window.indexedDB
        .open('milestoneDB', version: 1, onUpgradeNeeded: _initializeDatabase)
        .then(_loadFromDB);
  }

  static const String MY_STORE = 'powerupStore';

  static const String MY_INDEX = 'my_index';

  void _initializeDatabase(VersionChangeEvent e) {
    Database db = (e.target as Request).result;

    var objectStore =
        db.createObjectStore(MY_STORE, autoIncrement: true);
    objectStore.createIndex(MY_INDEX, 'myIndexField', unique: true);
  }

  Future _loadFromDB(Database db) {
    print('Loading from DB: $db');
    _db = db;
    Transaction trans = db.transaction(MY_STORE, 'readonly');
    ObjectStore store = trans.objectStore(MY_STORE);

    Stream<CursorWithValue> cursors =
        store.openCursor(autoAdvance: true).asBroadcastStream();
    cursors.listen((cursor) {
      storedValues[cursor.key] = cursor.value;
//      var milestone = new Milestone.fromRaw(cursor.key, cursor.value);
//      milestones.add(milestone);
    });

    return cursors.length.then((_) {
      return storedValues.length;
    });
  }
}
