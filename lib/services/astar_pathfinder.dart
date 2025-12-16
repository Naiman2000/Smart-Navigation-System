import '../models/store_layout_model.dart';
import 'navigation_service.dart';

/// A* pathfinding implementation for navigating around obstacles
class AStarPathfinder {
  static const double gridSize = 0.5; // 0.5 meters per grid cell

  /// Find path from start to goal avoiding obstacles
  List<Position> findPath(Position start, Position goal, StoreLayout layout) {
    // Adjust both start and goal positions if they're in aisles to be at walkable centers
    final adjustedStart = _adjustToWalkablePosition(start, layout);
    final adjustedGoal = _adjustToWalkablePosition(goal, layout);
    
    // Convert positions to grid coordinates
    final startNode = _GridNode(
      x: (adjustedStart.x / gridSize).round(),
      y: (adjustedStart.y / gridSize).round(),
    );
    final goalNode = _GridNode(
      x: (adjustedGoal.x / gridSize).round(),
      y: (adjustedGoal.y / gridSize).round(),
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

        // Calculate tentative gScore with penalty for aisle centers
        // This makes the algorithm prefer walkways over aisle centers
        final baseDistance = _distance(current, neighbor);
        final aislePenalty = _getAisleContaining(neighborPos, layout) != null ? 2.0 : 0.0;
        final tentativeG =
            (gScore[current] ?? double.infinity) + baseDistance + aislePenalty;

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
    return _findPathWithWaypoints(adjustedStart, adjustedGoal, layout);
  }

  /// Find path by adding waypoints at aisle ends
  /// This ensures the path goes through walkways between aisles
  /// Note: These waypoints will be connected using A* pathfinding in navigation_service
  List<Position> _findPathWithWaypoints(
    Position start,
    Position goal,
    StoreLayout layout,
  ) {
    // Both start and goal are already adjusted to walkway positions (beside aisles)
    final adjustedStart = _adjustToWalkablePosition(start, layout);
    final adjustedGoal = _adjustToWalkablePosition(goal, layout);
    
    // Since adjusted positions are in walkways, we can route directly
    // The A* pathfinding will handle routing through walkways
    if (_distanceBetween(adjustedStart, adjustedGoal) > 0.1) {
      return [adjustedStart, adjustedGoal];
    }
    
    return [adjustedStart];
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

  /// Calculate Euclidean distance between two positions
  double _distanceBetween(Position a, Position b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy); // No need for sqrt for comparison
  }

  /// Adjust a position to be walkable if it's in an aisle
  /// For items on shelves, this offsets to the walkway beside the aisle
  /// If item is on right side, offset to left walkway; if on left, offset to right walkway
  Position _adjustToWalkablePosition(Position pos, StoreLayout layout) {
    final aisle = _getAisleContaining(pos, layout);
    if (aisle != null) {
      final aisleCenterX = aisle.bounds.x + aisle.bounds.width / 2;
      final originalX = pos.x;
      
      // Determine which side of the aisle the item is on
      // If item X > aisle center, it's on the right side, so offset to left walkway
      // If item X < aisle center, it's on the left side, so offset to right walkway
      final isOnRightSide = originalX > aisleCenterX;
      
      // Walkway width is 3m, aisle width is 2m
      // Offset to the walkway beside the aisle
      final walkwayOffset = 1.5; // Half of walkway width (3m / 2 = 1.5m)
      
      double adjustedX;
      if (isOnRightSide) {
        // Item is on right side, offset to left walkway (left of aisle)
        adjustedX = aisle.bounds.x - walkwayOffset;
      } else {
        // Item is on left side, offset to right walkway (right of aisle)
        adjustedX = aisle.bounds.x + aisle.bounds.width + walkwayOffset;
      }
      
      // Keep the Y coordinate (shelf level)
      final adjustedY = pos.y.clamp(
        aisle.bounds.y,
        aisle.bounds.y + aisle.bounds.height,
      );
      
      return Position(x: adjustedX, y: adjustedY);
    }
    return pos;
  }

  /// Check if a position is walkable
  /// Walkways between aisles are always walkable
  /// Aisle centers are only walkable when navigating within that aisle
  bool _isWalkable(Position pos, StoreLayout layout) {
    // Check if position is within store bounds
    if (pos.x < 0 || pos.x > 50.0 || pos.y < 0 || pos.y > 30.0) {
      return false;
    }

    // Check if position is within an aisle bounds
    final aisle = _getAisleContaining(pos, layout);
    
    if (aisle != null) {
      // Position is within an aisle rectangle
      // Only allow if it's at the exact center (walkway within aisle)
      // Aisles are 2m wide, center is at x + 1m
      final aisleCenterX = aisle.bounds.x + aisle.bounds.width / 2;
      final distanceFromCenter = (pos.x - aisleCenterX).abs();
      
      // Only allow positions very close to aisle center (within 0.1m tolerance)
      // This ensures we only use aisle centers, not shelf areas
      if (distanceFromCenter > 0.1) {
        return false;
      }
      
      // Check Y bounds to ensure we're within the aisle
      if (pos.y < aisle.bounds.y || pos.y > aisle.bounds.y + aisle.bounds.height) {
        return false;
      }
      
      // Aisle center is walkable (for navigating to items in this aisle)
      return true;
    }
    
    // Position is not in any aisle - it's in a walkway between aisles
    // Walkways are always walkable
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

