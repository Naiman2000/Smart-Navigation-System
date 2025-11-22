import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../services/firebase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      _firebaseService.getUserShoppingLists(userId).listen((lists) {
        setState(() {
          _shoppingLists = lists;
          _isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load shopping lists: $error';
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load shopping lists: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItemComplete(String listId, String itemId, bool isCompleted) async {
    try {
      await _firebaseService.updateItemStatus(
        listId: listId,
        itemId: itemId,
        isCompleted: !isCompleted,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
        );
      }
    }
  }

  Future<void> _deleteList(String listId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: const Text('Are you sure you want to delete this shopping list?'),
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
        await _firebaseService.deleteShoppingList(listId);
        _loadShoppingLists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('List deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete list: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Shopping Lists'),
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
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
        onPressed: () => Navigator.pushNamed(context, '/addList'),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Add Items'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No Shopping Lists',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
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
          // Navigate to list details or map view
          Navigator.pushNamed(context, '/map', arguments: list);
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            progress == 1.0 ? Colors.green : Colors.green.shade400,
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
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                color: item.isCompleted ? Colors.grey : Colors.black87,
                fontWeight: item.isCompleted ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
          Text(
            item.quantityDisplay,
            style: TextStyle(
              fontSize: 14,
              color: item.isCompleted ? Colors.grey.shade400 : Colors.grey.shade600,
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
