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

  const StoreMapWidget({
    super.key,
    this.userPosition,
    this.products,
    this.shoppingList,
    this.showRoute = true,
    this.onMapTap,
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
      child: Column(
        children: [
          // Map Controls
          _buildMapControls(),
          // Map Area
          Expanded(
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.map, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: AppTheme.spacingS),
          const Text(
            'Store Map',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 22),
            color: AppTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: () {
              _transformationController.value = Matrix4.identity()
                ..scale(1.2)
                ..translate(
                  -MediaQuery.of(context).size.width * 0.1,
                  -MediaQuery.of(context).size.height * 0.1,
                );
            },
            tooltip: 'Zoom in',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 22),
            color: AppTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: () {
              _transformationController.value = Matrix4.identity()
                ..scale(0.8)
                ..translate(
                  MediaQuery.of(context).size.width * 0.1,
                  MediaQuery.of(context).size.height * 0.1,
                );
            },
            tooltip: 'Zoom out',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong, size: 22),
            color: AppTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            tooltip: 'Reset view',
          ),
        ],
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

  StoreMapPainter({
    required this.layout,
    this.userPosition,
    required this.products,
    this.shoppingList,
    this.showRoute = true,
    required this.pulseAnimation,
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
      return Offset(
        offset.dx + point.x * scale,
        offset.dy + point.y * scale,
      );
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
            fontSize: math.max(1.5 * scale, 10.0).toDouble(),
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
        Offset(
          aisleRect.center.dx - textPainter.width / 2,
          aisleRect.top + 4,
        ),
      );
    }

    // Draw navigation route if enabled
    if (showRoute && userPosition != null && products.isNotEmpty) {
      _drawNavigationRoute(canvas, toScreen, scale);
    }

    // Draw product markers
    for (final product in products) {
      final productPoint = Point(
        x: product.location.coordinates.x,
        y: product.location.coordinates.y,
      );
      _drawProductMarker(canvas, toScreen(productPoint), product, scale);
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
          fontSize: math.max(1.2 * scale, 10.0).toDouble(),
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
  ) {
    if (userPosition == null || products.isEmpty) return;

    final navigationService = NavigationService();
    final destinations = products.map((p) {
      return Position(
        x: p.location.coordinates.x,
        y: p.location.coordinates.y,
      );
    }).toList();

    final route = navigationService.calculateRoute(
      Position(x: userPosition!.x, y: userPosition!.y),
      destinations,
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
    final arrowLength = 12 * scale;
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
    double scale,
  ) {
    final color = _getCategoryColor(product.category);

    // Draw marker circle
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    final radius = 12 * scale;
    canvas.drawCircle(position, radius, markerPaint);
    canvas.drawCircle(position, radius, borderPaint);

    // Draw icon (simplified as a small circle for now)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 6 * scale, iconPaint);

    // Draw product name label with background
    final textPainter = TextPainter(
      text: TextSpan(
        text: product.name,
        style: TextStyle(
          fontSize: math.max(9 * scale, 8.0).toDouble(),
          color: Colors.white,
          fontWeight: FontWeight.w600,
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
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + radius + 3,
      ),
    );
  }

  void _drawUserPosition(Canvas canvas, Offset position, double scale) {
    // Pulsing circle effect - roughly 1 meter radius
    final pulseRadius = 1.0 * scale * (1.0 + pulseAnimation.value * 0.3);
    final pulsePaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, pulseRadius, pulsePaint);

    // Outer circle - 0.6 meters radius
    final outerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15 * scale; // Line width
    canvas.drawCircle(position, 0.6 * scale, outerPaint);

    // Inner filled circle - 0.4 meters radius
    final innerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 0.4 * scale, innerPaint);

    // "You are here" label - fixed pixel size for readability
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'You',
        style: TextStyle(
          fontSize: math.max(0.4 * scale, 10.0).toDouble(), // Min 10px
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
          fontSize: math.max(0.5 * scale, 10.0).toDouble(), // Much smaller text
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
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + radius + 4,
      ),
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
