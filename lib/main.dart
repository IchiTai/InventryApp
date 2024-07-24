import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventoryProvider(),
      child: MaterialApp(
        title: 'Inventory App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: InventoryScreen(),
      ),
    );
  }
}

class InventoryProvider with ChangeNotifier {
  Map<String, List<Item>> _categories = {};

  InventoryProvider() {
    _loadItems();
  }

  Map<String, List<Item>> get categories => _categories;

  void addCategory(String category) {
    if (!_categories.containsKey(category)) {
      _categories[category] = [];
      _saveItems();
      notifyListeners();
    }
  }

  void removeCategory(String category) {
    if (_categories.containsKey(category)) {
      _categories.remove(category);
      _saveItems();
      notifyListeners();
    }
  }

  void addItem(String category, String name, int quantity) {
    if (_categories.containsKey(category)) {
      _categories[category]?.add(Item(name, quantity));
      _saveItems();
      notifyListeners();
    }
  }

  void updateItemQuantity(String category, int index, int quantity) {
    if (_categories.containsKey(category)) {
      _categories[category]?[index].quantity = quantity;
      _saveItems();
      notifyListeners();
    }
  }

  void removeItem(String category, int index) {
    if (_categories.containsKey(category)) {
      _categories[category]?.removeAt(index);
      _saveItems();
      notifyListeners();
    }
  }

  void _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, List<Map<String, dynamic>>> data = {};
    _categories.forEach((key, value) {
      data[key] = value.map((item) => item.toMap()).toList();
    });
    prefs.setString('categories', json.encode(data));
  }

  void _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('categories');
    if (data != null) {
      Map<String, dynamic> jsonData = json.decode(data);
      jsonData.forEach((key, value) {
        _categories[key] =
            List<Item>.from(value.map((item) => Item.fromMap(item)));
      });
      notifyListeners();
    }
  }
}

class Item {
  String name;
  int quantity;

  Item(this.name, this.quantity);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      map['name'],
      map['quantity'],
    );
  }
}

class InventoryScreen extends StatelessWidget {
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final category = _categoryController.text;
              if (category.isNotEmpty) {
                context.read<InventoryProvider>().addCategory(category);
              }
            },
            child: Text('Add Category'),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.categories.keys.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories.keys.elementAt(index);
                    return ListTile(
                      title: Text(category),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, category);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryItemsScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Category'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<InventoryProvider>().removeCategory(category);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class CategoryItemsScreen extends StatelessWidget {
  final String category;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  CategoryItemsScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items in $category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text;
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              if (name.isNotEmpty) {
                context
                    .read<InventoryProvider>()
                    .addItem(category, name, quantity);
              }
            },
            child: Text('Add Item'),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final items = provider.categories[category] ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                          '${items[index].name} - ${items[index].quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (items[index].quantity > 0) {
                                provider.updateItemQuantity(
                                    category, index, items[index].quantity - 1);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              provider.updateItemQuantity(
                                  category, index, items[index].quantity + 1);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              provider.removeItem(category, index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
