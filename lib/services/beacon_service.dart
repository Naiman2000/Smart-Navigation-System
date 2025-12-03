import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BeaconService {
  // Singleton pattern
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  // Stream controller for beacon data
  final StreamController<List<BeaconData>> _beaconController =
      StreamController<List<BeaconData>>.broadcast();

  // List to store detected beacons
  final List<BeaconData> _detectedBeacons = [];

  // Scanning state
  bool _isScanning = false;

  // RSSI readings buffer for smoothing
  final Map<String, List<int>> _rssiBuffer = {};
  static const int _rssiBufferSize = 5;

  // Stream of detected beacons
  Stream<List<BeaconData>> get beaconStream => _beaconController.stream;

  // Check if currently scanning
  bool get isScanning => _isScanning;

  // ============================================================================
  // INITIALIZATION AND PERMISSIONS
  // ============================================================================

  /// Initialize Bluetooth
  Future<bool> initializeBluetooth() async {
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not available on this device');
      }

      // Check if Bluetooth is turned on
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        // Request to turn on Bluetooth
        await FlutterBluePlus.turnOn();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to initialize Bluetooth: $e');
      return false;
    }
  }

  // ============================================================================
  // SCANNING METHODS
  // ============================================================================

  /// Start scanning for beacons
  Future<void> startScanning() async {
    if (_isScanning) {
      debugPrint('Already scanning');
      return;
    }

    try {
      // Initialize Bluetooth
      final initialized = await initializeBluetooth();
      if (!initialized) {
        throw Exception('Failed to initialize Bluetooth');
      }

      _isScanning = true;
      _detectedBeacons.clear();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      // Listen for scan state
      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _isScanning) {
          // Restart scanning to make it continuous
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isScanning) {
              FlutterBluePlus.startScan(
                timeout: const Duration(seconds: 4),
                androidUsesFineLocation: true,
              );
            }
          });
        }
      });

      debugPrint('Beacon scanning started');
    } catch (e) {
      _isScanning = false;
      throw Exception('Failed to start scanning: $e');
    }
  }

  /// Stop scanning for beacons
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      _detectedBeacons.clear();
      _rssiBuffer.clear();
      debugPrint('Beacon scanning stopped');
    } catch (e) {
      debugPrint('Failed to stop scanning: $e');
    }
  }

  /// Process scan results
  void _processScanResults(List<ScanResult> results) {
    _detectedBeacons.clear();

    for (final result in results) {
      // Filter for beacon devices (adjust filter as needed)
      if (_isBeaconDevice(result)) {
        final smoothedRssi = _smoothRSSI(result.device.remoteId.str, result.rssi);
        final distance = calculateDistance(smoothedRssi, result.advertisementData.txPowerLevel ?? -59);

        final beacon = BeaconData(
          id: result.device.remoteId.str,
          name: result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Unknown',
          rssi: smoothedRssi,
          distance: distance,
          timestamp: DateTime.now(),
        );

        _detectedBeacons.add(beacon);
      }
    }

    // Sort by signal strength (closest first)
    _detectedBeacons.sort((a, b) => b.rssi.compareTo(a.rssi));

    // Emit updated beacon list
    _beaconController.add(List.from(_detectedBeacons));
  }

  /// Check if device is a beacon
  bool _isBeaconDevice(ScanResult result) {
    // Filter logic - adjust based on your beacon specifications
    // Option 1: Filter by device name
    final name = result.device.platformName.toLowerCase();
    if (name.contains('beacon') || name.contains('ibeacon')) {
      return true;
    }

    // Option 2: Filter by manufacturer data (for iBeacon)
    final manufacturerData = result.advertisementData.manufacturerData;
    if (manufacturerData.containsKey(0x004C)) {
      // Apple's company identifier for iBeacon
      return true;
    }

    // Option 3: Accept all BLE devices (for testing)
    // Remove or adjust this in production
    return result.rssi > -90; // Only devices with reasonable signal strength
  }

  // ============================================================================
  // DISTANCE CALCULATION
  // ============================================================================

  /// Calculate distance from RSSI using Log-Distance Path Loss Model
  double calculateDistance(int rssi, int txPower) {
    if (rssi == 0) {
      return -1.0; // Invalid reading
    }

    // Path loss exponent (typically 2.0-4.0 for indoor environments)
    const double pathLossExponent = 2.5;

    // Calculate distance using formula:
    // distance = 10 ^ ((txPower - rssi) / (10 * n))
    final ratio = (txPower - rssi) / (10 * pathLossExponent);
    final distance = math.pow(10, ratio).toDouble();

    return double.parse(distance.toStringAsFixed(2));
  }

  /// Alternative distance calculation using ratio method
  double estimateDistance(int rssi, int measuredPower) {
    if (rssi == 0) {
      return -1.0;
    }

    final ratio = rssi * 1.0 / measuredPower;
    
    if (ratio < 1.0) {
      return double.parse(math.pow(ratio, 10).toStringAsFixed(2));
    } else {
      final distance = (0.89976) * math.pow(ratio, 7.7095) + 0.111;
      return double.parse(distance.toStringAsFixed(2));
    }
  }

  // ============================================================================
  // RSSI SMOOTHING
  // ============================================================================

  /// Smooth RSSI readings using moving average
  int _smoothRSSI(String deviceId, int rssi) {
    // Initialize buffer for this device if not exists
    if (!_rssiBuffer.containsKey(deviceId)) {
      _rssiBuffer[deviceId] = [];
    }

    // Add new reading
    _rssiBuffer[deviceId]!.add(rssi);

    // Keep only last N readings
    if (_rssiBuffer[deviceId]!.length > _rssiBufferSize) {
      _rssiBuffer[deviceId]!.removeAt(0);
    }

    // Calculate average
    final sum = _rssiBuffer[deviceId]!.reduce((a, b) => a + b);
    return (sum / _rssiBuffer[deviceId]!.length).round();
  }

  // ============================================================================
  // FILTERING METHODS
  // ============================================================================

  /// Filter beacons by proximity (maximum distance)
  List<BeaconData> filterBeaconsByProximity(
    List<BeaconData> beacons,
    double maxDistance,
  ) {
    return beacons
        .where((beacon) => beacon.distance > 0 && beacon.distance <= maxDistance)
        .toList();
  }

  /// Get nearest beacon
  BeaconData? getNearestBeacon(List<BeaconData> beacons) {
    if (beacons.isEmpty) return null;

    return beacons.reduce((a, b) =>
        a.distance < b.distance && a.distance > 0 ? a : b);
  }

  /// Get top N closest beacons
  List<BeaconData> getClosestBeacons(List<BeaconData> beacons, int count) {
    final validBeacons = beacons.where((b) => b.distance > 0).toList();
    validBeacons.sort((a, b) => a.distance.compareTo(b.distance));
    return validBeacons.take(count).toList();
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose resources
  void dispose() {
    stopScanning();
    _beaconController.close();
  }
}

