import 'dart:async';
import 'package:flutter/material.dart';
import '../services/beacon_service.dart';
import '../services/navigation_service.dart';
import '../services/firebase_service.dart';
import '../services/beacon_config_service.dart';
import '../models/shopping_list_model.dart';
import '../models/product_model.dart';
import '../models/store_layout_model.dart';
import '../widgets/store_map_widget.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _beaconService = BeaconService();
  final _navigationService = NavigationService();
  final _firebaseService = FirebaseService();
  final _beaconConfigService = BeaconConfigService();

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

  @override
  void initState() {
    super.initState();
    // Delay beacon check to avoid blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeBeaconSystem();
        _checkBeaconStatus();
        _initializeUserPosition();
        _loadProductsFromShoppingList();
      }
    });
  }

  @override
  void dispose() {
    _beaconSubscription?.cancel();
    _beaconService.stopScanning();
    super.dispose();
  }

  Future<void> _initializeBeaconSystem() async {
    // Initialize beacon cache
    await _beaconConfigService.initializeCache();
    
    // Subscribe to beacon stream for real-time updates
    _beaconSubscription = _beaconService.beaconStream.listen((beacons) {
      if (mounted) {
        setState(() {
          _detectedBeacons = beacons;
          _beaconsDetected = beacons.length;
        });
        _updateUserPosition(beacons);
      }
    });
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

  void _initializeUserPosition() {
    // Get user position from navigation service
    final position = _navigationService.currentPosition;
    if (position != null) {
      setState(() {
        _userPosition = Point(x: position.x, y: position.y);
      });
    } else {
      // Default position at entry point
      setState(() {
        _userPosition = const Point(x: 25.0, y: 0.0);
      });
    }
  }

  Future<void> _loadProductsFromShoppingList() async {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final shoppingList = arguments as ShoppingListModel?;
    
    if (shoppingList == null || shoppingList.items.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final productIds = shoppingList.items
          .where((item) => item.productId.isNotEmpty)
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
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final shoppingList = arguments as ShoppingListModel?;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Store Aisles & Navigation'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/beaconConfig');
            },
            tooltip: 'Beacon Configuration',
          ),
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
            onPressed: _isScanning ? _stopScanning : _startScanning,
            tooltip: _isScanning ? 'Stop Scanning' : 'Start Scanning',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Card
          Container(
            width: double.infinity,
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS + 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  _connectionStatus,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_beaconsDetected > 0) ...[
                  const SizedBox(width: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_beaconsDetected Beacons',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_positionAccuracy > 0) ...[
                  const SizedBox(width: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '±${_positionAccuracy.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if we are on a mobile screen (width < 600)
                bool isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  // Mobile Layout: Column (Map on top, Info on bottom)
                  return Column(
                    children: [
                      // Store Layout (Takes available space)
                      Expanded(child: _buildStoreLayoutSection()),

                      // Divider
                      const Divider(height: 1, thickness: 1),

                      // Side Panel (Info) - Fixed height or flexible on mobile
                      SizedBox(
                        height: 250, // Fixed height for info panel on mobile
                        width: double.infinity,
                        child: _buildSidePanel(shoppingList),
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet Layout: Row (Map on left, Info on right)
                  return Row(
                    children: [
                      // Store Layout
                      Expanded(flex: 2, child: _buildStoreLayoutSection()),

                      // Vertical Divider
                      const VerticalDivider(width: 1, thickness: 1),

                      // Side Panel
                      SizedBox(
                        width: 300,
                        child: _buildSidePanel(shoppingList),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_screen_fab', // Unique tag to prevent Hero conflicts
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.arrow_back),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StoreMapWidget(
      userPosition: _userPosition,
      products: _products,
      shoppingList: shoppingList,
      showRoute: true,
    );
  }

  Widget _buildSidePanel(ShoppingListModel? shoppingList) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shopping List Info
            if (shoppingList != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_basket, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Active List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shoppingList.listName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shoppingList.items.length} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_products.length} products on map',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Beacon Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth_searching, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Nearby Beacons',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_detectedBeacons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _isScanning
                                  ? 'Scanning for beacons...'
                                  : 'Start scanning to detect beacons',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_positionStatus.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _positionStatus,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ..._detectedBeacons.map(
                      (beacon) => _buildBeaconInfo(
                        beacon.name,
                        beacon.rssi,
                        '${beacon.distance.toStringAsFixed(1)}m',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
