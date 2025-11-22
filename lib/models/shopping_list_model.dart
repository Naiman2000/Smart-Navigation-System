import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListModel {
  final String listId;
  final String userId;
  final String listName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShoppingItem> items;
  final bool isActive;
  final int totalItems;
  final int completedItems;

  ShoppingListModel({
    required this.listId,
    required this.userId,
    required this.listName,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.isActive,
    required this.totalItems,
    required this.completedItems,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'listId': listId,
      'userId': userId,
      'listName': listName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'items': items.map((item) => item.toJson()).toList(),
      'isActive': isActive,
      'totalItems': totalItems,
      'completedItems': completedItems,
    };
  }

  // Create from Firestore document
  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return ShoppingListModel(
      listId: json['listId'] as String,
      userId: json['userId'] as String,
      listName: json['listName'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      items: itemsList
          .map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      totalItems: json['totalItems'] as int,
      completedItems: json['completedItems'] as int,
    );
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (totalItems == 0) return 0.0;
    return (completedItems / totalItems) * 100;
  }

  // Check if all items are completed
  bool get isCompleted {
    return totalItems > 0 && completedItems == totalItems;
  }

  // Get remaining items count
  int get remainingItems {
    return totalItems - completedItems;
  }

  ShoppingListModel copyWith({
    String? listId,
    String? userId,
    String? listName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShoppingItem>? items,
    bool? isActive,
    int? totalItems,
    int? completedItems,
  }) {
    return ShoppingListModel(
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      listName: listName ?? this.listName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      isActive: isActive ?? this.isActive,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
    );
  }
}

class ShoppingItem {
  final String itemId;
  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final bool isCompleted;
  final DateTime addedAt;

  ShoppingItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.isCompleted,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'isCompleted': isCompleted,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      itemId: json['itemId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      isCompleted: json['isCompleted'] as bool,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
    );
  }

  ShoppingItem copyWith({
    String? itemId,
    String? productId,
    String? productName,
    int? quantity,
    String? unit,
    bool? isCompleted,
    DateTime? addedAt,
  }) {
    return ShoppingItem(
      itemId: itemId ?? this.itemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  // Format quantity with unit for display
  String get quantityDisplay {
    return '$quantity $unit';
  }
}

// Common units for shopping items
class ShoppingUnit {
  static const String piece = 'piece';
  static const String kg = 'kg';
  static const String gram = 'g';
  static const String liter = 'L';
  static const String ml = 'ml';
  static const String pack = 'pack';
  static const String box = 'box';
  static const String bag = 'bag';
  static const String bottle = 'bottle';
  static const String can = 'can';

  static List<String> get all => [
        piece,
        kg,
        gram,
        liter,
        ml,
        pack,
        box,
        bag,
        bottle,
        can,
      ];
}


