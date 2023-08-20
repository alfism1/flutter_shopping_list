import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

// import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
      'flutter-prep-4722f-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        throw Exception("Something went wrong. Please try again later.");
        // setState(() {
        //   error = 'Failed to load items. Please try again later.';
        // });
        // return;
      }

      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final loadedItems = <GroceryItem>[];
      json.decode(response.body).forEach((key, value) {
        final category = categories.entries
            .firstWhere((element) => element.value.name == value['category'])
            .value;

        loadedItems.add(
          GroceryItem(
            id: key,
            name: value['name'],
            quantity: value['quantity'],
            category: category,
          ),
        );
      });

      setState(() {
        _groceryItems.clear();
        _groceryItems.addAll(loadedItems);
        isLoading = false;
      });
    } catch (e) {
      final errorMessage = e.toString().replaceFirst("Exception:", "").trim();
      setState(() {
        // remove "Exception"
        error = errorMessage;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    // _loadItem();

    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    // if (direction == DismissDirection.endToStart) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: const Text('Item deleted'),
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    // }

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'flutter-prep-4722f-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Delete item failed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.red),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {
        _groceryItems.add(item);
        // error = 'Failed to delete item. Please try again later.';
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet'));

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(_groceryItems[index].id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 4,
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
            ),
            onDismissed: (direction) => _removeItem(_groceryItems[index]),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _groceryItems[index].category.color,
                  // shape: BoxShape.circle,
                ),
              ),
              trailing: Text('${_groceryItems[index].quantity}'),
            ),
          );
        },
      );
    }

    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
