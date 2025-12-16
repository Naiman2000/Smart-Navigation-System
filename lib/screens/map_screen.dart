import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/beacon_service.dart';
import '../services/navigation_service.dart';
import '../services/firebase_service.dart';
import '../services/beacon_config_service.dart';
import '../services/proximity_service.dart';
import '../models/shopping_list_model.dart';
import '../models/product_model.dart';
import '../models/store_layout_model.dart';
import '../widgets/store_map_widget.dart';
import '../widgets/navigation_guidance_widget.dart';
import 'update_product_positions_screen.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();

  // Global key to access state from outside
  static final GlobalKey<MapScreenState> globalKey = GlobalKey<MapScreenState>();
  static MapScreenState? get instance => globalKey.currentState;
}

class MapScreenState extends State<MapScreen> {
  final _beaconService = BeaconService();
  final _navigationService = NavigationService();
  final _firebaseService = FirebaseService();
  final _beaconConfigService = BeaconConfigService();
  final _proximityService = ProximityService();

  bool _isScanning = false;
  String _connectionStatus = 'Not Connected';
  int _beaconsDetected = 0;
  List<BeaconData> _detectedBeacons = [];
  StreamSubscription<List<BeaconData>>? _beaconSubscription;
  double _positionAccuracy = 0.0;
  String _positionStatus = 'Waiting for beacons...';

  Point? _userPosition;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;

  // Navigation state
  ProductModel? _nextItem;
  Timer? _proximityCheckTimer;
  final Set<String> _alertedItems =
      {}; // Track items we've already alerted about
  ShoppingListModel? _currentShoppingList;

