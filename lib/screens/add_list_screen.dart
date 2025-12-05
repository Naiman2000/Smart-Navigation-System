import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/product_search_field.dart';

class AddListScreen extends StatefulWidget {
  const AddListScreen({super.key});

  @override
  State<AddListScreen> createState() => _AddListScreenState();
}

class _AddListScreenState extends State<AddListScreen> {
  final _firebaseService = FirebaseService();
  
  final _listNameController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  
  final List<ShoppingItem> _items = [];
  bool _isSaving = false;
  bool _isLoadingEditData = false; // Track if we're loading edit data
  int _loadRetryCount = 0; // Track retry attempts
  static const int _maxRetries = 3; // Maximum retry attempts
  String? _errorMessage;
  String? _editingListId; // Track if we're editing an existing list
  bool _isEditMode = false;
  String? _selectedProductId; // Store the selected product ID from search
  String? _lastSearchedProductName; // Track the last product name from search

  @override
  void initState() {
    super.initState();
    // Load existing list data after navigation completes
    // Use multiple callbacks to ensure route is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit more to ensure route is fully established
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadExistingListData();
        }
      });
    });
  }

  void _loadExistingListData() {
    if (!mounted) return;
    
    setState(() {
      _isLoadingEditData = true;
    });
    
    try {
      // Try to get arguments from route
      final route = ModalRoute.of(context);
      if (route == null) {
        if (_loadRetryCount < _maxRetries) {
          _loadRetryCount++;
          debugPrint('Route not available yet, retrying ($_loadRetryCount/$_maxRetries)');
          // Retry after a short delay
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _loadExistingListData();
            }
          });
        } else {
          debugPrint('Max retries reached, continuing without edit data');
          if (mounted) {
            setState(() {
              _isLoadingEditData = false;
            });
          }
        }
        return;
      }

      final arguments = route.settings.arguments;
      if (arguments is ShoppingListModel) {
        final existingList = arguments;
        if (mounted) {
          setState(() {
            _isEditMode = true;
            _editingListId = existingList.listId;
            _listNameController.text = existingList.listName;
            _items.addAll(existingList.items);
            _isLoadingEditData = false;
          });
          debugPrint('Edit mode loaded: ${existingList.listName} with ${existingList.items.length} items');
        }
      } else {
        debugPrint('No edit arguments found, creating new list');
        if (mounted) {
          setState(() {
            _isLoadingEditData = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading existing list data: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue without edit mode if there's an error
      if (mounted) {
        setState(() {
          _isEditMode = false;
          _editingListId = null;
          _isLoadingEditData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _listNameController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _addItemToList() {
    final itemName = _itemNameController.text.trim();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unit = _unitController.text.trim();

    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item name')),
      );
      return;
    }

    setState(() {
      final item = ShoppingItem(
        itemId: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: _selectedProductId ?? '', // Use selected product ID if available
        productName: itemName,
        quantity: quantity,
        unit: unit.isNotEmpty ? unit : 'piece',
        isCompleted: false,
        addedAt: DateTime.now(),
      );
      _items.add(item);
      
      // Clear fields
      _itemNameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _selectedProductId = null; // Clear the selected product ID
      _lastSearchedProductName = null; // Clear the last searched product name
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName to list'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removed')),
    );
  }

  String _getDefaultUnit(String category) {
    switch (category.toLowerCase()) {
      case 'dairy & eggs':
      case 'dairy':
        return 'liter';
      case 'meat & seafood':
      case 'meat':
        return 'kg';
      case 'produce':
        return 'kg';
      case 'beverages':
        return 'liter';
      case 'frozen foods':
      case 'frozen':
        return 'pack';
      case 'pantry staples':
      case 'pantry':
        return 'piece';
      case 'household items':
      case 'household':
        return 'piece';
      case 'personal care':
        return 'piece';
      default:
        return 'piece';
    }
  }

  Future<void> _saveShoppingList() async {
    final listName = _listNameController.text.trim();
    
    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _errorMessage = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditMode && _editingListId != null) {
        debugPrint('Updating shopping list: $_editingListId');
        
        // Editing existing list
        // Get current list to preserve item completion status with timeout
        final currentList = await _firebaseService.getShoppingList(_editingListId!)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Request timed out. Please check your connection and try again.');
              },
            );
        
        if (currentList == null) {
          throw Exception('List not found');
        }
        debugPrint('Current list loaded: ${currentList.items.length} items');

        // Update list name if changed
        if (currentList.listName != listName) {
          debugPrint('Updating list name');
          await _firebaseService.updateShoppingListName(
            listId: _editingListId!,
            listName: listName,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Update timed out. Please try again.');
            },
          );
        }

        // Preserve completion status for existing items
        final existingItemsMap = {
          for (var item in currentList.items) item.itemId: item
        };
        
        // Merge completion status from existing items into current items
        final updatedItems = _items.map((item) {
          final existingItem = existingItemsMap[item.itemId];
          if (existingItem != null) {
            // Preserve completion status and addedAt timestamp from existing item
            return item.copyWith(
              isCompleted: existingItem.isCompleted,
              addedAt: existingItem.addedAt,
            );
          }
          return item;
        }).toList();

        debugPrint('Updating ${updatedItems.length} items');
        // Update all items (handles adds, updates, and deletes) with timeout
        await _firebaseService.updateShoppingListItems(
          listId: _editingListId!,
          items: updatedItems,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Update timed out. Please check your connection and try again.');
          },
        );
        debugPrint('List updated successfully');

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('List updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back immediately without delay
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        }
      } else {
        debugPrint('Creating new shopping list');
        
        // Creating new list
        final listId = await _firebaseService.createShoppingList(
          userId: userId,
          listName: listName,
        );
        debugPrint('List created with ID: $listId');

        // Add all items to the list in a single batch operation
        debugPrint('Adding ${_items.length} items to list');
        await _firebaseService.addItemsToListBatch(
          listId: listId,
          items: _items,
        );
        debugPrint('Items added successfully');

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grocery list created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back immediately without delay
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving shopping list: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save list: ${e.toString()}';
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading edit data
    if (_isLoadingEditData) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Grocery List' : 'New Grocery List'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // List Name Input
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_basket, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Grocery List Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _listNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Weekly Shopping, Party Supplies',
                        prefixIcon: const Icon(Icons.label),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Add Items Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Grocery Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Product Search Field
                    ProductSearchField(
                      labelText: 'Product Name',
                      hintText: 'Search for products...',
                      onProductSelected: (ProductModel product) {
                        setState(() {
                          _itemNameController.text = product.name;
                          _selectedProductId = product.productId; // Store the product ID
                          _lastSearchedProductName = product.name; // Track the searched product name
                          // Set default unit based on category if not set
                          if (_unitController.text.isEmpty) {
                            _unitController.text = _getDefaultUnit(product.category);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Manual entry option
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemNameController,
                            decoration: InputDecoration(
                              labelText: 'Or enter manually',
                              hintText: 'Type product name',
                              prefixIcon: const Icon(Icons.edit),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              // Clear selected product ID if user manually edits (different from searched product)
                              if (_selectedProductId != null && 
                                  _lastSearchedProductName != null &&
                                  value != _lastSearchedProductName) {
                                setState(() {
                                  _selectedProductId = null;
                                  _lastSearchedProductName = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Quantity and Unit Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              hintText: '1',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'piece, kg, liter, etc.',
                              prefixIcon: const Icon(Icons.format_size),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Item Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Add Item',
                        onPressed: _addItemToList,
                        icon: Icons.add,
                        variant: ButtonVariant.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Items List
            if (_items.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.list, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode 
                      ? 'All Items (${_items.length})' 
                      : 'Items (${_items.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isEditMode) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Edit Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isSaving 
                  ? 'Saving...' 
                  : (_isEditMode ? 'Update List' : 'Save Grocery List'),
                onPressed: _isSaving ? null : _saveShoppingList,
                isLoading: _isSaving,
                icon: _isEditMode ? Icons.update : Icons.save,
                height: 56,
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
