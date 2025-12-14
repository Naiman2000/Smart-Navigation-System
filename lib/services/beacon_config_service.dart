import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/beacon_model.dart';
import '../models/store_layout_model.dart';
import 'firebase_service.dart';

/// Service for managing beacon configurations
/// Wraps FirebaseService to provide a cleaner interface
class BeaconConfigService {
  // Singleton pattern
  static final BeaconConfigService _instance = BeaconConfigService._internal();
  factory BeaconConfigService() => _instance;
  BeaconConfigService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Cache for beacon positions (for performance)
  final Map<String, Point> _positionCache = {};
  StreamSubscription<List<BeaconModel>>? _beaconsSubscription;

  // ============================================================================
  // BEACON CRUD OPERATIONS
  // ============================================================================

  /// Save or update beacon configuration
  Future<void> saveBeacon(BeaconModel beacon) async {
    try {
      final now = DateTime.now();
      final beaconToSave = beacon.copyWith(
        updatedAt: now,
        createdAt: beacon.createdAt == beacon.updatedAt ? now : beacon.createdAt,
      );
      
      await _firebaseService.createBeacon(beaconToSave);
      
      // Update cache
      _positionCache[beacon.beaconId] = beacon.position;
      
      debugPrint('Beacon saved: ${beacon.beaconId}');
    } catch (e) {
      throw Exception('Failed to save beacon: $e');
    }
  }

  /// Get beacon by ID
  Future<BeaconModel?> getBeacon(String beaconId) async {
    try {
      return await _firebaseService.getBeacon(beaconId);
    } catch (e) {
      throw Exception('Failed to get beacon: $e');
    }
  }

  /// Get all configured beacons
  Future<List<BeaconModel>> getAllBeacons({bool activeOnly = false}) async {
    try {
      final beacons = await _firebaseService.getAllBeacons(activeOnly: activeOnly);
      
      // Update cache
      for (final beacon in beacons) {
        _positionCache[beacon.beaconId] = beacon.position;
      }
      
      return beacons;
    } catch (e) {
      throw Exception('Failed to get beacons: $e');
    }
  }

  /// Get real-time stream of beacons
  Stream<List<BeaconModel>> getBeaconsStream({bool activeOnly = false}) {
    return _firebaseService.getBeaconsStream(activeOnly: activeOnly)
      ..listen((beacons) {
        // Update cache when beacons change
        _positionCache.clear();
        for (final beacon in beacons) {
          _positionCache[beacon.beaconId] = beacon.position;
        }
      });
  }

  /// Delete beacon
  Future<void> deleteBeacon(String beaconId) async {
    try {
      await _firebaseService.deleteBeacon(beaconId);
      _positionCache.remove(beaconId);
      debugPrint('Beacon deleted: $beaconId');
    } catch (e) {
      throw Exception('Failed to delete beacon: $e');
    }
  }

  /// Update beacon position
  Future<void> updateBeaconPosition(String beaconId, Point position) async {
    try {
      await _firebaseService.updateBeacon(beaconId, {
        'position': {'x': position.x, 'y': position.y},
      });
      _positionCache[beaconId] = position;
    } catch (e) {
      throw Exception('Failed to update beacon position: $e');
    }
  }

  /// Update beacon name
  Future<void> updateBeaconName(String beaconId, String name) async {
    try {
      await _firebaseService.updateBeacon(beaconId, {'name': name});
    } catch (e) {
      throw Exception('Failed to update beacon name: $e');
    }
  }

  /// Update beacon transmit power
  Future<void> updateBeaconTxPower(String beaconId, int txPower) async {
    try {
      await _firebaseService.updateBeacon(beaconId, {'txPower': txPower});
    } catch (e) {
      throw Exception('Failed to update beacon txPower: $e');
    }
  }

