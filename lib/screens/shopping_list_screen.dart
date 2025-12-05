import 'dart:async';
import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../services/firebase_service.dart';
import 'main_navigation_screen.dart' show MainNavigationExtension;

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _firebaseService = FirebaseService();
  List<ShoppingListModel> _shoppingLists = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<ShoppingListModel>>? _listsSubscription;

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadShoppingLists();
      }
    });
  }

  @override
  void dispose() {
    _listsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadShoppingLists() async {
    if (!mounted) return;
    
    // Cancel existing subscription if any
    await _listsSubscription?.cancel();
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not logged in';
            _isLoading = false;
          });
        }
        return;
      }

      _listsSubscription = _firebaseService
          .getUserShoppingLists(userId)
          .listen(
            (lists) {
              if (mounted) {
                setState(() {
                  _shoppingLists = lists;
                  _isLoading = false;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to load shopping lists: $error';
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shopping lists: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleItemComplete(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    try {
      await _firebaseService.updateItemStatus(
        listId: listId,
        itemId: itemId,
        isCompleted: !isCompleted,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
      }
    }
  }

  Future<void> _editList(ShoppingListModel list) async {
    if (!mounted) return;
    
    try {
      // Navigate to add list screen with existing list data for editing
      // Use unawaited to prevent blocking
      final result = await Navigator.pushNamed(
        context,
        '/addList',
        arguments: list,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Navigation timed out');
        },
      );
      
      // Refresh lists after editing
      if (result == true && mounted) {
        _loadShoppingLists();
      }
    } catch (e) {
      debugPrint('Error navigating to edit screen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open edit screen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteList(String listId) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: const Text(
          'Are you sure you want to delete this shopping list?',
        ),
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

    if (confirmed != true) return;
    
    try {
      // Proceed with deletion regardless of mounted state
      // Firebase operations don't require the widget to be mounted
      await _firebaseService.deleteShoppingList(listId);
      
      // Only check mounted before using context for UI updates
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete list: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Grocery Lists'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/addList'),
            tooltip: 'Add new list',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShoppingLists,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadShoppingLists,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _shoppingLists.isEmpty
          ? _buildEmptyState()
          : _buildShoppingLists(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'shopping_list_fab', // Unique tag to prevent Hero conflicts
        onPressed: () => Navigator.pushNamed(context, '/addList'),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
        tooltip: 'Create a new grocery list',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Grocery Lists Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating your first grocery list',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/addList'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Create New List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingLists() {
    return RefreshIndicator(
      onRefresh: _loadShoppingLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shoppingLists.length,
        // Add cache extent for better scrolling performance
        cacheExtent: 200,
        // Add physics for better performance
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final list = _shoppingLists[index];
          return _buildShoppingListCard(list);
        },
      ),
    );
  }

  Widget _buildShoppingListCard(ShoppingListModel list) {
    final completedItems = list.items.where((item) => item.isCompleted).length;
    final totalItems = list.items.length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
              onTap: () {
                // Switch to Map tab and pass the list
                final mainNav = context.getMainNavigationState();
                if (mainNav != null) {
                  mainNav.switchToTab(1); // Switch to Map tab
                  // Note: To pass arguments, we'd need a more sophisticated approach
                  // For now, just switch to map tab
                } else {
                  Navigator.pushNamed(context, '/map', arguments: list);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_basket, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.listName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${_formatDate(list.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editList(list),
                    tooltip: 'Edit list',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteList(list.listId),
                    tooltip: 'Delete list',
                  ),
                ],
              ),
            ),

            // Progress Bar
            if (totalItems > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0
                                ? Colors.green
                                : Colors.green.shade400,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$completedItems/$totalItems',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // Items List (show max 3 items)
            if (list.items.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (int i = 0; i < list.items.take(3).length; i++)
                      _buildItemRow(list.items[i], list.listId),
                    if (list.items.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+ ${list.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No items in this list',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item, String listId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: item.isCompleted,
            onChanged: (bool? value) {
              _toggleItemComplete(listId, item.itemId, item.isCompleted);
            },
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.productName,
              style: TextStyle(
                fontSize: 15,
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: item.isCompleted ? Colors.grey : Colors.black87,
                fontWeight: item.isCompleted
                    ? FontWeight.normal
                    : FontWeight.w500,
              ),
            ),
          ),
          Text(
            item.quantityDisplay,
            style: TextStyle(
              fontSize: 14,
              color: item.isCompleted
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
