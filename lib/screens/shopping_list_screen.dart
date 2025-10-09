import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Sample shopping list data - in a real app, this would come from a database
  final List<Map<String, dynamic>> _shoppingList = [
    {'name': 'Milk', 'quantity': '2 liters', 'isCompleted': false},
    {'name': 'Bread', 'quantity': '1 loaf', 'isCompleted': false},
    {'name': 'Eggs', 'quantity': '12 pieces', 'isCompleted': true},
    {'name': 'Bananas', 'quantity': '6 pieces', 'isCompleted': false},
    {'name': 'Chicken', 'quantity': '1 kg', 'isCompleted': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/addList'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Shopping List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_shoppingList.where((item) => !item['isCompleted']).length} items remaining',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _shoppingList.length,
                itemBuilder: (context, index) {
                  final item = _shoppingList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: item['isCompleted'] ? Colors.grey[200] : Colors.white,
                    child: CheckboxListTile(
                      value: item['isCompleted'],
                      onChanged: (bool? value) {
                        setState(() {
                          item['isCompleted'] = value ?? false;
                        });
                      },
                      title: Text(
                        item['name'],
                        style: TextStyle(
                          decoration: item['isCompleted'] 
                              ? TextDecoration.lineThrough 
                              : TextDecoration.none,
                          color: item['isCompleted'] 
                              ? Colors.grey 
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(item['quantity']),
                      secondary: Icon(
                        Icons.shopping_basket,
                        color: item['isCompleted'] ? Colors.grey : Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addList'),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
