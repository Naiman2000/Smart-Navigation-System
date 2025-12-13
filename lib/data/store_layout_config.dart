import 'package:flutter/material.dart';
import '../models/store_layout_model.dart';

/// Store layout configuration for a typical grocery store
/// Store dimensions: 50m × 30m
class StoreLayoutConfig {
  static const double storeWidth = 50.0; // meters
  static const double storeHeight = 30.0; // meters
  static const double aisleWidth = 2.5; // meters (width of each aisle)
  static const double sectionSpacing = 1.0; // meters between sections

  /// Get the default store layout
  static StoreLayout getDefaultLayout() {
    return StoreLayout(
      width: storeWidth,
      height: storeHeight,
      aisles: _getAisles(),
      sections: _getSections(),
      entryPoint: const Point(x: 23.5, y: 0.0), // Above aisle B2 area, in the gap between B2 (ends at 23.0) and C1 (starts at 25.0)
      checkoutArea: StoreRect(
        x: 23.0,
        y: 28.0,
        width: 2.0,
        height: 2.0,
      ), // Between B2 (ends at 23.0) and C1 (starts at 25.0), back area - clear of aisles
    );
  }

  /// Define aisles (vertical aisles running front to back)
  static List<Aisle> _getAisles() {
    return [
      // Left side aisles
      Aisle(
        id: 'A1',
        name: 'Aisle A1',
        bounds: StoreRect(x: 2.0, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Dairy & Eggs', 'Bakery'],
      ),
      Aisle(
        id: 'A2',
        name: 'Aisle A2',
        bounds: StoreRect(x: 6.5, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Meat & Seafood', 'Produce'],
      ),
      Aisle(
        id: 'A3',
        name: 'Aisle A3',
        bounds: StoreRect(x: 11.0, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Beverages', 'Pantry Staples'],
      ),
      // Center aisles
      Aisle(
        id: 'B1',
        name: 'Aisle B1',
        bounds: StoreRect(x: 16.0, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Frozen Foods', 'Snacks'],
      ),
      Aisle(
        id: 'B2',
        name: 'Aisle B2',
        bounds: StoreRect(x: 20.5, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Household Items', 'Personal Care'],
      ),
      // Right side aisles
      Aisle(
        id: 'C1',
        name: 'Aisle C1',
        bounds: StoreRect(x: 25.0, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Pantry Staples', 'Beverages'],
      ),
      Aisle(
        id: 'C2',
        name: 'Aisle C2',
        bounds: StoreRect(x: 29.5, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Produce', 'Meat & Seafood'],
      ),
      Aisle(
        id: 'C3',
        name: 'Aisle C3',
        bounds: StoreRect(x: 34.0, y: 0.0, width: aisleWidth, height: storeHeight),
        sections: ['Bakery', 'Dairy & Eggs'],
      ),
    ];
  }

  /// Define sections/departments
  static List<Section> _getSections() {
    return [
      // Left side sections
      Section(
        id: 'dairy',
        name: 'Dairy & Eggs',
        category: 'Dairy & Eggs',
        bounds: StoreRect(x: 0.0, y: 0.0, width: 2.0, height: 8.0),
        color: Colors.blue.shade50,
        icon: Icons.local_dining,
      ),
      Section(
        id: 'bakery-left',
        name: 'Bakery',
        category: 'Bakery',
        bounds: StoreRect(x: 0.0, y: 8.0, width: 2.0, height: 6.0),
        color: Colors.orange.shade50,
        icon: Icons.cake,
      ),
      Section(
        id: 'meat',
        name: 'Meat & Seafood',
        category: 'Meat & Seafood',
        bounds: StoreRect(x: 4.5, y: 0.0, width: 2.0, height: 10.0),
        color: Colors.red.shade50,
        icon: Icons.set_meal,
      ),
      Section(
        id: 'produce-left',
        name: 'Produce',
        category: 'Produce',
        bounds: StoreRect(x: 4.5, y: 10.0, width: 2.0, height: 8.0),
        color: Colors.green.shade50,
        icon: Icons.eco,
      ),
      Section(
        id: 'beverages-left',
        name: 'Beverages',
        category: 'Beverages',
        bounds: StoreRect(x: 9.0, y: 0.0, width: 2.0, height: 8.0),
        color: Colors.cyan.shade50,
        icon: Icons.local_drink,
      ),
      Section(
        id: 'pantry-left',
        name: 'Pantry Staples',
        category: 'Pantry Staples',
        bounds: StoreRect(x: 9.0, y: 8.0, width: 2.0, height: 10.0),
        color: Colors.brown.shade50,
        icon: Icons.kitchen,
      ),
      // Center sections
      Section(
        id: 'frozen',
        name: 'Frozen Foods',
        category: 'Frozen Foods',
        bounds: StoreRect(x: 14.0, y: 0.0, width: 2.0, height: 12.0),
        color: Colors.lightBlue.shade50,
        icon: Icons.ac_unit,
      ),
      Section(
        id: 'snacks',
        name: 'Snacks',
        category: 'Pantry Staples',
        bounds: StoreRect(x: 14.0, y: 12.0, width: 2.0, height: 6.0),
        color: Colors.amber.shade50,
        icon: Icons.cookie,
      ),
      Section(
        id: 'household',
        name: 'Household Items',
        category: 'Household Items',
        bounds: StoreRect(x: 18.5, y: 0.0, width: 2.0, height: 10.0),
        color: Colors.grey.shade100,
        icon: Icons.home,
      ),
      Section(
        id: 'personal-care',
        name: 'Personal Care',
        category: 'Personal Care',
        bounds: StoreRect(x: 18.5, y: 10.0, width: 2.0, height: 8.0),
        color: Colors.pink.shade50,
        icon: Icons.spa,
      ),
      // Right side sections
      Section(
        id: 'pantry-right',
        name: 'Pantry Staples',
        category: 'Pantry Staples',
        bounds: StoreRect(x: 23.0, y: 0.0, width: 2.0, height: 10.0),
        color: Colors.brown.shade50,
        icon: Icons.kitchen,
      ),
      Section(
        id: 'beverages-right',
        name: 'Beverages',
        category: 'Beverages',
        bounds: StoreRect(x: 23.0, y: 10.0, width: 2.0, height: 8.0),
        color: Colors.cyan.shade50,
        icon: Icons.local_drink,
      ),
      Section(
        id: 'produce-right',
        name: 'Produce',
        category: 'Produce',
        bounds: StoreRect(x: 27.5, y: 0.0, width: 2.0, height: 8.0),
        color: Colors.green.shade50,
        icon: Icons.eco,
      ),
      Section(
        id: 'meat-right',
        name: 'Meat & Seafood',
        category: 'Meat & Seafood',
        bounds: StoreRect(x: 27.5, y: 8.0, width: 2.0, height: 10.0),
        color: Colors.red.shade50,
        icon: Icons.set_meal,
      ),
      Section(
        id: 'bakery-right',
        name: 'Bakery',
        category: 'Bakery',
        bounds: StoreRect(x: 32.0, y: 0.0, width: 2.0, height: 6.0),
        color: Colors.orange.shade50,
        icon: Icons.cake,
      ),
      Section(
        id: 'dairy-right',
        name: 'Dairy & Eggs',
        category: 'Dairy & Eggs',
        bounds: StoreRect(x: 32.0, y: 6.0, width: 2.0, height: 8.0),
        color: Colors.blue.shade50,
        icon: Icons.local_dining,
      ),
    ];
  }

  /// Get section by category name
  static Section? getSectionByCategory(String category) {
    return _getSections().firstWhere(
      (section) => section.category == category,
      orElse: () => _getSections().first,
    );
  }

  /// Get aisle by ID
  static Aisle? getAisleById(String aisleId) {
    return _getAisles().firstWhere(
      (aisle) => aisle.id == aisleId,
      orElse: () => _getAisles().first,
    );
  }
}
