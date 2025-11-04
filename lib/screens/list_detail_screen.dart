// lib/screens/list_detail_screen.dart
import 'package:app_financas/models/shopping_list_item_model.dart';
import 'package:app_financas/models/shopping_list_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para o teclado numérico
import 'add_transaction_screen.dart';

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
// lib/screens/list_detail_screen.dart

// ... (dentro da classe _ListDetailScreenState) ...

  // 7. NOVA FUNÇÃO: Mostrar o pop-up de "Editar Item"
  void _showEditItemDialog(ShoppingListItemModel itemToEdit, int index) {
    // Pré-preenche os controladores com os dados existentes do item
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
                  
                  // Cria o novo item atualizado
                  final updatedItem = ShoppingListItemModel(
                    itemName: itemName,
                    link: linkController.text.isNotEmpty ? linkController.text : null,
                    price: price,
                    isChecked: itemToEdit.isChecked, // Mantém o status do checkbox
                  );
                  
                  // Atualiza o estado local E o Firebase
                  setState(() {
                    _items[index] = updatedItem; // Atualiza o item NAQUELE índice
                  });
                  _updateListInFirebase();
                  Navigator.pop(context); // Fecha o pop-up
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
                
                // --- INÍCIO DA MUDANÇA (Lógica do onChanged) ---
                onChanged: (bool? newValue) {
                  if (newValue == null) return;
                  
                  // Atualiza o estado visual primeiro
                  setState(() {
                    item.isChecked = newValue;
                  });
                  
                  // Salva a mudança (marcado/desmarcado) no Firebase
                  _updateListInFirebase(); 

                  // SE o item foi MARCADO (true) E tem um preço
                  if (newValue == true && item.price != null && item.price! > 0) {
                    // Mostra o pop-up de confirmação
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
                                Navigator.pop(dialogContext); // Fecha o diálogo
                                // Navega para a tela de Adicionar, pré-preenchendo os campos
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
                // --- FIM DA MUDANÇA ---
              ),
            ),
          );
        },
      ),
    );
  }
}