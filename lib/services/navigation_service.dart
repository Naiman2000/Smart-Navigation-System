import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'beacon_service.dart';
import 'beacon_config_service.dart';
import '../models/product_model.dart';

class NavigationService {
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Store map dimensions (in meters)
  static const double storeWidth = 50.0;
  static const double storeHeight = 30.0;

  // Current user position
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Beacon config service for getting real beacon positions
  final BeaconConfigService _beaconConfigService = BeaconConfigService();

  // ============================================================================
  // POSITION CALCULATION (TRILATERATION)
  // ============================================================================

  /// Calculate user position using trilateration from 3+ beacons
  Future<Position?> calculatePosition(List<BeaconData> beacons) async {
    // Need at least 3 beacons for trilateration
    if (beacons.length < 3) {
      debugPrint('Need at least 3 beacons for position calculation');
      return null;
    }

    // Filter beacons with valid distances
    final validBeacons = beacons
        .where((b) => b.distance > 0 && b.distance < 50)
        .toList();

    if (validBeacons.length < 3) {
      return null;
    }

    try {
      // Get real beacon positions from configuration service
      final beaconPositions = await _beaconConfigService.getBeaconPositions(
        validBeacons.map((b) => b.id).toList(),
      );

      if (beaconPositions.length < 3) {
        debugPrint('Not enough configured beacons found (${beaconPositions.length}/3)');
        return null;
      }

      // Use the 3 closest beacons with valid positions
      final sortedBeacons = validBeacons
          .where((b) => beaconPositions.containsKey(b.id))
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

      if (sortedBeacons.length < 3) {
        return null;
      }

      final top3 = sortedBeacons.take(3).toList();
      final pos1 = beaconPositions[top3[0].id]!;
      final pos2 = beaconPositions[top3[1].id]!;
      final pos3 = beaconPositions[top3[2].id]!;

      final beacon1 = BeaconPosition(
        id: top3[0].id,
        x: pos1.x,
        y: pos1.y,
        distance: top3[0].distance,
      );

      final beacon2 = BeaconPosition(
        id: top3[1].id,
        x: pos2.x,
        y: pos2.y,
        distance: top3[1].distance,
      );

      final beacon3 = BeaconPosition(
        id: top3[2].id,
        x: pos3.x,
        y: pos3.y,
        distance: top3[2].distance,
      );

      final position = _trilaterate(beacon1, beacon2, beacon3);
      
      // Validate position is within store bounds
      if (isValidPosition(position)) {
        _currentPosition = position;
        return position;
      } else {
        debugPrint('Calculated position is outside store bounds: $position');
        return null;
      }
    } catch (e) {
      debugPrint('Error calculating position: $e');
      return null;
    }
  }

  /// Trilateration algorithm
  Position _trilaterate(
    BeaconPosition b1,
    BeaconPosition b2,
    BeaconPosition b3,
  ) {
    // Convert to coordinate system with b1 at origin
    final x21 = b2.x - b1.x;
    final y21 = b2.y - b1.y;
    final x31 = b3.x - b1.x;
    final y31 = b3.y - b1.y;

    // Squared distances
    final d1sq = b1.distance * b1.distance;
    final d2sq = b2.distance * b2.distance;
    final d3sq = b3.distance * b3.distance;

    // Calculate position
    final a = 2 * x21;
    final b = 2 * y21;
    final c = d1sq - d2sq - (x21 * x21) - (y21 * y21);
    final d = 2 * x31;
    final e = 2 * y31;
    final f = d1sq - d3sq - (x31 * x31) - (y31 * y31);

    // Solve for x and y
    final denominator = (e * a) - (b * d);
    if (denominator == 0) {
      // Beacons are collinear, use weighted average
      return _weightedAveragePosition([b1, b2, b3]);
    }

    final x = ((c * e) - (f * b)) / denominator;
    final y = ((c * d) - (a * f)) / (b * d - a * e);

    // Convert back to original coordinate system
    return Position(
      x: x + b1.x,
      y: y + b1.y,
    );
  }

  /// Fallback: weighted average position
  Position _weightedAveragePosition(List<BeaconPosition> beacons) {
    double totalWeight = 0.0;
    double weightedX = 0.0;
    double weightedY = 0.0;

    for (final beacon in beacons) {
      // Weight inversely proportional to distance
      final weight = 1.0 / (beacon.distance + 0.1);
      totalWeight += weight;
      weightedX += beacon.x * weight;
      weightedY += beacon.y * weight;
    }

    return Position(
      x: weightedX / totalWeight,
      y: weightedY / totalWeight,
    );
  }

  // ============================================================================
  // ROUTE CALCULATION
  // ============================================================================

  /// Calculate optimal route through multiple destinations
  List<Position> calculateRoute(
    Position start,
    List<Position> destinations,
  ) {
    if (destinations.isEmpty) {
      return [start];
    }

    // Use nearest neighbor algorithm for route optimization
    return _nearestNeighborRoute(start, destinations);
  }

  /// Nearest Neighbor TSP approximation
  List<Position> _nearestNeighborRoute(
    Position start,
    List<Position> destinations,
  ) {
    final route = <Position>[start];
    final remaining = List<Position>.from(destinations);
    Position current = start;

    while (remaining.isNotEmpty) {
      // Find nearest unvisited destination
      Position? nearest;
      double minDistance = double.infinity;

      for (final dest in remaining) {
        final dist = calculateDistance(current, dest);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = dest;
        }
      }

      if (nearest != null) {
        route.add(nearest);
        remaining.remove(nearest);
        current = nearest;
      }
    }