  @override
  void initState() {
    super.initState();
    // Delay beacon check to avoid blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // _initializeBeaconSystem();
        _checkBeaconStatus();
        _initializeUserPosition();
        _loadProductsFromShoppingList();
        // Auto-start scanning after 2-3 second delay
        // _autoStartScanning(); // COMMENTED OUT: Non-stop Bluetooth scan disabled
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load shopping list from route arguments or reload if needed
    if (_currentShoppingList == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is ShoppingListModel) {
        setState(() {
          _currentShoppingList = arguments;
        });
        // Load products for the shopping list from arguments
        _loadProductsFromShoppingList();
      } else {
        // No arguments - try to load most recent shopping list
        _loadProductsFromShoppingList();
      }
    }
  }

  // COMMENTED OUT: Non-stop Bluetooth scan disabled
  // Future<void> _autoStartScanning() async {
  //   // Wait 2-3 seconds before auto-starting
  //   await Future.delayed(const Duration(seconds: 2));

  //   if (!mounted) return;

  //   // Check if Bluetooth is available and not already scanning
  //   try {
  //     final isAvailable = await _beaconService.initializeBluetooth();
  //     if (isAvailable && !_isScanning && mounted) {
  //       setState(() {
  //         _connectionStatus = 'Initializing...';
  //       });
  //       await _startScanning();
  //     }
  //   } catch (e) {
  //     debugPrint('Auto-start scanning failed: $e');
  //   }
  // }

  @override
  void dispose() {
    _beaconSubscription?.cancel();
    _proximityCheckTimer?.cancel();
    _beaconService.stopScanning();
    super.dispose();
  }

  Future<void> _initializeBeaconSystem() async {
    // Initialize beacon cache
    await _beaconConfigService.initializeCache();

    // Subscribe to beacon stream for real-time updates
    // COMMENTED OUT: Non-stop Bluetooth scan disabled
    // _beaconSubscription = _beaconService.beaconStream.listen((beacons) {
    //   if (mounted) {
    //     setState(() {
    //       _detectedBeacons = beacons;
    //       _beaconsDetected = beacons.length;
    //     });
    //     _updateUserPosition(beacons);
    //   }
    // });
  }

  Future<void> _updateUserPosition(List<BeaconData> beacons) async {
    if (beacons.length < 3) {
      setState(() {
        _positionStatus = 'Need 3+ beacons (${beacons.length} detected)';
        _positionAccuracy = 0.0;
      });
      return;
    }

    try {
      final position = await _navigationService.calculatePosition(beacons);

      if (position != null) {
        final accuracy = _navigationService.calculatePositionAccuracy(beacons);
        setState(() {
          _userPosition = Point(x: position.x, y: position.y);
          _positionAccuracy = accuracy;
          _positionStatus = 'Positioning active';
        });

        // Update route and check proximity
        _updateRoute();
        _checkProximity(beacons);
      } else {
        setState(() {
          _positionStatus = 'Position calculation failed';
          _positionAccuracy = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _positionStatus = 'Error: $e';
        _positionAccuracy = 0.0;
      });
    }
  }

  Future<void> _updateRoute() async {
    if (_currentShoppingList == null || _userPosition == null) {
      return;
    }

    try {
      // Get next item (this internally calculates the route)
      final nextItem = await _navigationService.getNextItem(
        _currentShoppingList!,
        _userPosition!,
      );

      setState(() {
        _nextItem = nextItem;
      });
    } catch (e) {
      debugPrint('Failed to update route: $e');
    }
  }

  void _checkProximity(List<BeaconData> detectedBeacons) {
    if (_products.isEmpty || _userPosition == null) {
      return;
    }

    // Check proximity using both methods
    final proximityResults = _proximityService.checkProximity(
      _userPosition,
      detectedBeacons,
      _products,
      3.0, // 3 meter threshold
    );

    // Show alerts for items within 3m that we haven't alerted about yet
    for (final result in proximityResults) {
      if (!_alertedItems.contains(result.product.productId)) {
        _showProximityAlert(result);
        _alertedItems.add(result.product.productId);
      }
    }
  }

  Widget _buildShoppingListItem(ShoppingItem item, String listId) {
    // Check if this item is the next item to navigate to
    final isNextItem =
        _nextItem != null &&
        item.productId == _nextItem!.productId &&
        !item.isCompleted;

    // Get product location if available
    ProductModel? product;
    bool hasLocation = false;
    double? distanceToProduct;

    if (_products.isNotEmpty) {
      try {
        product = _products.firstWhere((p) => p.productId == item.productId);
        hasLocation = product.location.aisle.isNotEmpty;

        // Calculate distance if user position is available
        if (_userPosition != null && hasLocation) {
          final productPos = Point(
            x: product.location.coordinates.x,
            y: product.location.coordinates.y,
          );
          final dx = productPos.x - _userPosition!.x;
          final dy = productPos.y - _userPosition!.y;
          distanceToProduct = math.sqrt(dx * dx + dy * dy);
        }
      } catch (e) {
        // Product not found in loaded products
        product = null;
        hasLocation = false;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNextItem
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNextItem ? AppTheme.primaryColor : Colors.grey.shade200,
          width: isNextItem ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to product location if available
            if (hasLocation && product != null) {
              // Show snackbar with navigation info
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          distanceToProduct != null
                              ? 'Navigating to ${product.name} (${distanceToProduct.toStringAsFixed(1)}m away)'
                              : 'Navigating to ${product.name}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              // Update the next item to this product for visual highlighting
              setState(() {
                _nextItem = product;
              });
            } else if (!hasLocation) {
              // Show message if location not available
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Location not available for this item',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: item.isCompleted,
                    onChanged: (bool? value) {
                      _toggleItemComplete(
                        listId,
                        item.itemId,
                        item.isCompleted,
                      );
                    },
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name with NEXT badge
                      Row(
                        children: [
                          if (isNextItem) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEXT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              item.productName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isNextItem
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isCompleted
                                    ? Colors.grey.shade400
                                    : (isNextItem
                                          ? AppTheme.primaryColor
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Quantity and location info
                      Row(
                        children: [
                          // Quantity
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.quantityDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          if (hasLocation && product != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${product!.location.aisle} • Shelf ${product!.location.shelf}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Distance badge
                      if (distanceToProduct != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 13,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distanceToProduct.toStringAsFixed(1)}m away',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow indicator for clickable items
                if (hasLocation)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProximityAlert(ProximityResult result) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                "You're near ${result.product.name} (${result.distanceDisplay})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _initializeUserPosition() {
    // Get user position from navigation service
    final position = _navigationService.currentPosition;
    if (position != null) {
      setState(() {
        _userPosition = Point(x: position.x, y: position.y);
      });
    } else {
      // Default position slightly offset from entry point to avoid overlap
      setState(() {
        _userPosition = const Point(x: 25.0, y: 29.0);
      });
    }
  }

  // Public method to update shopping list from outside
  void updateShoppingList(ShoppingListModel? shoppingList) {
    if (mounted) {
      setState(() {
        _currentShoppingList = shoppingList;
      });
      _loadProductsFromShoppingList();
    }
  }

  /// Load the most recent active shopping list from Firebase
  Future<ShoppingListModel?> _loadMostRecentShoppingList() async {
    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) {
        return null;
      }

      // Get user's shopping lists (ordered by createdAt descending)
      final listsStream = _firebaseService.getUserShoppingLists(userId);
      
      // Get the first (most recent) list
      final lists = await listsStream.first;
      if (lists.isNotEmpty) {
        return lists.first; // Most recent list
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to load most recent shopping list: $e');
      return null;
    }
  }

  Future<void> _loadProductsFromShoppingList() async {
    // First try to get shopping list from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments;
    ShoppingListModel? shoppingList = arguments as ShoppingListModel?;

    // If no arguments and no current shopping list, load most recent from Firebase
    if (shoppingList == null && _currentShoppingList == null) {
      shoppingList = await _loadMostRecentShoppingList();
    }

    // Use existing shopping list if no new one found
    if (shoppingList == null) {
      shoppingList = _currentShoppingList;
    }

    setState(() {
      _currentShoppingList = shoppingList;
    });

    if (shoppingList == null || shoppingList.items.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // Load only incomplete items
      final incompleteItems = shoppingList.items
          .where((item) => !item.isCompleted && item.productId.isNotEmpty)
          .toList();

      final productIds = incompleteItems
          .map((item) => item.productId)
          .toSet()
          .toList();

      final products = <ProductModel>[];
      for (final productId in productIds) {
        final product = await _firebaseService.getProduct(productId);
        if (product != null) {
          products.add(product);
        }
      }

      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });

      // Calculate initial route
      if (_userPosition != null) {
        await _updateRoute();
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  Future<void> _checkBeaconStatus() async {
    setState(() {
      _connectionStatus = 'Checking...';
    });

    try {
      final isAvailable = await _beaconService.initializeBluetooth();
      setState(() {
        _connectionStatus = isAvailable
            ? 'Ready to Connect'
            : 'Bluetooth Not Available';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _connectionStatus = 'Scanning...';
      _beaconsDetected = 0;
      _detectedBeacons = [];
    });

    try {
      await _beaconService.startScanning();
      setState(() {
        _connectionStatus = 'Scanning...';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Scan Failed: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScanning() async {
    await _beaconService.stopScanning();
    setState(() {
      _isScanning = false;
      _connectionStatus = 'Stopped';
      _beaconsDetected = 0;
      _detectedBeacons = [];
    });
  }

  Future<void> _refreshMap() async {
    // Clear proximity alerts
    _alertedItems.clear();

    // Reload products from shopping list
    await _loadProductsFromShoppingList();

    // Recalculate route if we have position
    if (_userPosition != null) {
      await _updateRoute();
    }

    // Optionally restart scanning if it was active
    if (_isScanning) {
      await _stopScanning();
      await Future.delayed(const Duration(milliseconds: 500));
      await _startScanning();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Smart Navigation'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh Map button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMap,
            tooltip: 'Refresh Map',
          ),
          // Menu button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'toggle_scan':
                  if (_isScanning) {
                    _stopScanning();
                  } else {
                    _startScanning();
                  }
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/beaconConfig');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_scan',
                child: Row(
                  children: [
                    Icon(_isScanning ? Icons.stop : Icons.play_arrow, size: 20),
                    const SizedBox(width: 8),
                    Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Beacon Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section - Fixed at top (50% of screen)
          Expanded(flex: 5, child: _buildStoreLayoutSection()),

          // Navigation Guidance - Compact section
          if (_nextItem != null && _userPosition != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  top: BorderSide(color: Colors.orange.shade200, width: 2),
                  bottom: BorderSide(color: Colors.orange.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.navigation, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next Item',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _nextItem!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_userPosition != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_navigationService.calculateDistance(Position(x: _userPosition!.x, y: _userPosition!.y), Position(x: _nextItem!.location.coordinates.x, y: _nextItem!.location.coordinates.y)).toStringAsFixed(1)}m',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Shopping List Section - Scrollable bottom (50% of screen)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _currentShoppingList == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Shopping List',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Navigate to this screen from your shopping list to see items here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentShoppingList!.listName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_currentShoppingList!.completedItems}/${_currentShoppingList!.items.length} items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress indicator
                            if (_currentShoppingList!.items.isNotEmpty)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value:
                                      _currentShoppingList!.completedItems /
                                      _currentShoppingList!.items.length,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                  strokeWidth: 4,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Shopping List Items
                        ..._currentShoppingList!.items
                            .map(
                              (item) => _buildShoppingListItem(
                                item,
                                _currentShoppingList!.listId,
                              ),
                            )
                            .toList(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeaconInfo(String name, int rssi, String distance) {
    Color rssiColor = rssi > -50
        ? Colors.green
        : rssi > -60
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: rssiColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '$rssi dBm',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Icon(Icons.straighten, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                distance,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreLayoutSection() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final shoppingList = arguments as ShoppingListModel?;

    if (_isLoadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading products...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Show error state if products failed to load but we have a shopping list
    if (shoppingList != null &&
        shoppingList.items.isNotEmpty &&
        _products.isEmpty &&
        !_isLoadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Some items may not have product locations',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshMap,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StoreMapWidget(
      userPosition: _userPosition,
      products: _products.isNotEmpty ? _products : null,
      shoppingList: shoppingList,
      showRoute: true,
      nextItem: _nextItem,
    );
  }

  Widget _buildShoppingListSection(ShoppingListModel shoppingList) {
    final completedCount = shoppingList.items
        .where((item) => item.isCompleted)
        .length;
    final totalCount = shoppingList.items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Row(
            children: [
              const Icon(Icons.shopping_basket, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shopping List',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      shoppingList.listName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress indicator
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Expandable list
          _buildShoppingListItems(shoppingList),
        ],
      ),
    );
  }

  Widget _buildShoppingListItems(ShoppingListModel shoppingList) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Row(
        children: [
          Icon(Icons.list, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            'View Items (${shoppingList.items.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      children: shoppingList.items.map((item) {
        return _buildShoppingListItem(item, shoppingList.listId);
      }).toList(),
    );
  }

  Future<void> _toggleItemComplete(
    String listId,
    String itemId,
    bool currentStatus,
  ) async {
    try {
      await _firebaseService.updateItemStatus(
        listId: listId,
        itemId: itemId,
        isCompleted: !currentStatus,
      );

      // Reload products and update route
      await _loadProductsFromShoppingList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Item marked as incomplete'
                  : 'Item marked as complete',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
      }
    }
  }
}
