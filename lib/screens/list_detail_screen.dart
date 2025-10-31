// lib/screens/list_detail_screen.dart
import 'package:app_financas/models/shopping_list_item_model.dart';
import 'package:app_financas/models/shopping_list_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para o teclado numérico

class ListDetailScreen extends StatefulWidget {
  final ShoppingListModel shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<ShoppingListItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.shoppingList.items);
  }

  Future<void> _updateListInFirebase() async {
    try {
      await _firestoreService.updateShoppingListItems(widget.shoppingList.id!, _items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 4. Função para mostrar o pop-up de "Adicionar Item"
  void _showAddItemDialog() {
    // --- MUDANÇA 1: Adicionar controlador de preço ---
    final TextEditingController itemController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(hintText: "Nome do item"),
                autofocus: true,
              ),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(hintText: "Link (opcional)"),
              ),
              // --- MUDANÇA 2: Adicionar campo de Valor ---
              TextField(
                controller: priceController,
                decoration: const InputDecoration(hintText: "Valor (opcional)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                final itemName = itemController.text;
                if (itemName.isNotEmpty) {
                  // --- MUDANÇA 3: Pegar o valor e salvar no modelo ---
                  final price = double.tryParse(priceController.text);
                  
                  final newItem = ShoppingListItemModel(
                    itemName: itemName,
                    link: linkController.text.isNotEmpty ? linkController.text : null,
                    price: price, // <-- Adicionado aqui
                  );
                  
                  setState(() {
                    _items.add(newItem);
                  });
                  _updateListInFirebase();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shoppingList.listName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return Dismissible(
            key: Key(item.itemName + index.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                _items.removeAt(index);
              });
              _updateListInFirebase();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.itemName} removido'), backgroundColor: Colors.red),
              );
            },
            child: CheckboxListTile(
              // --- MUDANÇA 4: Mostrar o preço na lista ---
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.itemName),
                  if (item.price != null)
                    Text(
                      'R\$ ${item.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green, // Cor de destaque para o preço
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              subtitle: item.link != null && item.link!.isNotEmpty 
                ? Text(item.link!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)) 
                : null,
              value: item.isChecked,
              onChanged: (bool? newValue) {
                if (newValue == null) return;
                setState(() {
                  item.isChecked = newValue;
                });
                _updateListInFirebase();
              },
            ),
          );
        },
      ),
    );
  }
}