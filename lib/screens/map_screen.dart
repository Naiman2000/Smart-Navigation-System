import 'package:flutter/material.dart';
import '../services/beacon_service.dart';
import '../models/shopping_list_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _beaconService = BeaconService();

  bool _isScanning = false;
  String _connectionStatus = 'Not Connected';
  int _beaconsDetected = 0;
  List<Map<String, dynamic>> _beacons = [];

  // Sample store layout data
  final List<Map<String, dynamic>> _storeLayout = [
    {'section': 'Dairy & Eggs', 'aisle': 'A1', 'icon': Icons.local_drink},
    {'section': 'Meat & Seafood', 'aisle': 'A2', 'icon': Icons.set_meal},
    {'section': 'Fruits & Vegetables', 'aisle': 'A3', 'icon': Icons.apple},
    {'section': 'Bakery', 'aisle': 'A4', 'icon': Icons.cake},
    {'section': 'Cereals', 'aisle': 'B1', 'icon': Icons.breakfast_dining},
    {'section': 'Snacks', 'aisle': 'B2', 'icon': Icons.cookie},
    {'section': 'Beverages', 'aisle': 'B3', 'icon': Icons.local_cafe},
    {'section': 'Frozen Foods', 'aisle': 'C1', 'icon': Icons.ac_unit},
  ];

  @override
  void initState() {
    super.initState();
    _checkBeaconStatus();
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
    });

    try {
      await _beaconService.startScanning();

      // Simulate beacon detection for demo
      setState(() {
        _beaconsDetected = 5; // Simulated
        _connectionStatus = 'Connected';
        _beacons = [
          {'name': 'Beacon A1', 'rssi': -45, 'distance': '2.5m'},
          {'name': 'Beacon A2', 'rssi': -52, 'distance': '3.2m'},
          {'name': 'Beacon B1', 'rssi': -58, 'distance': '4.1m'},
          {'name': 'Beacon C1', 'rssi': -62, 'distance': '5.0m'},
          {'name': 'Beacon D1', 'rssi': -68, 'distance': '6.0m'},
        ];
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
            color: Colors.green.shade700,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isScanning ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _connectionStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_beaconsDetected > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$_beaconsDetected Beacons Detected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
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
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  Widget _buildStoreSectionCard(Map<String, dynamic> section) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to ${section['section']}...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(section['icon'] as IconData, size: 32, color: Colors.green),
              const SizedBox(height: 8),
              Text(
                section['section'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                section['aisle'],
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Store Layout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'You are here',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _storeLayout.length,
              itemBuilder: (context, index) {
                final item = _storeLayout[index];
                return _buildStoreSectionCard(item);
              },
            ),
          ),
        ],
      ),
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
                  if (_beacons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Start scanning to detect beacons',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._beacons.map(
                      (beacon) => _buildBeaconInfo(
                        beacon['name'],
                        beacon['rssi'],
                        beacon['distance'],
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
