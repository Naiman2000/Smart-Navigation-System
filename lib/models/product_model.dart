import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String name;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final ProductLocation location;
  final bool inStock;
  final DateTime lastUpdated;

  ProductModel({
    required this.productId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.inStock,
    required this.lastUpdated,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'location': location.toJson(),
      'inStock': inStock,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Create from Firestore document
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      location: ProductLocation.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      inStock: json['inStock'] as bool? ?? true,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
    );
  }

  ProductModel copyWith({
    String? productId,
    String? name,
    String? category,
    String? description,
    double? price,
    String? imageUrl,
    ProductLocation? location,
    bool? inStock,
    DateTime? lastUpdated,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      inStock: inStock ?? this.inStock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ProductLocation {
  final String aisle;
  final String section;
  final int shelf;
  final String beaconId;
  final Coordinates coordinates;

  ProductLocation({
    required this.aisle,
    required this.section,
    required this.shelf,
    required this.beaconId,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      'aisle': aisle,
      'section': section,
      'shelf': shelf,
      'beaconId': beaconId,
      'coordinates': coordinates.toJson(),
    };
  }

  factory ProductLocation.fromJson(Map<String, dynamic> json) {
    return ProductLocation(
      aisle: json['aisle'] as String,
      section: json['section'] as String,
      shelf: json['shelf'] as int,
      beaconId: json['beaconId'] as String,
      coordinates: Coordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
    );
  }

  ProductLocation copyWith({
    String? aisle,
    String? section,
    int? shelf,
    String? beaconId,
    Coordinates? coordinates,
  }) {
    return ProductLocation(
      aisle: aisle ?? this.aisle,
      section: section ?? this.section,
      shelf: shelf ?? this.shelf,
      beaconId: beaconId ?? this.beaconId,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class Coordinates {
  final double x;
  final double y;

  Coordinates({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Coordinates copyWith({
    double? x,
    double? y,
  }) {
    return Coordinates(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

// Product categories enum
enum ProductCategory {
  dairy,
  meat,
  bakery,
  produce,
  beverages,
  frozen,
  pantry,
  household,
  personalCare,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.dairy:
        return 'Dairy & Eggs';
      case ProductCategory.meat:
        return 'Meat & Seafood';
      case ProductCategory.bakery:
        return 'Bakery';
      case ProductCategory.produce:
        return 'Produce';
      case ProductCategory.beverages:
        return 'Beverages';
      case ProductCategory.frozen:
        return 'Frozen Foods';
      case ProductCategory.pantry:
        return 'Pantry Staples';
      case ProductCategory.household:
        return 'Household Items';
      case ProductCategory.personalCare:
        return 'Personal Care';
    }
  }
}


