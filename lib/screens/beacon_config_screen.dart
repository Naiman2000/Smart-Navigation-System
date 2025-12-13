import 'dart:async';
import 'package:flutter/material.dart';
import '../services/beacon_config_service.dart';
import '../models/beacon_model.dart';
import '../models/store_layout_model.dart';
import '../data/store_layout_config.dart';
import '../widgets/store_map_widget.dart';
import '../theme/app_theme.dart';

class BeaconConfigScreen extends StatefulWidget {
  const BeaconConfigScreen({super.key});

  @override
  State<BeaconConfigScreen> createState() => _BeaconConfigScreenState();
}

class _BeaconConfigScreenState extends State<BeaconConfigScreen> {
  final _beaconConfigService = BeaconConfigService();
  StreamSubscription<List<BeaconModel>>? _beaconsSubscription;
  List<BeaconModel> _beacons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadBeacons();
  }

  @override
  void dispose() {
    _beaconsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBeacons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load initial beacons
      final beacons = await _beaconConfigService.getAllBeacons();
      setState(() {
        _beacons = beacons;
        _isLoading = false;
      });

      // Subscribe to real-time updates
      _beaconsSubscription = _beaconConfigService
          .getBeaconsStream()
          .listen((beacons) {
        if (mounted) {
          setState(() {
            _beacons = beacons;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load beacons: $e')),
        );
      }
    }
  }

  List<BeaconModel> get _filteredBeacons {
    var filtered = _beacons;

    if (_showActiveOnly) {
      filtered = filtered.where((b) => b.isActive).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.name.toLowerCase().contains(query) ||
            b.macAddress.toLowerCase().contains(query) ||
            b.beaconId.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _toggleBeaconActive(BeaconModel beacon) async {
    try {
      await _beaconConfigService.toggleBeaconActive(
        beacon.beaconId,
        !beacon.isActive,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update beacon: $e')),
        );
      }
    }
  }

  Future<void> _deleteBeacon(BeaconModel beacon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Beacon'),
        content: Text('Are you sure you want to delete "${beacon.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _beaconConfigService.deleteBeacon(beacon.beaconId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Beacon deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete beacon: $e')),
          );
        }
      }
    }
  }

  Future<void> _editBeacon(BeaconModel beacon) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BeaconEditScreen(beacon: beacon),
      ),
    );

    if (result == true) {
      _loadBeacons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configured Beacons'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/beaconPairing');
            },
            tooltip: 'Pair New Beacon',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search beacons...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Checkbox(
                      value: _showActiveOnly,
                      onChanged: (value) {
                        setState(() {
                          _showActiveOnly = value ?? false;
                        });
                      },
                    ),
                    const Text('Show active only'),
                    const Spacer(),
                    Text(
                      '${_filteredBeacons.length} beacons',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Beacons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBeacons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              _beacons.isEmpty
                                  ? 'No beacons configured yet'
                                  : 'No beacons match your search',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            if (_beacons.isEmpty) ...[
                              const SizedBox(height: AppTheme.spacingM),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/beaconPairing');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Pair First Beacon'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        itemCount: _filteredBeacons.length,
                        itemBuilder: (context, index) {
                          final beacon = _filteredBeacons[index];
                          return _buildBeaconCard(beacon);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeaconCard(BeaconModel beacon) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: beacon.isActive
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bluetooth,
            color: beacon.isActive
                ? AppTheme.primaryColor
                : Colors.grey,
          ),
        ),
        title: Text(
          beacon.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: beacon.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              beacon.macAddress,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: beacon.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    beacon.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Position: (${beacon.position.x.toStringAsFixed(1)}, ${beacon.position.y.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    beacon.isActive ? Icons.toggle_on : Icons.toggle_off,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(beacon.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editBeacon(beacon);
                break;
              case 'toggle':
                _toggleBeaconActive(beacon);
                break;
              case 'delete':
                _deleteBeacon(beacon);
                break;
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Beacon ID', beacon.beaconId),
                _buildInfoRow('MAC Address', beacon.macAddress),
                _buildInfoRow('Transmit Power', '${beacon.txPower} dBm'),
                _buildInfoRow(
                  'Position',
                  '(${beacon.position.x.toStringAsFixed(2)}, ${beacon.position.y.toStringAsFixed(2)})',
                ),
                if (beacon.lastSeen != null)
                  _buildInfoRow(
                    'Last Seen',
                    _formatDateTime(beacon.lastSeen!),
                  ),
                _buildInfoRow('Created', _formatDateTime(beacon.createdAt)),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editBeacon(beacon),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    OutlinedButton.icon(
                      onPressed: () => _toggleBeaconActive(beacon),
                      icon: Icon(
                        beacon.isActive ? Icons.toggle_on : Icons.toggle_off,
                      ),
                      label: Text(beacon.isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Screen for editing beacon configuration
class _BeaconEditScreen extends StatefulWidget {
  final BeaconModel beacon;

  const _BeaconEditScreen({required this.beacon});

  @override
  State<_BeaconEditScreen> createState() => _BeaconEditScreenState();
}

class _BeaconEditScreenState extends State<_BeaconEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _beaconConfigService = BeaconConfigService();
  int _txPower = -59;
  Point? _selectedPosition;
  bool _showMapPicker = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.beacon.name;
    _txPower = widget.beacon.txPower;
    _selectedPosition = widget.beacon.position;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Update name
      if (_nameController.text.trim() != widget.beacon.name) {
        await _beaconConfigService.updateBeaconName(
          widget.beacon.beaconId,
          _nameController.text.trim(),
        );
      }

      // Update txPower
      if (_txPower != widget.beacon.txPower) {
        await _beaconConfigService.updateBeaconTxPower(
          widget.beacon.beaconId,
          _txPower,
        );
      }

      // Update position
      if (_selectedPosition != null &&
          _selectedPosition != widget.beacon.position) {
        await _beaconConfigService.updateBeaconPosition(
          widget.beacon.beaconId,
          _selectedPosition!,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beacon updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update beacon: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Beacon'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showMapPicker
          ? _buildMapPicker()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Beacon Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Beacon Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Beacon Name',
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
                            Text(
                              'MAC Address: ${widget.beacon.macAddress}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingM),

                    // Transmit Power
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transmit Power',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            Text(
                              '$_txPower dBm',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingM),

                    // Position
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Position on Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            if (_selectedPosition != null)
                              Text(
                                'Current: (${_selectedPosition!.x.toStringAsFixed(1)}, ${_selectedPosition!.y.toStringAsFixed(1)})',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: AppTheme.spacingS),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showMapPicker = true;
                                });
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('Change Position'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Save Changes',
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
                  'Select New Position',
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
}

/// Map position picker widget (reused from pairing screen)
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

/// Position marker widget (reused from pairing screen)
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
