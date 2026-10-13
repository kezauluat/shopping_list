import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const HomeScreen(title: 'Cart'),
    );
  }
}

// ---------- Model ----------
class Item {
  String name; // not final: the details screen can rename it (Part 6)
  bool bought;
  int quantity; // Part 2
  String note; // Part 6
  String category; // Part 6

  Item(
    this.name, {
    this.bought = false,
    this.quantity = 1,
    this.note = '',
    this.category = 'Food',
  });
}

// ---------- Home screen ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Item> items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final TextEditingController controller = TextEditingController();
  String filter = 'All'; // Part 5

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), action: action),
    );
  }

  // Part 3: no duplicates, just more
  void addItem() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      showMessage('Please type an item name');
      return;
    }
    final matches =
        items.where((item) => item.name.toLowerCase() == name.toLowerCase());
    if (matches.isNotEmpty) {
      final existing = matches.first;
      setState(() {
        existing.quantity++;
      });
      showMessage(
          '${existing.name} is already on the list: now ×${existing.quantity}');
    } else {
      setState(() {
        items.add(Item(name));
      });
    }
    controller.clear();
  }

  void toggleBought(Item item) {
    setState(() {
      item.bought = !item.bought;
    });
  }

  // Part 2: quantity never below 1
  void increase(Item item) {
    setState(() {
      item.quantity++;
    });
  }

  void decrease(Item item) {
    if (item.quantity > 1) {
      setState(() {
        item.quantity--;
      });
    }
  }

  // Part 4: delete with undo (removes the item itself, not an index)
  void deleteItem(Item item) {
    final position = items.indexOf(item); // remember where it was FIRST
    setState(() {
      items.remove(item);
    });
    showMessage(
      '${item.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            var place = position;
            if (place > items.length) place = items.length;
            items.insert(place, item);
          });
        },
      ),
    );
  }

  // Part 6: open the details screen, redraw when coming back
  void openDetails(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailsScreen(item: item)),
    ).then((_) {
      setState(() {});
    });
  }

  // Part 5: the list we show, built from items (items itself never changes)
  List<Item> get shown {
    final toBuy = items.where((item) => !item.bought).toList();
    final bought = items.where((item) => item.bought).toList();
    if (filter == 'To buy') return toBuy;
    if (filter == 'Bought') return bought;
    return [...toBuy, ...bought]; // All: bought items at the bottom
  }

  Widget buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: filter == label,
      onSelected: (_) {
        setState(() {
          filter = label;
        });
      },
    );
  }

  Widget buildList() {
    if (items.isEmpty) {
      return const Center(child: Text('Your list is empty')); // Part 1
    }
    final list = shown;
    if (list.isEmpty) {
      return const Center(child: Text('Nothing here')); // Part 5
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final details =
            item.note.isEmpty ? item.category : '${item.category} · ${item.note}';
        return ListTile(
          leading: const Icon(Icons.shopping_basket),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.bought ? TextDecoration.lineThrough : null,
              color: item.bought ? Colors.grey : null,
            ),
          ),
          subtitle: Text(details),
          onTap: () => toggleBought(item),
          onLongPress: () => openDetails(item),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => decrease(item),
              ),
              Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => increase(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deleteItem(item),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((item) => !item.bought).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($left left)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                items.clear();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type an item',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: addItem, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                buildFilterChip('All'),
                const SizedBox(width: 8),
                buildFilterChip('To buy'),
                const SizedBox(width: 8),
                buildFilterChip('Bought'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: buildList()),
          ],
        ),
      ),
    );
  }
}

// ---------- Details screen (Part 6) ----------
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});
  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String category = 'Food';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.item.name;
    noteController.text = widget.item.note;
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The name cannot be empty')),
      );
      return; // stay on this screen
    }
    // Only now do we change the real item, so the back arrow changes nothing
    widget.item.name = name;
    widget.item.note = noteController.text.trim();
    widget.item.category = category;
    Navigator.pop(context);
  }

  Widget buildCategoryChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: category == label,
      onSelected: (_) {
        setState(() {
          category = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            Row(
              children: [
                buildCategoryChip('Food'),
                const SizedBox(width: 8),
                buildCategoryChip('Drinks'),
                const SizedBox(width: 8),
                buildCategoryChip('Home'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}