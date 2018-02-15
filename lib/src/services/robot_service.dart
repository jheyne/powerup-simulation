import 'dart:math';
import "package:angular/angular.dart";
import '../scoring/model.dart' as up;
import '../scoring/goal_spec.dart';
import '../scoring/autobot.dart';

enum Zone { Near, Mid, Far }

typedef up.LocationService LocationSupplier();

@Directive(selector: '[robot-service]')
@Injectable()
class RobotService {

  Random random = new Random();

  LocationSupplier locationSupplier;

  bool manualDriveRed1 = false;

  up.Match match;
  up.Robot robotRed1;
  up.Robot robotRed2;
  up.Robot robotRed3;
  up.Robot robotBlue1;
  up.Robot robotBlue2;
  up.Robot robotBlue3;

  void newMatch() {
    match = new up.Match();
    robotRed1 = buildBot(match.red, Zone.Near)..label = 'Red 1';
    robotRed2 = buildBot(match.red, Zone.Mid)..label = 'Red 2';
    robotRed3 = buildBot(match.red, Zone.Far)..label = 'Red 3';
    robotBlue1 = buildBot(match.blue, Zone.Near)..label = 'Blue 1';
    robotBlue2 = buildBot(match.blue, Zone.Mid)..label = 'Blue 2';
    robotBlue3 = buildBot(match.blue, Zone.Far)..label = 'Blue 3';
  }

  up.Robot buildBot(up.Alliance alliance, Zone zone) {
    up.Robot robot = new up.Robot(alliance, locationSupplier);
    buildSpecs(robot, buildGoalStrategy(robot, zone));
    adjustCapability(robot);
    return robot;
  }

  adjustCapability(up.Robot robot) {
    robot.ranking = random.nextInt(100);
  }

  buildGoalStrategy(up.Robot robot, Zone zone) {
    if (zone == Zone.Near) {
      return GoalBuilder.nearField(robot.alliance);
    } else if (zone == Zone.Mid) {
      return GoalBuilder.midField(robot.alliance);
    } else {
      return GoalBuilder.farField(robot.alliance);
    }
  }

  buildSpecs(up.Robot robot, GoalStrategy strategy) {
    robot.strategyLabel = strategy.label;
    for (TargetGoal goal in strategy.goals) {
      robot.goalSpecs.add(new GoalSpec()..fromJson(goal.toJson()));
    }
    print('Printing robot: ${robot.toJson()}');
  }
}