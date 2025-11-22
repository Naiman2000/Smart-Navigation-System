import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
  });

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences.toJson(),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp).toDate(),
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserPreferences {
  final bool notifications;
  final String language;
  final String theme;

  UserPreferences({
    required this.notifications,
    required this.language,
    required this.theme,
  });

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications,
      'language': language,
      'theme': theme,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifications: json['notifications'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'light',
    );
  }

  // Default preferences
  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      notifications: true,
      language: 'en',
      theme: 'light',
    );
  }

  UserPreferences copyWith({
    bool? notifications,
    String? language,
    String? theme,
  }) {
    return UserPreferences(
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}


