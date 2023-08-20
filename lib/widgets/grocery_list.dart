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

  // late is for non-nullable variable that is not initialized in the constructor (e.g. Future)
  // and will be initialized later in the code (e.g. in initState())
  // to avoid null safety error (e.g. _loadedItem = _loadItem();)
  // and to avoid using nullable variable (e.g. Future<List<GroceryItem>>? _loadedItem;)
  // which is not recommended in Flutter (e.g. FutureBuilder<List<GroceryItem>>(future: _loadedItem, builder: (context, snapshot) {return content;},),)
  // because it will cause the widget to rebuild twice (e.g. first time is null, second time is the actual value)
  // which is not good for performance
  late Future<List<GroceryItem>> _loadedItem;
  // bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadedItem = _loadItem();
  }

  Future<List<GroceryItem>> _loadItem() async {
    final url = Uri.https(
      'flutter-prep-4722f-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    // try {
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception("Something went wrong. Please try again later.");
      // setState(() {
      //   error = 'Failed to load items. Please try again later.';
      // });
      // return;
    }

    if (response.body == 'null') {
      // setState(() {
      //   isLoading = false;
      // });
      return [];
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

    return loadedItems;

    // setState(() {
    //   _groceryItems.clear();
    //   _groceryItems.addAll(loadedItems);
    //   isLoading = false;
    // });
    // } catch (e) {
    //   final errorMessage = e.toString().replaceFirst("Exception:", "").trim();
    //   setState(() {
    //     // remove "Exception"
    //     error = errorMessage;
    //   });
    // }
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
      'dlutter-prep-4722f-default-rtdb.asia-southeast1.firebasedatabase.app',
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
      body: FutureBuilder(
        future: _loadedItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No items added yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return Dismissible(
                key: ValueKey(snapshot.data![index].id),
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
                onDismissed: (direction) => _removeItem(snapshot.data![index]),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: snapshot.data![index].category.color,
                      // shape: BoxShape.circle,
                    ),
                  ),
                  trailing: Text('${snapshot.data![index].quantity}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
