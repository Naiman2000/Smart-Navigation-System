import 'package:flutter/material.dart';

/// Store layout model defining the physical structure of the store
class StoreLayout {
  final double width; // Store width in meters
  final double height; // Store height in meters
  final List<Aisle> aisles;
  final List<Section> sections;
  final Point entryPoint;
  final StoreRect checkoutArea;

  const StoreLayout({
    required this.width,
    required this.height,
    required this.aisles,
    required this.sections,
    required this.entryPoint,
    required this.checkoutArea,
  });
}

/// Represents an aisle in the store
class Aisle {
  final String id; // e.g., "A1", "A2", "B1"
  final String name;
  final StoreRect bounds; // Position and size in store coordinates (meters)
  final List<String> sections; // Sections accessible from this aisle

  const Aisle({
    required this.id,
    required this.name,
    required this.bounds,
    required this.sections,
  });
}

/// Represents a section/department in the store
class Section {
  final String id;
  final String name;
  final String category;
  final StoreRect bounds; // Position and size in store coordinates (meters)
  final Color color;
  final IconData icon;

  const Section({
    required this.id,
    required this.name,
    required this.category,
    required this.bounds,
    required this.color,
    required this.icon,
  });
}

/// Point in store coordinates (meters)
class Point {
  final double x;
  final double y;

  const Point({required this.x, required this.y});

  Point operator +(Point other) => Point(x: x + other.x, y: y + other.y);
  Point operator -(Point other) => Point(x: x - other.x, y: y - other.y);
  
  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy);
  }
}

/// Rectangle in store coordinates (meters)
class StoreRect {
  final double x;
  final double y;
  final double width;
  final double height;

  const StoreRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;
  
  Point get center => Point(x: x + width / 2, y: y + height / 2);
  
  bool contains(Point point) {
    return point.x >= x && 
           point.x <= x + width && 
           point.y >= y && 
           point.y <= y + height;
  }
}

/// Map marker for displaying items on the map
class MapMarker {
  final String id;
  final Point position;
  final String label;
  final Color color;
  final IconData icon;
  final bool isProduct;
  final String? productId;

  const MapMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.color,
    required this.icon,
    this.isProduct = false,
    this.productId,
  });
}

/// Navigation route with waypoints
class NavigationRoute {
  final List<Point> waypoints;
  final double totalDistance; // in meters

  const NavigationRoute({
    required this.waypoints,
    required this.totalDistance,
  });
}

