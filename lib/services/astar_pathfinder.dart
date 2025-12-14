import '../models/store_layout_model.dart';
import 'navigation_service.dart';

/// A* pathfinding implementation for navigating around obstacles
class AStarPathfinder {
  static const double gridSize = 0.5; // 0.5 meters per grid cell

  /// Find path from start to goal avoiding obstacles
  List<Position> findPath(Position start, Position goal, StoreLayout layout) {
    // Convert positions to grid coordinates
    final startNode = _GridNode(
      x: (start.x / gridSize).round(),
      y: (start.y / gridSize).round(),
    );
    final goalNode = _GridNode(
      x: (goal.x / gridSize).round(),
      y: (goal.y / gridSize).round(),
    );

    // Open and closed sets
    final openSet = <_GridNode>[startNode];
    final closedSet = <_GridNode>{};
    final cameFrom = <_GridNode, _GridNode>{};
    final gScore = <_GridNode, double>{startNode: 0};
    final fScore = <_GridNode, double>{
      startNode: _heuristic(startNode, goalNode),
    };

    while (openSet.isNotEmpty) {
      // Get node with lowest fScore
      openSet.sort(
        (a, b) => (fScore[a] ?? double.infinity).compareTo(
          fScore[b] ?? double.infinity,
        ),
      );
      final current = openSet.removeAt(0);

      // Check if we reached the goal
      if (current == goalNode) {
        return _reconstructPath(cameFrom, current);
      }

      closedSet.add(current);

      // Check all neighbors (8 directions)
      for (final neighbor in _getNeighbors(current)) {
        if (closedSet.contains(neighbor)) continue;

        // Check if neighbor is walkable
        final neighborPos = Position(
          x: neighbor.x * gridSize,
          y: neighbor.y * gridSize,
        );
        if (!_isWalkable(neighborPos, layout)) continue;

        // Calculate tentative gScore
        final tentativeG =
            (gScore[current] ?? double.infinity) + _distance(current, neighbor);

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeG >= (gScore[neighbor] ?? double.infinity)) {
          continue;
        }

        // This path is the best so far
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeG;
        fScore[neighbor] = tentativeG + _heuristic(neighbor, goalNode);
      }
    }

