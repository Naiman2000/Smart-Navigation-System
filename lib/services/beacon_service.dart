import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'beacon_config_service.dart';

class BeaconService {
  // Singleton pattern
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  // Stream controller for beacon data
  final StreamController<List<BeaconData>> _beaconController =
      StreamController<List<BeaconData>>.broadcast();

  // Stream controller for discovery mode (all BLE devices)
  final StreamController<List<DiscoveredDevice>> _discoveryController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  // List to store detected beacons
  final List<BeaconData> _detectedBeacons = [];

  // List to store discovered devices (for pairing)
  final List<DiscoveredDevice> _discoveredDevices = [];

  // Scanning state
  bool _isScanning = false;
  bool _isDiscoveryMode = false;

  // RSSI readings buffer for smoothing
  final Map<String, List<int>> _rssiBuffer = {};
  static const int _rssiBufferSize = 5;

  // Beacon config service for checking configured beacons
  final BeaconConfigService _beaconConfigService = BeaconConfigService();
  Set<String> _configuredBeaconIds = {};

  // Stream of detected beacons (configured beacons only)
  Stream<List<BeaconData>> get beaconStream => _beaconController.stream;

  // Stream of discovered devices (for pairing screen)
  Stream<List<DiscoveredDevice>> get discoveryStream => _discoveryController.stream;

  // Check if currently scanning
  bool get isScanning => _isScanning;

  // Check if in discovery mode
  bool get isDiscoveryMode => _isDiscoveryMode;

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

  /// Start scanning for beacons (configured beacons only)
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

      // Load configured beacon IDs
      await _loadConfiguredBeaconIds();

      _isScanning = true;
      _detectedBeacons.clear();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        if (_isDiscoveryMode) {
          _processDiscoveryResults(results);
        } else {
          _processScanResults(results);
        }
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