  /// Toggle beacon active status
  Future<void> toggleBeaconActive(String beaconId, bool isActive) async {
    try {
      await _firebaseService.updateBeacon(beaconId, {'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to toggle beacon active status: $e');
    }
  }

  /// Update beacon last seen timestamp
  Future<void> updateBeaconLastSeen(String beaconId) async {
    try {
      await _firebaseService.updateBeaconLastSeen(beaconId);
    } catch (e) {
      // Silently fail - not critical
      debugPrint('Failed to update beacon last seen: $e');
    }
  }

  // ============================================================================
  // POSITION LOOKUP (for trilateration)
  // ============================================================================

  /// Get beacon position for trilateration
  /// Returns null if beacon not found or not active
  Future<Point?> getBeaconPosition(String beaconId) async {
    // Check cache first
    if (_positionCache.containsKey(beaconId)) {
      return _positionCache[beaconId];
    }

    // Fetch from Firestore
    try {
      final beacon = await getBeacon(beaconId);
      if (beacon != null && beacon.isActive) {
        _positionCache[beaconId] = beacon.position;
        return beacon.position;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get beacon position: $e');
      return null;
    }
  }

  /// Get positions for multiple beacons (batch lookup)
  Future<Map<String, Point>> getBeaconPositions(List<String> beaconIds) async {
    final positions = <String, Point>{};
    
    for (final id in beaconIds) {
      final position = await getBeaconPosition(id);
      if (position != null) {
        positions[id] = position;
      }
    }
    
    return positions;
  }

  /// Initialize cache by loading all active beacons
  Future<void> initializeCache() async {
    try {
      final beacons = await getAllBeacons(activeOnly: true);
      _positionCache.clear();
      for (final beacon in beacons) {
        _positionCache[beacon.beaconId] = beacon.position;
      }
      debugPrint('Beacon cache initialized with ${_positionCache.length} beacons');
    } catch (e) {
      debugPrint('Failed to initialize beacon cache: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _positionCache.clear();
  }

  // ============================================================================
  // PROXIMITY HELPERS (for product location binding)
  // ============================================================================

  /// Get all beacons within a specified radius of a position
  Future<List<BeaconModel>> getBeaconsNearPosition(
    Point position,
    double radius,
  ) async {
    try {
      final allBeacons = await getAllBeacons(activeOnly: true);
      final nearbyBeacons = <BeaconModel>[];

      for (final beacon in allBeacons) {
        final distance = _calculateDistance(position, beacon.position);
        if (distance <= radius) {
          nearbyBeacons.add(beacon);
        }
      }

      // Sort by distance (closest first)
      nearbyBeacons.sort((a, b) {
        final distA = _calculateDistance(position, a.position);
        final distB = _calculateDistance(position, b.position);
        return distA.compareTo(distB);
      });

      return nearbyBeacons;
    } catch (e) {
      debugPrint('Failed to get beacons near position: $e');
      return [];
    }
  }

  /// Find the nearest beacon to a given position
  /// Returns null if no active beacons found
  Future<BeaconModel?> findNearestBeacon(Point position) async {
    try {
      final allBeacons = await getAllBeacons(activeOnly: true);
      if (allBeacons.isEmpty) {
        return null;
      }

      BeaconModel? nearest;
      double minDistance = double.infinity;

      for (final beacon in allBeacons) {
        final distance = _calculateDistance(position, beacon.position);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = beacon;
        }
      }

      return nearest;
    } catch (e) {
      debugPrint('Failed to find nearest beacon: $e');
      return null;
    }
  }

  /// Calculate Euclidean distance between two points
  double _calculateDistance(Point p1, Point p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if beacon is configured
  Future<bool> isBeaconConfigured(String beaconId) async {
    final beacon = await getBeacon(beaconId);
    return beacon != null;
  }

  /// Get active beacons count
  Future<int> getActiveBeaconsCount() async {
    final beacons = await getAllBeacons(activeOnly: true);
    return beacons.length;
  }

  /// Dispose resources
  void dispose() {
    _beaconsSubscription?.cancel();
    _positionCache.clear();
  }
}
