import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/store_layout_model.dart';
import '../data/store_layout_config.dart';
import '../services/navigation_service.dart';
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';
import '../theme/app_theme.dart';

/// Custom widget that renders a top-down store map
class StoreMapWidget extends StatefulWidget {
  final Point? userPosition;
  final List<ProductModel>? products;
  final ShoppingListModel? shoppingList;
  final bool showRoute;
  final Function(Point)? onMapTap;
  final ProductModel? nextItem; // Next item to navigate to

  const StoreMapWidget({
    super.key,
    this.userPosition,
    this.products,
    this.shoppingList,
    this.showRoute = true,
    this.onMapTap,
    this.nextItem,
  });

  @override
  State<StoreMapWidget> createState() => _StoreMapWidgetState();
}

class _StoreMapWidgetState extends State<StoreMapWidget>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = StoreLayoutConfig.getDefaultLayout();

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(20),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: CustomPaint(
                painter: StoreMapPainter(
                  layout: layout,
                  userPosition: widget.userPosition,
                  products: widget.products ?? [],
                  shoppingList: widget.shoppingList,
                  showRoute: widget.showRoute,
                  pulseAnimation: _pulseController,
                  nextItem: widget.nextItem,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for drawing the store map
class StoreMapPainter extends CustomPainter {
  final StoreLayout layout;
  final Point? userPosition;
  final List<ProductModel> products;
  final ShoppingListModel? shoppingList;
  final bool showRoute;
  final Animation<double> pulseAnimation;
  final ProductModel? nextItem;

  StoreMapPainter({
    required this.layout,
    this.userPosition,
    required this.products,
    this.shoppingList,
    this.showRoute = true,
    required this.pulseAnimation,
    this.nextItem,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale factors to fit the map in the available size
    final scaleX = size.width / layout.width;
    final scaleY = size.height / layout.height;
    final scale = math.min(scaleX, scaleY); // Maintain aspect ratio

    // Center the map within the available space
    final scaledWidth = layout.width * scale;
    final scaledHeight = layout.height * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;
    final offset = Offset(offsetX, offsetY);

    // Helper function to convert store coordinates to screen coordinates
    Offset toScreen(Point point) {
      return Offset(offset.dx + point.x * scale, offset.dy + point.y * scale);
    }

    // Helper function to convert store rect to screen rect
    Rect toScreenRect(StoreRect rect) {
      return Rect.fromLTWH(
        offset.dx + rect.x * scale,
        offset.dy + rect.y * scale,
        rect.width * scale,
        rect.height * scale,
      );
    }

    // Draw background
    final backgroundPaint = Paint()..color = Colors.grey.shade100;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw sections (departments) - lighter background only, no labels to reduce clutter
    for (final section in layout.sections) {
      final sectionRect = toScreenRect(section.bounds);
      final sectionPaint = Paint()
        ..color = section.color.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = section.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(sectionRect, sectionPaint);
      canvas.drawRect(sectionRect, borderPaint);
    }

    // Draw aisles (paths)
    for (final aisle in layout.aisles) {
      final aisleRect = toScreenRect(aisle.bounds);
      final aislePaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill;
      final aisleBorderPaint = Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(aisleRect, aislePaint);
      canvas.drawRect(aisleRect, aisleBorderPaint);

      // Draw aisle label with background for visibility
      final textPainter = TextPainter(
        text: TextSpan(
          text: aisle.id,
          style: TextStyle(
            fontSize: math.min(math.max(0.8 * scale, 8.0), 10.0).toDouble(),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background rectangle for label
      final labelBgRect = Rect.fromLTWH(
        aisleRect.center.dx - textPainter.width / 2 - 4,
        aisleRect.top + 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      final labelBgPaint = Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelBgRect, const Radius.circular(4)),
        labelBgPaint,
      );

      textPainter.paint(
        canvas,
        Offset(aisleRect.center.dx - textPainter.width / 2, aisleRect.top + 4),
      );
    }

    // Draw navigation route if enabled (only to next item if specified)
    if (showRoute && userPosition != null) {
      if (nextItem != null) {
        _drawRouteToNextItem(canvas, toScreen, scale, userPosition!, nextItem!);
      } else if (products.isNotEmpty) {
        _drawNavigationRoute(canvas, toScreen, scale, layout);
      }
    }

    // Draw product markers (highlight next item if specified)
    for (final product in products) {
      final productPoint = Point(
        x: product.location.coordinates.x,
        y: product.location.coordinates.y,
      );
      final isNextItem =
          nextItem != null && nextItem!.productId == product.productId;
      _drawProductMarker(
        canvas,
        toScreen(productPoint),
        product,
        scale,
        isNextItem: isNextItem,
      );
    }

    // Draw user position
    if (userPosition != null) {
      _drawUserPosition(canvas, toScreen(userPosition!), scale);
    }

    // Draw entry point
    _drawEntryPoint(canvas, toScreen(layout.entryPoint), scale);

    // Draw checkout area
    final checkoutRect = toScreenRect(layout.checkoutArea);
    final checkoutPaint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;
    final checkoutBorderPaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2 * scale;

    canvas.drawRect(checkoutRect, checkoutPaint);
    canvas.drawRect(checkoutRect, checkoutBorderPaint);

    // Checkout label with better visibility
    final checkoutText = TextPainter(
      text: TextSpan(
        text: 'CHECKOUT',
        style: TextStyle(
          fontSize: math.min(math.max(0.7 * scale, 8.0), 10.0).toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    checkoutText.layout();

    // Draw semi-transparent background for better text visibility
    final textBgRect = Rect.fromLTWH(
      checkoutRect.center.dx - checkoutText.width / 2 - 6,
      checkoutRect.center.dy - checkoutText.height / 2 - 2,
      checkoutText.width + 12,
      checkoutText.height + 4,
    );
    final textBgPaint = Paint()
      ..color = Colors.orange.shade800.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(textBgRect, const Radius.circular(4)),
      textBgPaint,
    );

    checkoutText.paint(
      canvas,
      Offset(
        checkoutRect.center.dx - checkoutText.width / 2,
        checkoutRect.center.dy - checkoutText.height / 2,
      ),
    );
  }

  void _drawNavigationRoute(
    Canvas canvas,
    Offset Function(Point) toScreen,
    double scale,
    StoreLayout layout,
  ) {
    if (userPosition == null || products.isEmpty) return;

    final navigationService = NavigationService();
    final destinations = products.map((p) {
      return Position(x: p.location.coordinates.x, y: p.location.coordinates.y);
    }).toList();

    final route = navigationService.calculateRoute(
      Position(x: userPosition!.x, y: userPosition!.y),
      destinations,
      layout: layout,
    );

    if (route.length < 2) return;

    final path = Path();
    final start = toScreen(Point(x: route[0].x, y: route[0].y));
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i < route.length; i++) {
      final point = toScreen(Point(x: route[i].x, y: route[i].y));
      path.lineTo(point.dx, point.dy);
    }

    // Draw dashed line
    final dashPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    final dashPath = _createDashedPath(path, 8 * scale, 4 * scale);
    canvas.drawPath(dashPath, dashPaint);

    // Draw arrows along the route
    for (int i = 0; i < route.length - 1; i++) {
      final start = Point(x: route[i].x, y: route[i].y);
      final end = Point(x: route[i + 1].x, y: route[i + 1].y);
      _drawArrow(
        canvas,
        toScreen(start),
        toScreen(end),
        AppTheme.primaryColor,
        scale,
      );
    }
  }

  /// Draw route to next item only
  void _drawRouteToNextItem(
    Canvas canvas,
    Offset Function(Point) toScreen,
    double scale,
    Point userPosPoint,
    ProductModel next,
  ) {
    final navigationService = NavigationService();
    final nextItemPoint = Point(
      x: next.location.coordinates.x,
      y: next.location.coordinates.y,
    );

    final userPos = Position(x: userPosPoint.x, y: userPosPoint.y);
    final itemPos = Position(x: nextItemPoint.x, y: nextItemPoint.y);

    // Use A* pathfinding to get route around obstacles
    final route = navigationService.calculateRoute(userPos, [
      itemPos,
    ], layout: layout);

    if (route.length < 2) return;

    final distance = navigationService.calculateDistance(userPos, itemPos);

    // Draw the pathfinding route
    final routePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;

    final path = Path();
    final firstPoint = toScreen(Point(x: route.first.x, y: route.first.y));
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < route.length; i++) {
      final point = toScreen(Point(x: route[i].x, y: route[i].y));
      path.lineTo(point.dx, point.dy);
    }

    final dashPath = _createDashedPath(path, 10 * scale, 5 * scale);
    canvas.drawPath(dashPath, routePaint);

    // Draw arrow at the end
    if (route.length >= 2) {
      final secondLast = toScreen(
        Point(x: route[route.length - 2].x, y: route[route.length - 2].y),
      );
      final last = toScreen(Point(x: route.last.x, y: route.last.y));
      _drawArrow(canvas, secondLast, last, Colors.orange, scale);
    }

    // Draw distance label
    final distanceText = distance < 1.0
        ? '${(distance * 100).round()} cm'
        : '${distance.toStringAsFixed(1)} m';

    final textPainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: TextStyle(
          fontSize: math.min(math.max(8 * scale, 8.0), 10.0).toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label at midpoint of route
    final midIndex = route.length ~/ 2;
    final midPoint = toScreen(
      Point(x: route[midIndex].x, y: route[midIndex].y),
    );

    // Draw background for distance label
    final labelBgRect = Rect.fromLTWH(
      midPoint.dx - textPainter.width / 2 - 4,
      midPoint.dy - textPainter.height / 2 - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    final labelBgPaint = Paint()
      ..color = Colors.orange.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(4)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }

  Path _createDashedPath(Path path, double dashLength, double dashSpace) {
    final dashPath = Path();
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        if (start != null) {
          dashPath.moveTo(start.position.dx, start.position.dy);
        }
        distance += dashLength;
        if (distance < metric.length) {
          final end = metric.getTangentForOffset(distance);
          if (end != null) {
            dashPath.lineTo(end.position.dx, end.position.dy);
          }
        }
        distance += dashSpace;
      }
    }
    return dashPath;
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double scale,
  ) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowLength = 6 * scale;
    final arrowAngle = math.pi / 6;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    path.lineTo(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawProductMarker(
    Canvas canvas,
    Offset position,
    ProductModel product,
    double scale, {
    bool isNextItem = false,
  }) {
    final color = isNextItem
        ? Colors.orange
        : _getCategoryColor(product.category);

    // Draw pulsing circle for next item
    if (isNextItem) {
      final pulseRadius = (2 * scale) * (1.0 + pulseAnimation.value * 0.2);
      final pulsePaint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, pulseRadius, pulsePaint);
    }

    // Draw marker circle (larger for next item)
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isNextItem ? 1 * scale : 0.8 * scale;

    final radius = isNextItem ? 2 * scale : 1.5 * scale;
    canvas.drawCircle(position, radius, markerPaint);
    canvas.drawCircle(position, radius, borderPaint);

    // Draw icon (simplified as a small circle for now)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      position,
      isNextItem ? 1 * scale : 0.8 * scale,
      iconPaint,
    );

    // Draw product name label with background
    final labelText = isNextItem ? 'Next: ${product.name}' : product.name;
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          fontSize: math
              .min(math.max((isNextItem ? 5 : 4) * scale, 6.0), 9.0)
              .toDouble(),
          color: Colors.white,
          fontWeight: isNextItem ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();

    // Draw background for product label
    if (textPainter.width > 0) {
      final labelBgRect = Rect.fromLTWH(
        position.dx - textPainter.width / 2 - 3,
        position.dy + radius + 2,
        textPainter.width + 6,
        textPainter.height + 2,
      );
      final labelBgPaint = Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelBgRect, const Radius.circular(3)),
        labelBgPaint,
      );
    }

    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy + radius + 3),
    );
  }

  void _drawUserPosition(Canvas canvas, Offset position, double scale) {
    // Pulsing circle effect - roughly 0.5 meter radius
    final pulseRadius = 0.5 * scale * (1.0 + pulseAnimation.value * 0.3);
    final pulsePaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, pulseRadius, pulsePaint);

    // Outer circle - 0.3 meters radius
    final outerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1 * scale; // Line width
    canvas.drawCircle(position, 0.3 * scale, outerPaint);

    // Inner filled circle - 0.2 meters radius
    final innerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 0.2 * scale, innerPaint);

    // "You are here" label - fixed pixel size for readability
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'You',
        style: TextStyle(
          fontSize: math.min(math.max(0.3 * scale, 8.0), 9.0).toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background for "You" label
    final labelBgRect = Rect.fromLTWH(
      position.dx - textPainter.width / 2 - 2,
      position.dy - textPainter.height / 2 - 1,
      textPainter.width + 4,
      textPainter.height + 2,
    );
    final labelBgPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(4)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawEntryPoint(Canvas canvas, Offset position, double scale) {
    final entryPaint = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15 * scale;

    // Entry circle - 0.8 meters radius
    final radius = math.max(0.8 * scale, 5.0).toDouble();
    canvas.drawCircle(position, radius, entryPaint);
    canvas.drawCircle(position, radius, borderPaint);

    // Entry label with background
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ENTRY',
        style: TextStyle(
          fontSize: math.min(math.max(0.4 * scale, 8.0), 9.0).toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background for label
    final labelBgRect = Rect.fromLTWH(
      position.dx - textPainter.width / 2 - 4,
      position.dy + radius + 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    final labelBgPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(4)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy + radius + 4),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy & eggs':
      case 'dairy':
        return Colors.blue;
      case 'meat & seafood':
      case 'meat':
        return Colors.red;
      case 'bakery':
        return Colors.orange;
      case 'produce':
        return Colors.green;
      case 'beverages':
        return Colors.cyan;
      case 'frozen foods':
      case 'frozen':
        return Colors.lightBlue;
      case 'pantry staples':
      case 'pantry':
        return Colors.brown;
      case 'household items':
      case 'household':
        return Colors.grey;
      case 'personal care':
        return Colors.pink;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  bool shouldRepaint(StoreMapPainter oldDelegate) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.products.length != products.length ||
        oldDelegate.pulseAnimation.value != pulseAnimation.value;
  }
}