  /// Start discovery mode (shows all BLE devices for pairing)
  Future<void> startDiscoveryMode() async {
    if (_isScanning && !_isDiscoveryMode) {
      await stopScanning();
    }

    if (_isDiscoveryMode) {
      debugPrint('Already in discovery mode');
      return;
    }

    try {
      // Initialize Bluetooth
      final initialized = await initializeBluetooth();
      if (!initialized) {
        throw Exception('Failed to initialize Bluetooth');
      }

      // Request permissions if needed (flutter_blue_plus handles this, but we ensure it's done)
      // The package will automatically request permissions when startScan is called
      
      // Load configured beacon IDs to filter them out
      await _loadConfiguredBeaconIds();

      _isDiscoveryMode = true;
      _isScanning = true;
      _discoveredDevices.clear();

      // Start scanning - flutter_blue_plus will request permissions automatically
      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: true,
        );
      } catch (e) {
        // Re-throw with more context if it's a permission error
        if (e.toString().contains('BLUETOOTH_SCAN') || 
            e.toString().contains('Permission')) {
          throw Exception(
            'Bluetooth permission required. Please grant Bluetooth and Location permissions in app settings.'
          );
        }
        rethrow;
      }

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        _processDiscoveryResults(results);
      });

      // Listen for scan state - when scan completes, stop discovery mode
      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _isDiscoveryMode) {
          // Scan completed, stop discovery mode automatically
          debugPrint('Discovery scan completed');
          _isDiscoveryMode = false;
          _isScanning = false;
        }
      });

      debugPrint('Discovery mode started');
    } catch (e) {
      _isDiscoveryMode = false;
      _isScanning = false;
      throw Exception('Failed to start discovery mode: $e');
    }
  }

  /// Stop discovery mode
  Future<void> stopDiscoveryMode() async {
    _isDiscoveryMode = false;
    _discoveredDevices.clear();
    await stopScanning();
    debugPrint('Discovery mode stopped');
  }

  /// Load configured beacon IDs from config service
  Future<void> _loadConfiguredBeaconIds() async {
    try {
      final beacons = await _beaconConfigService.getAllBeacons(activeOnly: true);
      _configuredBeaconIds = beacons.map((b) => b.beaconId).toSet();
      debugPrint('Loaded ${_configuredBeaconIds.length} configured beacon IDs');
    } catch (e) {
      debugPrint('Failed to load configured beacons: $e');
      _configuredBeaconIds.clear();
    }
  }

  /// Stop scanning for beacons
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      _isDiscoveryMode = false;
      _detectedBeacons.clear();
      _discoveredDevices.clear();
      _rssiBuffer.clear();
      debugPrint('Beacon scanning stopped');
    } catch (e) {
      debugPrint('Failed to stop scanning: $e');
    }
  }

  /// Process scan results (for configured beacons only)
  void _processScanResults(List<ScanResult> results) {
    _detectedBeacons.clear();

    for (final result in results) {
      final deviceId = result.device.remoteId.str;
      
      // Only process if it's a configured beacon
      if (_isBeaconDevice(result) && _configuredBeaconIds.contains(deviceId)) {
        // Get beacon config for txPower
        _beaconConfigService.getBeacon(deviceId).then((beacon) {
          final txPower = beacon?.txPower ?? -59;
          final smoothedRssi = _smoothRSSI(deviceId, result.rssi);
          final distance = calculateDistance(smoothedRssi, txPower);

          final beaconData = BeaconData(
            id: deviceId,
            name: beacon?.name ?? 
                (result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown'),
            rssi: smoothedRssi,
            distance: distance,
            timestamp: DateTime.now(),
          );

          _detectedBeacons.add(beaconData);
          
          // Update last seen timestamp
          _beaconConfigService.updateBeaconLastSeen(deviceId);

          // Sort and emit
          _detectedBeacons.sort((a, b) => b.rssi.compareTo(a.rssi));
          _beaconController.add(List.from(_detectedBeacons));
        });
      }
    }
  }

  /// Process discovery results (all BLE devices for pairing)
  void _processDiscoveryResults(List<ScanResult> results) {
    final deviceMap = <String, DiscoveredDevice>{};

    for (final result in results) {
      final deviceId = result.device.remoteId.str;
      final deviceName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'Unknown Device';

      // Skip already configured beacons
      if (_configuredBeaconIds.contains(deviceId)) {
        continue;
      }

      // Only show devices with reasonable signal strength
      if (result.rssi > -90) {
        deviceMap[deviceId] = DiscoveredDevice(
          id: deviceId,
          name: deviceName,
          macAddress: deviceId,
          rssi: result.rssi,
          timestamp: DateTime.now(),
          isConfigured: false,
        );
      }
    }

    // Update discovered devices list
    _discoveredDevices.clear();
    _discoveredDevices.addAll(deviceMap.values);
    _discoveredDevices.sort((a, b) => b.rssi.compareTo(a.rssi));

    // Emit updated discovery list
    _discoveryController.add(List.from(_discoveredDevices));
  }

  /// Check if device is a beacon
  /// In normal mode: checks if device is in configured beacons list
  /// In discovery mode: accepts all BLE devices with reasonable signal
  bool _isBeaconDevice(ScanResult result) {
    final deviceId = result.device.remoteId.str;

    // If in discovery mode, accept all devices with reasonable signal
    if (_isDiscoveryMode) {
      return result.rssi > -90;
    }

    // In normal mode, check if device is configured
    if (_configuredBeaconIds.contains(deviceId)) {
      return true;
    }

    // Also check by device name patterns (for backward compatibility)
    final name = result.device.platformName.toLowerCase();
    if (name.contains('beacon') || name.contains('ibeacon')) {
      return true;
    }

    // Check by manufacturer data (for iBeacon)
    final manufacturerData = result.advertisementData.manufacturerData;
    if (manufacturerData.containsKey(0x004C)) {
      // Apple's company identifier for iBeacon
      return true;
    }

    return false;
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

  /// Refresh configured beacon list (call after pairing new beacon)
  Future<void> refreshConfiguredBeacons() async {
    await _loadConfiguredBeaconIds();
  }

  /// Dispose resources
  void dispose() {
    stopScanning();
    _beaconController.close();
    _discoveryController.close();
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

// ============================================================================
// DISCOVERED DEVICE MODEL (for pairing screen)
// ============================================================================

class DiscoveredDevice {
  final String id;
  final String name;
  final String macAddress;
  final int rssi;
  final DateTime timestamp;
  final bool isConfigured;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    required this.timestamp,
    this.isConfigured = false,
  });

  SignalStrength get signalStrength {
    if (rssi >= -50) return SignalStrength.excellent;
    if (rssi >= -60) return SignalStrength.good;
    if (rssi >= -70) return SignalStrength.fair;
    if (rssi >= -80) return SignalStrength.poor;
    return SignalStrength.veryPoor;
  }

  @override
  String toString() {
    return 'DiscoveredDevice(id: $id, name: $name, macAddress: $macAddress, rssi: $rssi)';
  }
}


