import 'dart:html';

import 'package:angular/angular.dart';

import '../scoring/model.dart';

@Component(
  selector: 'balance-component',
  templateUrl: 'balance_component.html',
  styleUrls: const ['balance_component.css'],
  directives: const [CORE_DIRECTIVES, NgClass, NgIf],
)
class BalanceComponent implements OnInit {
  @Input()
  Robot robot;

  @Input()
  Balance balance;

  bool get redOnLeft => balance.redOnLeft;

  @Input()
  bool isSwitch = true;

  Map<String, bool> classMap(bool isLeft) {
//    bool isBlue = !redOnLeft && !isLeft || redOnLeft && isLeft;
    bool red = isLeft && redOnLeft || !isLeft && !redOnLeft;
    return {'red': red, 'blue': !red, 'switch': isSwitch, 'scale': !isSwitch};
  }

  clickRightPlate(MouseEvent event) {
    // presume robot is red
    BalancePlate plate = redOnLeft ? balance.bluePlate : balance.redPlate;
    print('redOnLeft is $redOnLeft so got plate ${plate.color}');
    plate.putCube(robot, event, 'right');
  }

  clickLeftPlate(MouseEvent event) {
    // presume robot is red
    BalancePlate plate = !redOnLeft ? balance.bluePlate : balance.redPlate;
    print('redOnLeft is $redOnLeft so got plate ${plate.color}');
    plate.putCube(robot, event, 'left');
  }

  BalanceComponent();

  @override
  void ngOnInit() {
    if (balance.redPlate.alliance == null) {
      balance.redPlate.alliance = robot.alliance.isRed
          ? robot.alliance
          : robot.alliance.oppositeAlliance;
      balance.bluePlate.alliance = robot.alliance.isRed
          ? robot.alliance.oppositeAlliance
          : robot.alliance;
      print('intializing alliances (Red on Left: $redOnLeft) left: ${balance
          .redPlate.alliance.color} right: ${balance.bluePlate.alliance
          .color}');
    }
  }

  xxx() {
    balance.cubeCount(robot.alliance);
    balance.redPlate.cubeCount;
  }
}
