import 'package:flutter/material.dart';
import '../models/store_layout_model.dart';

/// Store layout configuration for a typical grocery store
/// Store dimensions: 50m × 30m
///
/// Layout Design:
/// - 6 vertical aisles (A1, A2, A3, B1, B2, B3)
/// - Each aisle: 2m wide × 24m long
/// - Walkways: 3m wide between aisles
/// - Entry: Top center (between A3 and B1)
/// - Checkout: Bottom center (between A3 and B1)
class StoreLayoutConfig {
  static const double storeWidth = 50.0; // meters
  static const double storeHeight = 30.0; // meters
  static const double aisleWidth = 2.0; // meters (width of each aisle)
  static const double aisleHeight = 24.0; // meters (length of each aisle)
  static const double walkwayWidth = 3.0; // meters between aisles
  static const double topMargin = 3.0; // meters from top edge
  static const double bottomMargin = 3.0; // meters from bottom edge

  /// Get the default store layout
  static StoreLayout getDefaultLayout() {
    return StoreLayout(
      width: storeWidth,
      height: storeHeight,
      aisles: _getAisles(),
      sections: _getSections(),
      entryPoint: Point(
        x: 25.0, // Center of store (between A3 and B1)
        y: storeHeight - 0.5, // At the very bottom edge
      ),
      checkoutArea: StoreRect(
        x: 24.0, // Center area
        y: 0.0, // At the absolute top edge, above all aisles
        width: 2.0,
        height: 2.0,
      ),
    );
  }

  /// Define aisles (6 vertical aisles with proper spacing)
  static List<Aisle> _getAisles() {
    // Calculate aisle positions
    // Total width needed:
    // 6 aisles × 2m = 12m
    // 4 regular walkways × 3m = 12m (between A1-A2, A2-A3, B1-B2, B2-B3)
    // 1 center walkway × 6m = 6m (between A3 and B1)
    // Total = 30m
    // Left margin = (50m - 30m) / 2 = 10m

    final leftStartX = 10.0; // Center the aisles horizontally
    final centerWalkway = 6.0; // Wider walkway between A and B sides
    final aisleYStart = topMargin;

    return [
      // Left side aisles
      Aisle(
        id: 'A1',
        name: 'Aisle A1',
        bounds: StoreRect(
          x: leftStartX,
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Dairy & Eggs', 'Bakery'],
      ),
      Aisle(
        id: 'A2',
        name: 'Aisle A2',
        bounds: StoreRect(
          x: leftStartX + aisleWidth + walkwayWidth, // 5 + 2 + 3 = 10
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Meat & Seafood', 'Produce'],
      ),
      Aisle(
        id: 'A3',
        name: 'Aisle A3',
        bounds: StoreRect(
          x: leftStartX + (aisleWidth + walkwayWidth) * 2, // 5 + 10 = 15
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Beverages', 'Pantry Staples'],
      ),

      // Right side aisles (after 6m center walkway)
      // A3 ends at: leftStartX + (aisleWidth + walkwayWidth) * 2 + aisleWidth = 10 + 10 + 2 = 22
      // B1 starts at: 22 + centerWalkway = 22 + 6 = 28
      Aisle(
        id: 'B1',
        name: 'Aisle B1',
        bounds: StoreRect(
          x:
              leftStartX +
              (aisleWidth + walkwayWidth) * 2 +
              aisleWidth +
              centerWalkway, // 10 + 10 + 2 + 6 = 28
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Frozen Foods', 'Snacks'],
      ),
      Aisle(
        id: 'B2',
        name: 'Aisle B2',
        bounds: StoreRect(
          x:
              leftStartX +
              (aisleWidth + walkwayWidth) * 3 +
              aisleWidth +
              centerWalkway, // 10 + 15 + 2 + 6 = 33
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Household Items', 'Personal Care'],
      ),
      Aisle(
        id: 'B3',
        name: 'Aisle B3',
        bounds: StoreRect(
          x:
              leftStartX +
              (aisleWidth + walkwayWidth) * 4 +
              aisleWidth +
              centerWalkway, // 10 + 20 + 2 + 6 = 38
          y: aisleYStart,
          width: aisleWidth,
          height: aisleHeight,
        ),
        sections: ['Health & Beauty', 'Baby Care'],
      ),
    ];
  }

  /// Define sections/departments
  static List<Section> _getSections() {
    return [
      // A1 aisle sections (x=10)
      Section(
        id: 'dairy',
        name: 'Dairy & Eggs',
        category: 'Fresh',
        bounds: StoreRect(x: 10.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.blue.shade100,
        icon: Icons.egg,
      ),
      Section(
        id: 'bakery',
        name: 'Bakery',
        category: 'Fresh',
        bounds: StoreRect(x: 10.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.orange.shade100,
        icon: Icons.bakery_dining,
      ),
      // A2 aisle sections (x=15)
      Section(
        id: 'meat',
        name: 'Meat & Seafood',
        category: 'Fresh',
        bounds: StoreRect(x: 15.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.red.shade100,
        icon: Icons.set_meal,
      ),
      Section(
        id: 'produce',
        name: 'Produce',
        category: 'Fresh',
        bounds: StoreRect(x: 15.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.green.shade100,
        icon: Icons.local_florist,
      ),
      // A3 aisle sections (x=20)
      Section(
        id: 'beverages',
        name: 'Beverages',
        category: 'Grocery',
        bounds: StoreRect(x: 20.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.cyan.shade100,
        icon: Icons.local_drink,
      ),
      Section(
        id: 'pantry',
        name: 'Pantry Staples',
        category: 'Grocery',
        bounds: StoreRect(x: 20.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.brown.shade100,
        icon: Icons.kitchen,
      ),
      // B1 aisle sections (x=28)
      Section(
        id: 'frozen',
        name: 'Frozen Foods',
        category: 'Frozen',
        bounds: StoreRect(x: 28.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.lightBlue.shade100,
        icon: Icons.ac_unit,
      ),
      Section(
        id: 'snacks',
        name: 'Snacks',
        category: 'Grocery',
        bounds: StoreRect(x: 28.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.amber.shade100,
        icon: Icons.fastfood,
      ),
      // B2 aisle sections (x=33)
      Section(
        id: 'household',
        name: 'Household Items',
        category: 'Non-Food',
        bounds: StoreRect(x: 33.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.grey.shade100,
        icon: Icons.home,
      ),
      Section(
        id: 'personal',
        name: 'Personal Care',
        category: 'Health & Beauty',
        bounds: StoreRect(x: 33.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.pink.shade100,
        icon: Icons.face,
      ),
      // B3 aisle sections (x=38)
      Section(
        id: 'health',
        name: 'Health & Beauty',
        category: 'Health & Beauty',
        bounds: StoreRect(x: 38.0, y: 3.0, width: 2.0, height: 12.0),
        color: Colors.purple.shade100,
        icon: Icons.health_and_safety,
      ),
      Section(
        id: 'baby',
        name: 'Baby Care',
        category: 'Baby',
        bounds: StoreRect(x: 38.0, y: 15.0, width: 2.0, height: 12.0),
        color: Colors.yellow.shade100,
        icon: Icons.child_care,
      ),
    ];
  }
}
