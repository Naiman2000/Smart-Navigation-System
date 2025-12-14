import '../models/product_model.dart';
import '../models/store_layout_model.dart';
import 'beacon_service.dart';
import 'navigation_service.dart' show NavigationService, Position;

/// Service for detecting proximity to items using coordinate and beacon-based methods
class ProximityService {
  // Singleton pattern
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  final NavigationService _navigationService = NavigationService();

  /// Check proximity to items using coordinate-based distance calculation
  /// Returns items within the specified threshold distance
  List<ProximityResult> checkProximityToItems(
    Point? userPosition,
    List<ProductModel> items,
    double threshold,
  ) {
    if (userPosition == null) {
      return [];
    }

    final results = <ProximityResult>[];

    for (final item in items) {
      final itemPosition = Point(
        x: item.location.coordinates.x,
        y: item.location.coordinates.y,
      );

      final distance = _navigationService.calculateDistance(
        Position(x: userPosition.x, y: userPosition.y),
        Position(x: itemPosition.x, y: itemPosition.y),
      );

      if (distance <= threshold) {
        results.add(ProximityResult(
          product: item,
          distance: distance,
          method: ProximityMethod.coordinate,
        ));
      }
    }

    // Sort by distance (closest first)
    results.sort((a, b) => a.distance.compareTo(b.distance));

    return results;
  }

  /// Get the nearest item to user position
  ProximityResult? getNearestItem(
    Point? userPosition,
    List<ProductModel> items,
  ) {
    if (userPosition == null || items.isEmpty) {
      return null;
    }

    ProductModel? nearest;
    double minDistance = double.infinity;

    for (final item in items) {
      final itemPosition = Point(
        x: item.location.coordinates.x,
        y: item.location.coordinates.y,
      );

      final distance = _navigationService.calculateDistance(
        Position(x: userPosition.x, y: userPosition.y),
        Position(x: itemPosition.x, y: itemPosition.y),
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = item;
      }
    }

    if (nearest == null) {
      return null;
    }

    return ProximityResult(
      product: nearest,
      distance: minDistance,
      method: ProximityMethod.coordinate,
    );
  }

  /// Check proximity using beacon-based detection
  /// More accurate when item's beacon is detected
  List<ProximityResult> checkBeaconProximity(
    List<BeaconData> detectedBeacons,
    List<ProductModel> items,
    double threshold,
  ) {
    final results = <ProximityResult>[];
    final detectedBeaconIds = detectedBeacons.map((b) => b.id).toSet();

    for (final item in items) {
      final itemBeaconId = item.location.beaconId;

      // Check if item's beacon is in detected beacons
      if (detectedBeaconIds.contains(itemBeaconId)) {
        final beaconData = detectedBeacons.firstWhere((b) => b.id == itemBeaconId);
        final distance = beaconData.distance;

        if (distance > 0 && distance <= threshold) {
          results.add(ProximityResult(
            product: item,
            distance: distance,
            method: ProximityMethod.beacon,
            beaconRssi: beaconData.rssi,
          ));
        }
      }
    }

    // Sort by distance (closest first)
    results.sort((a, b) => a.distance.compareTo(b.distance));

    return results;
  }

  /// Combined proximity check using both methods
  /// Prefers beacon-based when available, falls back to coordinate-based
  List<ProximityResult> checkProximity(
    Point? userPosition,
    List<BeaconData> detectedBeacons,
    List<ProductModel> items,
    double threshold,
  ) {
    // First try beacon-based (more accurate)
    final beaconResults = checkBeaconProximity(detectedBeacons, items, threshold);

    // Get items already found via beacon
    final foundProductIds = beaconResults.map((r) => r.product.productId).toSet();

    // Add coordinate-based results for items not found via beacon
    if (userPosition != null) {
      final coordinateResults = checkProximityToItems(userPosition, items, threshold);
      for (final result in coordinateResults) {
        if (!foundProductIds.contains(result.product.productId)) {
          beaconResults.add(result);
        }
      }
    }

    // Sort by distance
    beaconResults.sort((a, b) => a.distance.compareTo(b.distance));

    return beaconResults;
  }

  /// Check if user is very close to an item (< 1m)
  bool isVeryClose(ProximityResult result) {
    return result.distance < 1.0;
  }

  /// Check if user is near an item (< 3m)
  bool isNear(ProximityResult result) {
    return result.distance < 3.0;
  }
}

/// Result of proximity check
class ProximityResult {
  final ProductModel product;
  final double distance;
  final ProximityMethod method;
  final int? beaconRssi;

  ProximityResult({
    required this.product,
    required this.distance,
    required this.method,
    this.beaconRssi,
  });

  /// Format distance for display
  String get distanceDisplay {
    if (distance < 1.0) {
      return '${(distance * 100).round()} cm';
    }
    return '${distance.toStringAsFixed(1)} m';
  }

  /// Get proximity level
  ProximityLevel get level {
    if (distance < 1.0) return ProximityLevel.veryClose;
    if (distance < 3.0) return ProximityLevel.near;
    return ProximityLevel.far;
  }
}

/// Method used for proximity detection
enum ProximityMethod {
  coordinate,
  beacon,
}

/// Proximity level
enum ProximityLevel {
  veryClose, // < 1m
  near, // 1-3m
  far, // > 3m
}

extension ProximityLevelExtension on ProximityLevel {
  String get displayName {
    switch (this) {
      case ProximityLevel.veryClose:
        return 'Very Close';
      case ProximityLevel.near:
        return 'Near';
      case ProximityLevel.far:
        return 'Far';
    }
  }
}