    return route;
  }

  /// Calculate optimal shopping route with product locations
  Future<List<Position>> calculateShoppingRoute(
    Position userPosition,
    List<ProductModel> products,
  ) async {
    // Extract product positions
    final destinations = products.map((p) {
      return Position(
        x: p.location.coordinates.x,
        y: p.location.coordinates.y,
      );
    }).toList();

    return calculateRoute(userPosition, destinations);
  }

  // ============================================================================
  // DIRECTION GENERATION
  // ============================================================================

  /// Generate turn-by-turn directions from route
  List<Direction> getDirections(List<Position> route) {
    if (route.length < 2) {
      return [];
    }

    final directions = <Direction>[];

    for (int i = 0; i < route.length - 1; i++) {
      final current = route[i];
      final next = route[i + 1];
      final distance = calculateDistance(current, next);

      DirectionType type;
      String instruction;

      if (i == 0) {
        type = DirectionType.forward;
        instruction = 'Head towards next item';
      } else if (i == route.length - 2) {
        type = DirectionType.arrived;
        instruction = 'Arrive at destination';
      } else {
        final previous = route[i - 1];
        final angle = _calculateTurnAngle(previous, current, next);

        if (angle < -15) {
          type = DirectionType.turnLeft;
          instruction = 'Turn left';
        } else if (angle > 15) {
          type = DirectionType.turnRight;
          instruction = 'Turn right';
        } else {
          type = DirectionType.forward;
          instruction = 'Continue straight';
        }
      }

      directions.add(Direction(
        type: type,
        instruction: instruction,
        distance: distance,
        position: next,
      ));
    }

    return directions;
  }

  /// Calculate turn angle in degrees
  double _calculateTurnAngle(Position p1, Position p2, Position p3) {
    final angle1 = math.atan2(p2.y - p1.y, p2.x - p1.x);
    final angle2 = math.atan2(p3.y - p2.y, p3.x - p2.x);
    
    double angle = (angle2 - angle1) * 180 / math.pi;
    
    // Normalize to -180 to 180
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    
    return angle;
  }

  // ============================================================================
  // DISTANCE CALCULATIONS
  // ============================================================================

  /// Calculate Euclidean distance between two points
  double calculateDistance(Position p1, Position p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate Manhattan distance (for grid-based navigation)
  double calculateManhattanDistance(Position p1, Position p2) {
    return (p1.x - p2.x).abs() + (p1.y - p2.y).abs();
  }

  /// Calculate total route distance
  double calculateTotalDistance(List<Position> route) {
    if (route.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      total += calculateDistance(route[i], route[i + 1]);
    }
    return total;
  }

  // ============================================================================
  // TIME ESTIMATION
  // ============================================================================

  /// Estimate time to complete route
  Duration estimateTime(List<Position> route, {double walkingSpeed = 1.4}) {
    // Walking speed in m/s (default: 1.4 m/s indoor average)
    final distance = calculateTotalDistance(route);
    
    // Add buffer time for each item (20 seconds per item)
    final itemTime = (route.length - 1) * 20;
    
    final walkTime = distance / walkingSpeed;
    final totalSeconds = walkTime + itemTime;
    
    return Duration(seconds: totalSeconds.round());
  }

  // ============================================================================
  // POSITION ACCURACY
  // ============================================================================

  /// Calculate position accuracy based on beacon quality
  double calculatePositionAccuracy(List<BeaconData> beacons) {
    if (beacons.length < 3) {
      return 10.0; // Low accuracy indicator
    }

    // More beacons and better RSSI = higher accuracy
    final avgRssi = beacons.map((b) => b.rssi).reduce((a, b) => a + b) / beacons.length;
    
    // Estimate accuracy in meters (better RSSI = lower value = higher accuracy)
    if (avgRssi >= -60) return 2.0;
    if (avgRssi >= -70) return 3.0;
    if (avgRssi >= -80) return 5.0;
    return 8.0;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if position is within store bounds
  bool isValidPosition(Position position) {
    return position.x >= 0 &&
        position.x <= storeWidth &&
        position.y >= 0 &&
        position.y <= storeHeight;
  }

  /// Get aisle from position (simplified)
  String getAisleFromPosition(Position position) {
    // Simplified aisle calculation
    // In production, this would use actual store layout data
    final aisleNumber = (position.x / 5).floor() + 1;
    return 'Aisle $aisleNumber';
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class Position {
  final double x;
  final double y;

  Position({
    required this.x,
    required this.y,
  });

  @override
  String toString() => 'Position(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class BeaconPosition {
  final String id;
  final double x;
  final double y;
  final double distance;

  BeaconPosition({
    required this.id,
    required this.x,
    required this.y,
    required this.distance,
  });
}

class Direction {
  final DirectionType type;
  final String instruction;
  final double distance;
  final Position position;

  Direction({
    required this.type,
    required this.instruction,
    required this.distance,
    required this.position,
  });

  String get distanceDisplay {
    if (distance < 1) {
      return '${(distance * 100).round()} cm';
    }
    return '${distance.toStringAsFixed(1)} m';
  }
}

enum DirectionType {
  forward,
  turnLeft,
  turnRight,
  arrived,
}

extension DirectionTypeExtension on DirectionType {
  String get displayName {
    switch (this) {
      case DirectionType.forward:
        return 'Go Forward';
      case DirectionType.turnLeft:
        return 'Turn Left';
      case DirectionType.turnRight:
        return 'Turn Right';
      case DirectionType.arrived:
        return 'Arrived';
    }
  }
}


