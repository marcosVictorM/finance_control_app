// lib/screens/list_detail_screen.dart
import 'package:app_financas/models/shopping_list_item_model.dart';
import 'package:app_financas/models/shopping_list_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:app_financas/screens/add_transaction_screen.dart'; // Import que já tínhamos
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _showAddItemDialog() {
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
                  final price = double.tryParse(priceController.text);
                  
                  final newItem = ShoppingListItemModel(
                    itemName: itemName,
                    link: linkController.text.isNotEmpty ? linkController.text : null,
                    price: price,
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

  void _showEditItemDialog(ShoppingListItemModel itemToEdit, int index) {
    final TextEditingController itemController = TextEditingController(text: itemToEdit.itemName);
    final TextEditingController linkController = TextEditingController(text: itemToEdit.link);
    final TextEditingController priceController = TextEditingController(text: itemToEdit.price?.toStringAsFixed(2) ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Item'),
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
                  final price = double.tryParse(priceController.text);
                  final updatedItem = ShoppingListItemModel(
                    itemName: itemName,
                    link: linkController.text.isNotEmpty ? linkController.text : null,
                    price: price,
                    isChecked: itemToEdit.isChecked,
                  );
                  
                  setState(() {
                    _items[index] = updatedItem;
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

  // --- MUDANÇA 1: Widget da Barra de Soma ---
  Widget _buildSummaryBar() {
    // 1. Calcular os totais
    double totalPrice = 0.0;
    double checkedPrice = 0.0;

    for (var item in _items) {
      if (item.price != null) {
        totalPrice += item.price!;
        if (item.isChecked) {
          checkedPrice += item.price!;
        }
      }
    }
    
    // Se não houver preços, não mostra a barra
    if (totalPrice == 0.0) {
      return const SizedBox.shrink(); // Retorna widget vazio
    }

    // 2. Construir o Card
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumo da Lista',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comprado:', style: TextStyle(fontSize: 14)),
                Text(
                  'R\$ ${checkedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Previsto:', style: TextStyle(fontSize: 14)),
                Text(
                  'R\$ ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // --- FIM MUDANÇA 1 ---

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
      
      // --- MUDANÇA 2: Adicionar a barra de soma no rodapé ---
      bottomNavigationBar: _buildSummaryBar(),
      // --- FIM MUDANÇA 2 ---
      
      body: ListView.builder(
        // --- MUDANÇA 3: Adicionar padding para não cobrir o último item ---
        // (100 é uma estimativa segura para a altura da barra de soma + FAB)
        padding: const EdgeInsets.only(bottom: 150.0), 
        // --- FIM MUDANÇA 3 ---
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
            
            child: GestureDetector(
              onLongPress: () {
                _showEditItemDialog(item, index);
              },
              child: CheckboxListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.itemName),
                    if (item.price != null)
                      Text(
                        'R\$ ${item.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
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

                  if (newValue == true && item.price != null && item.price! > 0) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Lançar Despesa?'),
                          content: Text('Deseja lançar "${item.itemName}" (R\$ ${item.price!.toStringAsFixed(2)}) como uma nova despesa?'),
                          actions: [
                            TextButton(
                              child: const Text('Não'),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                            ElevatedButton(
                              child: const Text('Sim'),
                              onPressed: () {
                                Navigator.pop(dialogContext); 
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransactionScreen(
                                      initialDescription: item.itemName,
                                      initialAmount: item.price,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}