import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:css_animation/css_animation.dart';

import '../balance_component/balance_component.dart';
import '../scoring/model.dart' as up;
import '../utils/astar_util.dart';

@Component(
  selector: 'field-diagram',
  templateUrl: 'field_diagram.html',
  styleUrls: const ['field_diagram.css'],
  directives: const [CORE_DIRECTIVES, NgClass, BalanceComponent],
)
class FieldDiagram implements OnInit, AfterViewChecked, up.LocationService {
  static const int DISPLAY_SCALE = 2;

  /// keep track of robots and the elements that visualize them
  Map<up.Robot, Element> _robotMap = {};

  @Input()
  up.Match match;
  @Input()
  up.Field field;
  @Input()
  up.Robot robot;

  @ViewChild('topSwitch')
  BalanceComponent topSwitch;

  @ViewChild('bottomSwitch')
  BalanceComponent bottomSwitch;

  @ViewChild('midScale')
  BalanceComponent midScale;

  FieldDiagram();

  bool get isRed => robot.alliance.isRed;

  bool get isBlue => robot.alliance.isBlue;

  Map<String, bool> get balancePlateClass =>
      {'redTeam': isRed, 'blueTeam': isBlue};

  @override
  void ngOnInit() {
    PathPlanner.instance.gridList;
  }

  @override
  ngAfterViewChecked() {
    List<BalanceComponent> balanceComponents = [
      topSwitch,
      midScale,
      bottomSwitch
    ];
//    print('Components are $balanceComponents');
    for (BalanceComponent b in balanceComponents) {
      b.ngOnInit();
    }
  }

  @override
  up.Location getLocationX(MouseEvent event) {
    Element element = event.target;
    Rectangle diagramOffset = offsetFromDiagramX(element);
    var rect = diagramOffset;
//    print('ClientX ${element.id} left ${rect.left}, ${rect.top}, ${rect
//        .width}, ${rect.height}');
    return new up.Location(rect.left + rect.width / 2 - 8,
        rect.top + rect.height / 2 - 8, rect.width, rect.height);
  }

  Rectangle offsetFromDiagramX(Element element) {
    Element parent = querySelector('#field');
    Element current = element;
    num left = 0;
    num top = 0;
    while (current != parent) {
      left += current.offsetLeft;
      top += current.offsetTop;
      current = current.parent;
    }
    return new Rectangle(left, top, element.offsetWidth, element.offsetHeight);
  }

  @override
  up.Location getLocation(up.HasId item) {
    Element parent = querySelector('#field');
    Element element = querySelector('#${item.id}');
    var rect = element.client;
//    print(
//        'Client left ${rect.left}, ${rect.top}, ${rect.width}, ${rect.height}');
    return new up.Location(rect.left, rect.top, rect.width, rect.height);
  }

  /// calculate how long the move should take, move the robot, and disable input until finished
  onRobotMove(up.Robot bot, math.Point start, math.Point end, whenComplete) {
//    print('Begin at $start go to $end');
    final num distance =
        math.sqrt(math.pow(start.x - end.x, 2) + math.pow(start.y - end.y, 2)) *
            DISPLAY_SCALE;
    final num turn = bot.turn.sampleValue;
    final num travelTime = distance / bot.travelSpeed.sampleValue;
    // TODO need to know operation being performed
    final num graspBall = bot.graspBall.sampleValue;
    final int duration = (turn + travelTime + graspBall).toInt();
//    print('Turn: $turn Travel Time: $travelTime Grasp ball: $graspBall');
//    print('Distance: $distance Duration: $duration');

    Element element = _robotMap[robot];
    math.Rectangle fieldRect = querySelector('#field').getBoundingClientRect();
//    print('Start: $start End: $end');
    Map<int, Map<String, Object>> keyframes = {};
    try {
      keyframes = PathPlanner.instance.buildKeyFrames(start, end, fieldRect);
    } catch (e) {
      print(e);
      keyframes = new Map<int, Map<String, Object>>();
      keyframes[0] = {'left': '${start.x}px', 'top': '${start.y}px'};
    }
    // set the end in case of rounding errors
    keyframes[100] = {'left': '${end.x}px', 'top': '${end.y}px'};
    var animation = new CssAnimation.keyframes(keyframes);
    animationComplete() {
      whenComplete();
      animation.destroy();
    }

    animation.apply(element,
        duration: math.max(duration, 1000), onComplete: animationComplete);
  }

  addRobot(up.Robot robot) {
    Element added = new DivElement()
      ..classes.add('robot')
      ..style.width = '16px'
      ..style.height = '16px'
      ..style.backgroundColor = 'rgba(255, 0, 0, 0.5)'
      ..style.position = 'relative'
      ..style.zIndex = '100';
    querySelector('#field').children.add(added);
    _robotMap[robot] = added;
    robot.onRobotMove = onRobotMove;
  }

  resetRobots() {
    _robotMap.forEach((robot, element) => element.remove());
    _robotMap.clear();
  }
}