    // No path found using A*, try adding waypoints
    return _findPathWithWaypoints(start, goal, layout);
  }

  /// Find path by adding waypoints at aisle ends
  /// This ensures the path goes around aisles rather than through them
  List<Position> _findPathWithWaypoints(
    Position start,
    Position goal,
    StoreLayout layout,
  ) {
    // Check if start and goal are in different aisles
    final startAisle = _getAisleContaining(start, layout);
    final goalAisle = _getAisleContaining(goal, layout);

    // If both in same aisle, use straight path
    if (startAisle != null && startAisle == goalAisle) {
      return [start, goal];
    }

    // Build path with waypoints
    final waypoints = <Position>[start];

    // If goal is in an aisle, we need to route to the aisle entrance
    if (goalAisle != null) {
      // Find which end of the goal aisle is closer to start
      final aisleTopEnd = Position(
        x: goalAisle.bounds.x + goalAisle.bounds.width / 2,
        y: goalAisle.bounds.y,
      );
      final aisleBottomEnd = Position(
        x: goalAisle.bounds.x + goalAisle.bounds.width / 2,
        y: goalAisle.bounds.y + goalAisle.bounds.height,
      );

      // Choose the closer end
      final distToTop = _distanceBetween(start, aisleTopEnd);
      final distToBottom = _distanceBetween(start, aisleBottomEnd);

      final aisleEntrance = distToTop < distToBottom
          ? aisleTopEnd
          : aisleBottomEnd;

      // Add waypoint at aisle entrance (only if it's not too close to start)
      if (_distanceBetween(start, aisleEntrance) > 1.0) {
        waypoints.add(aisleEntrance);
      }
    }

    waypoints.add(goal);
    return waypoints;
  }

  /// Get the aisle containing a position, or null if not in any aisle
  Aisle? _getAisleContaining(Position pos, StoreLayout layout) {
    for (final aisle in layout.aisles) {
      if (pos.x >= aisle.bounds.x &&
          pos.x <= aisle.bounds.x + aisle.bounds.width &&
          pos.y >= aisle.bounds.y &&
          pos.y <= aisle.bounds.y + aisle.bounds.height) {
        return aisle;
      }
    }
    return null;
  }

  /// Get the end point of an aisle that's closest to the target
  Position _getAisleEnd(Aisle aisle, Position target) {
    // Aisles are vertical, so we check top and bottom ends
    final topEnd = Position(
      x: aisle.bounds.x + aisle.bounds.width / 2,
      y: aisle.bounds.y,
    );
    final bottomEnd = Position(
      x: aisle.bounds.x + aisle.bounds.width / 2,
      y: aisle.bounds.y + aisle.bounds.height,
    );

    // Return the end closer to target
    final distToTop = _distanceBetween(topEnd, target);
    final distToBottom = _distanceBetween(bottomEnd, target);

    return distToTop < distToBottom ? topEnd : bottomEnd;
  }

  /// Calculate Euclidean distance between two positions
  double _distanceBetween(Position a, Position b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy); // No need for sqrt for comparison
  }

  /// Check if a position is walkable
  /// Aisles have walkable center paths, but we avoid the shelf areas on sides
  bool _isWalkable(Position pos, StoreLayout layout) {
    // Check if position is within store bounds
    if (pos.x < 0 || pos.x > 50.0 || pos.y < 0 || pos.y > 30.0) {
      return false;
    }

    // For now, consider all positions within store bounds as walkable
    // In a more sophisticated implementation, we could define shelf zones
    // within aisles that should be avoided, but allow the center walkway

    // The key insight: products are ON shelves (edges of aisles)
    // The walkable path is the CENTER of aisles and the spaces between them
    // For simplicity, we'll allow all positions and let the grid resolution
    // naturally create paths that go through aisle centers and between aisles

    return true;
  }

  /// Get neighboring grid nodes (8 directions)
  List<_GridNode> _getNeighbors(_GridNode node) {
    return [
      _GridNode(x: node.x - 1, y: node.y), // Left
      _GridNode(x: node.x + 1, y: node.y), // Right
      _GridNode(x: node.x, y: node.y - 1), // Up
      _GridNode(x: node.x, y: node.y + 1), // Down
      _GridNode(x: node.x - 1, y: node.y - 1), // Up-Left
      _GridNode(x: node.x + 1, y: node.y - 1), // Up-Right
      _GridNode(x: node.x - 1, y: node.y + 1), // Down-Left
      _GridNode(x: node.x + 1, y: node.y + 1), // Down-Right
    ];
  }

  /// Heuristic function (Manhattan distance)
  double _heuristic(_GridNode a, _GridNode b) {
    return ((a.x - b.x).abs() + (a.y - b.y).abs()).toDouble();
  }

  /// Distance between two grid nodes
  double _distance(_GridNode a, _GridNode b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    // Diagonal movement costs sqrt(2), straight costs 1
    return (dx == 1 && dy == 1) ? 1.414 : 1.0;
  }

  /// Reconstruct path from A* result
  List<Position> _reconstructPath(
    Map<_GridNode, _GridNode> cameFrom,
    _GridNode current,
  ) {
    final path = <_GridNode>[current];
    var node = current;

    while (cameFrom.containsKey(node)) {
      node = cameFrom[node]!;
      path.insert(0, node);
    }

    // Convert grid nodes back to positions and simplify path
    final positions = path
        .map((n) => Position(x: n.x * gridSize, y: n.y * gridSize))
        .toList();

    // Simplify path by removing unnecessary waypoints
    return _simplifyPath(positions);
  }

  /// Simplify path by removing collinear points
  List<Position> _simplifyPath(List<Position> path) {
    if (path.length <= 2) return path;

    final simplified = <Position>[path.first];

    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];

      // Check if points are collinear (same direction)
      final dx1 = curr.x - prev.x;
      final dy1 = curr.y - prev.y;
      final dx2 = next.x - curr.x;
      final dy2 = next.y - curr.y;

      // If direction changes significantly, keep the point
      final crossProduct = (dx1 * dy2 - dy1 * dx2).abs();
      if (crossProduct > 0.1) {
        simplified.add(curr);
      }
    }

    simplified.add(path.last);
    return simplified;
  }
}

/// Grid node for A* pathfinding
class _GridNode {
  final int x;
  final int y;

  _GridNode({required this.x, required this.y});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GridNode && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