// ============================================================================
// BEACON DATA MODEL
// ============================================================================

class BeaconData {
  final String id;
  final String name;
  final int rssi;
  final double distance;
  final DateTime timestamp;

  BeaconData({
    required this.id,
    required this.name,
    required this.rssi,
    required this.distance,
    required this.timestamp,
  });

  // Signal strength quality indicator
  SignalStrength get signalStrength {
    if (rssi >= -50) return SignalStrength.excellent;
    if (rssi >= -60) return SignalStrength.good;
    if (rssi >= -70) return SignalStrength.fair;
    if (rssi >= -80) return SignalStrength.poor;
    return SignalStrength.veryPoor;
  }

  // Proximity indicator
  Proximity get proximity {
    if (distance < 0) return Proximity.unknown;
    if (distance <= 1.0) return Proximity.immediate;
    if (distance <= 3.0) return Proximity.near;
    if (distance <= 10.0) return Proximity.far;
    return Proximity.veryFar;
  }

  @override
  String toString() {
    return 'BeaconData(id: $id, name: $name, rssi: $rssi, distance: ${distance}m)';
  }
}

// ============================================================================
// ENUMS
// ============================================================================

enum SignalStrength {
  excellent,
  good,
  fair,
  poor,
  veryPoor,
}

enum Proximity {
  immediate, // < 1m
  near, // 1-3m
  far, // 3-10m
  veryFar, // > 10m
  unknown,
}

extension SignalStrengthExtension on SignalStrength {
  String get displayName {
    switch (this) {
      case SignalStrength.excellent:
        return 'Excellent';
      case SignalStrength.good:
        return 'Good';
      case SignalStrength.fair:
        return 'Fair';
      case SignalStrength.poor:
        return 'Poor';
      case SignalStrength.veryPoor:
        return 'Very Poor';
    }
  }
}

extension ProximityExtension on Proximity {
  String get displayName {
    switch (this) {
      case Proximity.immediate:
        return 'Immediate';
      case Proximity.near:
        return 'Near';
      case Proximity.far:
        return 'Far';
      case Proximity.veryFar:
        return 'Very Far';
      case Proximity.unknown:
        return 'Unknown';
    }
  }
}


