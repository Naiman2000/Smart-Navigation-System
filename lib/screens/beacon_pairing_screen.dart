import 'dart:async';
import 'package:flutter/material.dart';
import '../services/beacon_service.dart';
import '../services/beacon_config_service.dart';
import '../models/beacon_model.dart';
import '../models/store_layout_model.dart';
import '../data/store_layout_config.dart';
import '../widgets/store_map_widget.dart';
import '../theme/app_theme.dart';

class BeaconPairingScreen extends StatefulWidget {
  const BeaconPairingScreen({super.key});

  @override
  State<BeaconPairingScreen> createState() => _BeaconPairingScreenState();
}

class _BeaconPairingScreenState extends State<BeaconPairingScreen> {
  final _beaconService = BeaconService();
  final _beaconConfigService = BeaconConfigService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  List<DiscoveredDevice> _discoveredDevices = [];
  StreamSubscription<List<DiscoveredDevice>>? _discoverySubscription;
  Timer? _scanCheckTimer;
  bool _isDiscovering = false;
  DiscoveredDevice? _selectedDevice;
  int _txPower = -59;
  Point? _selectedPosition;
  bool _showMapPicker = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-start - let user manually start scan
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _scanCheckTimer?.cancel();
    _beaconService.stopDiscoveryMode();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    if (_isDiscovering) return;

    setState(() {
      _isDiscovering = true;
    });

