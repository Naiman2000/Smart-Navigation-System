import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_layout_model.dart';

/// Model representing a configured BLE beacon
class BeaconModel {
  final String beaconId;
  final String name;
  final String macAddress;
  final Point position;
  final int txPower;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BeaconModel({
    required this.beaconId,
    required this.name,
    required this.macAddress,
    required this.position,
    required this.txPower,
    this.isActive = true,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory BeaconModel.fromJson(Map<String, dynamic> json) {
    return BeaconModel(
      beaconId: json['beaconId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      position: Point(
        x: (json['position'] as Map<String, dynamic>?)?['x'] as double? ?? 0.0,
        y: (json['position'] as Map<String, dynamic>?)?['y'] as double? ?? 0.0,
      ),
      txPower: json['txPower'] as int? ?? -59,
      isActive: json['isActive'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'beaconId': beaconId,
      'name': name,
      'macAddress': macAddress,
      'position': {
        'x': position.x,
        'y': position.y,
      },
      'txPower': txPower,
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  BeaconModel copyWith({
    String? beaconId,
    String? name,
    String? macAddress,
    Point? position,
    int? txPower,
    bool? isActive,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeaconModel(
      beaconId: beaconId ?? this.beaconId,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      position: position ?? this.position,
      txPower: txPower ?? this.txPower,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BeaconModel(id: $beaconId, name: $name, macAddress: $macAddress, position: (${position.x}, ${position.y}), txPower: $txPower, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeaconModel && other.beaconId == beaconId;
  }

  @override
  int get hashCode => beaconId.hashCode;
}
