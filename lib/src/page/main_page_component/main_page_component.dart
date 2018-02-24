import 'package:angular/angular.dart';
import 'package:power_up_2018/src/services/index_db_service.dart';

import '../../editor/robot_summary_component/robot_summary_component.dart';
import '../../services/robot_service.dart';


@Component(
  selector: 'main-page-component',
  templateUrl: 'main_page_component.html',
  styleUrls: const ['main_page_component.css'],
  directives: const [CORE_DIRECTIVES, NgClass, RobotSummaryComponent],
)
class MainPageComponent implements OnInit {

  static MainPageComponent myInstance = null;

  final RobotService botz;
  IndexDbService _indexDbService;
  bool hasIntialized = false;

  factory MainPageComponent(RobotService botz, IndexDbService indexDbService) {
    if(myInstance == null){
      myInstance = new MainPageComponent._internal(botz, indexDbService);
    }
    return myInstance;
  }

  MainPageComponent._internal(this.botz, this._indexDbService);


  @override
  void ngOnInit() {
    if (!hasIntialized) {
//      botz.newMatch();
      _indexDbService.open();
      hasIntialized = true;
    }
  }

}