    try {
      await _beaconService.startDiscoveryMode();
      _discoverySubscription = _beaconService.discoveryStream.listen((devices) {
        if (mounted) {
          setState(() {
            _discoveredDevices = devices;
          });
        }
      });
      
      // Check periodically if scan has completed (scan has 4 second timeout)
      _scanCheckTimer?.cancel();
      _scanCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_beaconService.isScanning && mounted && _isDiscovering) {
          timer.cancel();
          setState(() {
            _isDiscovering = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan completed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start discovery: $e')),
        );
      }
    }
  }

  Future<void> _stopDiscovery() async {
    await _beaconService.stopDiscoveryMode();
    _discoverySubscription?.cancel();
    _scanCheckTimer?.cancel();
    setState(() {
      _isDiscovering = false;
      // Don't clear devices - keep the list visible
    });
  }

  Future<void> _refreshDiscovery() async {
    // Stop current scan if running
    if (_isDiscovering) {
      await _stopDiscovery();
    }
    
    // Clear previous results
    setState(() {
      _discoveredDevices.clear();
      _selectedDevice = null;
      _nameController.clear();
      _selectedPosition = null;
    });
    
    // Start new scan
    await _startDiscovery();
  }

  void _selectDevice(DiscoveredDevice device) {
    setState(() {
      _selectedDevice = device;
      _nameController.text = device.name != 'Unknown Device' ? device.name : '';
      _showMapPicker = false;
    });
  }

  void _showPositionPicker() {
    setState(() {
      _showMapPicker = true;
    });
  }

  Future<void> _saveBeacon() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device to pair')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a position on the map')),
      );
      return;
    }

    try {
      final beacon = BeaconModel(
        beaconId: _selectedDevice!.id,
        name: _nameController.text.trim(),
        macAddress: _selectedDevice!.macAddress,
        position: _selectedPosition!,
        txPower: _txPower,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _beaconConfigService.saveBeacon(beacon);
      await _beaconService.refreshConfiguredBeacons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beacon paired successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save beacon: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair BLE Beacon'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showMapPicker
          ? _buildMapPicker()
          : _buildPairingForm(),
    );
  }

  Widget _buildPairingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovery Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  if (_isDiscovering)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: Text(
                                'Scanning for BLE devices...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _stopDiscovery,
                            icon: const Icon(Icons.stop, size: 18),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                                vertical: AppTheme.spacingS,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _discoveredDevices.isEmpty
                              ? 'Tap Start to scan for BLE devices'
                              : 'Found ${_discoveredDevices.length} device(s). Tap Refresh to search again.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: AppTheme.spacingM,
                            runSpacing: AppTheme.spacingS,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _startDiscovery,
                                icon: const Icon(Icons.search, size: 18),
                                label: const Text('Start'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingM,
                                    vertical: AppTheme.spacingS,
                                  ),
                                ),
                              ),
                              if (_discoveredDevices.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: _refreshDiscovery,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Refresh'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingM,
                                      vertical: AppTheme.spacingS,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Discovered Devices List
          if (_discoveredDevices.isNotEmpty) ...[
            const Text(
              'Discovered Devices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ..._discoveredDevices.map((device) => _buildDeviceCard(device)),
          ],

          const SizedBox(height: AppTheme.spacingL),

          // Configuration Form
          if (_selectedDevice != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure Beacon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Selected Device Info
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bluetooth, color: AppTheme.primaryColor),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDevice!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _selectedDevice!.macAddress,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRssiColor(_selectedDevice!.rssi),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedDevice!.rssi} dBm',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Beacon Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Beacon Name',
                          hintText: 'e.g., Beacon A1, Entrance Beacon',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a beacon name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Transmit Power
                      Text(
                        'Transmit Power: $_txPower dBm',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Slider(
                        value: _txPower.toDouble(),
                        min: -100,
                        max: -40,
                        divisions: 60,
                        label: '$_txPower dBm',
                        onChanged: (value) {
                          setState(() {
                            _txPower = value.round();
                          });
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Position Picker
                      const Text(
                        'Position on Map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      OutlinedButton.icon(
                        onPressed: _showPositionPicker,
                        icon: const Icon(Icons.map),
                        label: Text(
                          _selectedPosition != null
                              ? 'Position: (${_selectedPosition!.x.toStringAsFixed(1)}, ${_selectedPosition!.y.toStringAsFixed(1)})'
                              : 'Tap to select position on map',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      // Save Button
                      ElevatedButton(
                        onPressed: _saveBeacon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Save Beacon',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_isDiscovering && _discoveredDevices.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Scanning for BLE devices...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!_isDiscovering) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_searching,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Start discovery to find BLE devices',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    final isSelected = _selectedDevice?.id == device.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _selectDevice(device),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getRssiColor(device.rssi).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bluetooth,
                  color: _getRssiColor(device.rssi),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.macAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRssiColor(device.rssi),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${device.rssi} dBm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPicker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          color: AppTheme.primaryColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showMapPicker = false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Select Beacon Position',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _MapPositionPicker(
            initialPosition: _selectedPosition,
            onPositionSelected: (position) {
              setState(() {
                _selectedPosition = position;
                _showMapPicker = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    if (rssi >= -80) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Map position picker widget
class _MapPositionPicker extends StatefulWidget {
  final Point? initialPosition;
  final Function(Point) onPositionSelected;

  const _MapPositionPicker({
    required this.initialPosition,
    required this.onPositionSelected,
  });

  @override
  State<_MapPositionPicker> createState() => _MapPositionPickerState();
}

class _MapPositionPickerState extends State<_MapPositionPicker> {
  Point? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final layout = StoreLayoutConfig.getDefaultLayout();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            
            final localPosition = box.globalToLocal(details.globalPosition);
            
            // Calculate scale factors
            final scaleX = layout.width / constraints.maxWidth;
            final scaleY = layout.height / constraints.maxHeight;
            final scale = scaleX < scaleY ? scaleX : scaleY;
            
            // Calculate offset (centered map)
            final scaledWidth = layout.width / scale;
            final scaledHeight = layout.height / scale;
            final offsetX = (constraints.maxWidth - scaledWidth) / 2;
            final offsetY = (constraints.maxHeight - scaledHeight) / 2;
            
            // Convert screen coordinates to store coordinates
            final storeX = (localPosition.dx - offsetX) * scale;
            final storeY = (localPosition.dy - offsetY) * scale;
            
            // Clamp to store bounds
            final clampedX = storeX.clamp(0.0, layout.width);
            final clampedY = storeY.clamp(0.0, layout.height);
            
            final position = Point(x: clampedX, y: clampedY);
            setState(() {
              _selectedPosition = position;
            });
            widget.onPositionSelected(position);
          },
          child: Stack(
            children: [
              StoreMapWidget(
                showRoute: false,
              ),
              if (_selectedPosition != null)
                _PositionMarker(
                  position: _selectedPosition!,
                  layout: layout,
                  constraints: constraints,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Position marker widget
class _PositionMarker extends StatelessWidget {
  final Point position;
  final StoreLayout layout;
  final BoxConstraints constraints;

  const _PositionMarker({
    required this.position,
    required this.layout,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate scale factors
    final scaleX = layout.width / constraints.maxWidth;
    final scaleY = layout.height / constraints.maxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calculate offset (centered map)
    final scaledWidth = layout.width / scale;
    final scaledHeight = layout.height / scale;
    final offsetX = (constraints.maxWidth - scaledWidth) / 2;
    final offsetY = (constraints.maxHeight - scaledHeight) / 2;
    
    // Convert store coordinates to screen coordinates
    final screenX = offsetX + (position.x / scale);
    final screenY = offsetY + (position.y / scale);
    
    return Positioned(
      left: screenX - 10,
      top: screenY - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
