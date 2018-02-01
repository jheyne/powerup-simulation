import 'dart:math';

import 'package:path_finding/path_finding.dart';

class GridBuilder {
  static List<List<bool>> buildGrid() {
    List<List<bool>> answer = [];
    for (int i = 0; i < 108; i++) {
      List<bool> row = new List(27);
      row.fillRange(0, 27, true);
      answer.add(row);
    }
    // blue switch and blue 6
    _maskOut(5, 23, 17, 1, answer);
    _maskOut(10, 24, 7, 4, answer);
    _maskOut(5, 30, 17, 1, answer);
    // scale
    _maskOut(4, 51, 19, 1, answer);
    _maskOut(10, 52, 7, 4, answer);
    _maskOut(4, 58, 19, 1, answer);
    // red switch and red 6
    _maskOut(5, 75, 17, 1, answer);
    _maskOut(10, 76, 7, 4, answer);
    _maskOut(5, 84, 17, 1, answer);
    return answer;
  }

  static _maskOut(
      int x, int y, int width, int height, List<List<bool>> answer) {
    for (int i = y; i < y + height; i++) {
      for (int j = x; j < x + width; j++) {
        answer[i][j] = false;
      }
    }
  }

}

class PathPlanner {
  static List<List<bool>> _grid;

  List<List<bool>> get gridList =>
      _grid == null ? _grid = GridBuilder.buildGrid() : _grid;

  static PathPlanner instance = new PathPlanner();

  List<PointNode> findPath(Point from, Point to, Rectangle rectangle) {
    Grid grid = new Grid(gridList);
    grid.diagonalMovement = DiagonalMovement.WithOneObstruction;
    PointNode start = grid.nodeFromPoint(scalePoint(from, rectangle));
    PointNode goal = grid.nodeFromPoint(scalePoint(to, rectangle));
//    print('Start Node: $start Goal Node: $goal');
    AStarFinder aStarFinder = new AStarFinder(grid);
    List<PointNode> path = aStarFinder.pathFind(start, goal);
    return path;
  }

  Map<int, Map<String, Object>> buildKeyFrames(
      Point from, Point to, Rectangle rectangle) {
    Map<int, Map<String, Object>> keyframes =
        new Map<int, Map<String, Object>>();
    List<PointNode> nodes = findPath(from, to, rectangle);
    keyframes[0] = buildKeyframe(nodes.first, rectangle);
    keyframes[100] = buildKeyframe(nodes.last, rectangle);
//    int interval = max(1, ((nodes.length - 2) / 18).floor().toInt());
    num interval = max(1, (100 / (nodes.length - 1)));
    for (int i = 1; i < nodes.length - 1; i++) {
      keyframes[(i * interval).floor().toInt()] = buildKeyframe(nodes[i], rectangle);
    }
    return keyframes;
  }

  Map<String, Object> buildKeyframe(PointNode node, Rectangle rectangle) {
    int unscaleX(PointNode n) => node.location.x * rectangle.width ~/ 27;
    int unscaleY(PointNode n) => node.location.y * rectangle.height ~/ 108;
    return {'left': '${unscaleX(node)}px', 'top': '${unscaleY(node)}px'};
  }
}

Point scalePoint(Point point, Rectangle rectangle) {
  return new Point((point.x * 27 / rectangle.width).floor().toInt(),
      (point.y * 108 / rectangle.height).floor().toInt());
}
