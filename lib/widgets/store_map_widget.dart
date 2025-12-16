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
    if (showRoute && userPosition != null && nextItem != null) {
      _drawRouteToNextItem(canvas, toScreen, scale, userPosition!, nextItem!);
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

    // Draw entry point first (so user position appears on top)
    _drawEntryPoint(canvas, toScreen(layout.entryPoint), scale);

    // Draw user position (drawn after entry so it appears on top)
    if (userPosition != null) {
      _drawUserPosition(canvas, toScreen(userPosition!), scale);
    }

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

    // Create smooth path with rounded corners
    final path = Path();
    final firstPoint = toScreen(Point(x: route.first.x, y: route.first.y));
    path.moveTo(firstPoint.dx, firstPoint.dy);

    // Use quadratic bezier curves for smoother path transitions
    if (route.length == 2) {
      // Simple straight line
      final endPoint = toScreen(Point(x: route.last.x, y: route.last.y));
      path.lineTo(endPoint.dx, endPoint.dy);
    } else {
      // Smooth path with rounded corners
      for (int i = 1; i < route.length; i++) {
        final currentPoint = toScreen(Point(x: route[i].x, y: route[i].y));
        
        if (i == 1) {
          path.lineTo(currentPoint.dx, currentPoint.dy);
        } else {
          // Use previous point for smooth curve
          final prevPoint = toScreen(Point(x: route[i - 1].x, y: route[i - 1].y));
          final controlPoint = Offset(
            (prevPoint.dx + currentPoint.dx) / 2,
            (prevPoint.dy + currentPoint.dy) / 2,
          );
          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            currentPoint.dx,
            currentPoint.dy,
          );
        }
      }
    }

    // Draw path with improved UI/UX
    // 1. Draw subtle shadow/outline for depth
    final pathShadowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.5 * scale).clamp(2.0, 4.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, pathShadowPaint);

    // 2. Draw main path with reduced thickness
    final routePaint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.8 * scale).clamp(1.5, 3.0) // Reduced from 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // 3. Draw inner highlight for depth
    final highlightPaint = Paint()
      ..color = Colors.orange.shade300.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 * scale).clamp(0.8, 1.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, highlightPaint);
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
