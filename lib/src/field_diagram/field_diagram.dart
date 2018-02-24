import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:css_animation/css_animation.dart';

import '../balance_component/balance_component.dart';
import '../scoring/game_clock.dart';
import '../scoring/model.dart' as up;
import '../utils/astar_util.dart';

@Component(
  selector: 'field-diagram',
  templateUrl: 'field_diagram.html',
  styleUrls: const ['field_diagram.css'],
  directives: const [CORE_DIRECTIVES, NgClass, BalanceComponent],
)
class FieldDiagram implements OnInit, AfterViewChecked, up.LocationService {
  final ChangeDetectorRef changeDetectorRef;
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

  FieldDiagram(this.changeDetectorRef);

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
    initializeScaleAndSwitches();
  }

  void initializeScaleAndSwitches() {
    List<BalanceComponent> balanceComponents = [
      topSwitch,
      midScale,
      bottomSwitch
    ];
    for (BalanceComponent b in balanceComponents) {
      b.ngOnInit();
    }
  }

  @override
  up.Location getLocationX(MouseEvent event) {
    Rectangle rect = offsetFromDiagram(event.target);
    return new up.Location(rect.left + rect.width / 2 - 8,
        rect.top + rect.height / 2 - 8, rect.width, rect.height);
  }

  Rectangle offsetFromDiagram(Element element) {
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
  up.Location getLocation(up.HasId item, up.Robot robot) {
    var id = item.id(robot);
    Element element = findElement(id);
    element.classes.add('findme');
    Rectangle rect = offsetFromDiagram(element);
    return new up.Location(rect.left, rect.top, rect.width, rect.height);
  }

  Element findElement(List<String> ids) {
    Element element = querySelector('#${ids.first}');
    if (ids.length == 1) {
      return element;
    } else {
      return element.querySelector('#${ids.last}');
    }
  }

  /// calculate how long the move should take, move the robot, and disable input until finished
  onRobotMove(up.Robot bot, math.Point start, math.Point end, whenComplete) {
//    print('onRobotMove start $start end $end');
    final num distance =
        math.sqrt(math.pow(start.x - end.x, 2) + math.pow(start.y - end.y, 2)) *
            DISPLAY_SCALE;
    final num turn = bot.turn.sampleValue;
    final num travelTime = distance / bot.travelSpeed.sampleValue;
    // TODO need to know operation being performed
    final num graspCube = bot.graspCube.sampleValue;
    final int duration = (turn + travelTime + graspCube).toInt();

    Element element = _robotMap[bot];
    math.Rectangle fieldRect = querySelector('#field').getBoundingClientRect();
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
    // avoid error if too many keyframes
    for (int i = 101; i < 110; i++) {
      keyframes.remove(i);
    }
    var animation = new CssAnimation.keyframes(keyframes);
    AnimationCanceller canceller =
        new AnimationCanceller(robot, element, animation);
    animationComplete() {
      whenComplete();
      animation.destroy();
      canceller.stopMonitoringEndGame();
    }

    animation.apply(element,
        duration: math.max(duration, 1000), onComplete: animationComplete);
  }

  int redBots = 0;
  int blueBots = 0;

  addRobot(up.Robot robot) {
    String color =
        robot.isRed ? 'rgba(255, 0, 0, 0.5)' : 'rgba(0, 0, 255, 0.5)';
    robot.isRed ? redBots++ : blueBots++;
    Element added = new DivElement()
      ..text = '${robot.isRed ? redBots : blueBots}'
      ..title = robot.label
      ..classes.add('robot')
      ..style.width = '16px'
      ..style.height = '16px'
      ..style.backgroundColor = color
      ..style.position = 'absolute'
      ..style.zIndex = '100';
    querySelector('#field').children.add(added);
    _robotMap[robot] = added;
    robot.onRobotMove = onRobotMove;
    new Timer(new Duration(milliseconds: 100), () {
      var myRect = added.getBoundingClientRect();
      var parentRect = added.parent.getBoundingClientRect();
      var x = myRect.left - parentRect.left;
      var y = myRect.top - parentRect.top;
      print('${robot.label} boundingClientRect $x @ $y');
      robot.currentLocation = new Point(x, y);
    });
  }

  resetField() {
    match.red.tally.matchPoints = 0;
    match.blue.tally.matchPoints = 0;
    _resetRobots();
    _resetCubeCounts();
    _resetSources();
  }

  _resetSources() {
    for (up.Alliance alliance in [match.red, match.blue]) {
      alliance.portalRight.count = 7;
      alliance.portalLeft.count = 7;
      alliance.allianceSource.count = 10;
      alliance.switchSource.count = 6;
    }
  }

  _resetRobots() {
    redBots = 0;
    blueBots = 0;
    _robotMap.forEach((robot, element) => element.remove());
    _robotMap.clear();
  }

  _resetCubeCounts() {
    for (BalanceComponent b in [topSwitch, midScale, bottomSwitch]) {
      b.balance.redPlate.cubeCount = 0;
      b.balance.bluePlate.cubeCount = 0;
    }
    for (up.Vault vault in [match.red.vault, match.blue.vault]) {
      vault.count = 0;
      vault.levitate.count = 0;
      vault.force.count = 0;
      vault.boost.count = 0;
    }
    _robotMap.keys.forEach((robot) {
      robot.hasClimbed = false;
      robot.hasParked = false;
      robot.hasCrossedLine = false;
    });
  }

  detectChanges() {
    changeDetectorRef.detectChanges();
  }

  placeRobots() {
    int red = 1;
    int blue = 1;
    _robotMap.forEach((robot, element) {
      if (robot.isRed) {
        element.style.left = '${red++ * 25}%';
        element.style.top = '97%';
      } else {
        element.style.left = '${blue++ * 25}%';
        element.style.top = '3%';
      }
    });
  }
}

class AnimationCanceller {
  final up.Robot robot;
  final Element element;
  final CssAnimation animation;

  AnimationCanceller(this.robot, this.element, this.animation) {
    registerForEndGame();
  }

  registerForEndGame() {
    robot.alliance.match.gameClock.addStateChangeListener(stateChange);
  }

  stateChange(State state) {
    if (state == State.DONE) {
      element.style.animationPlayState = 'paused';
      print('destroying animation for ${robot.label}');
      animation.destroy;
      stopMonitoringEndGame();
    }
  }

  void stopMonitoringEndGame() {
    robot.alliance.match.gameClock.removeStateChangeListener(stateChange);
  }
}
