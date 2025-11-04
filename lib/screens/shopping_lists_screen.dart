// lib/screens/shopping_lists_screen.dart
import 'package:app_financas/models/shopping_list_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'list_detail_screen.dart';

// (Vamos criar esta tela em seguida)
// import 'list_detail_screen.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Função para mostrar o pop-up de "Nova Lista"
  void _showCreateListDialog() {
    final TextEditingController listNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Lista de Compras'),
          content: TextField(
            controller: listNameController,
            decoration: const InputDecoration(hintText: "Nome da lista"),
            autofocus: true,
          ),
          actions: [
            // Botão Cancelar
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            // Botão Criar
            ElevatedButton(
              child: const Text('Criar'),
              onPressed: () {
                final listName = listNameController.text;
                if (listName.isNotEmpty) {
                  // Usa nosso serviço para criar a lista
                  _firestoreService.createShoppingList(listName);
                  Navigator.pop(context); // Fecha o pop-up
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Função para navegar para os detalhes da lista
  void _navigateToListDetail(ShoppingListModel list) {
  // APAGUE a linha de print:
  // print("Navegar para a lista: ${list.listName}");

  // DESCOMENTE (ou adicione) estas linhas:
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ListDetailScreen(shoppingList: list),
    ),
  );
}
// NOVA FUNÇÃO: Diálogo de confirmação para excluir
  void _showDeleteListDialog(ShoppingListModel list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Lista'),
          content: Text('Tem certeza que deseja excluir a lista "${list.listName}"? Todos os seus itens serão perdidos.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () {
                // Chama o serviço que já existe
                _firestoreService.deleteShoppingList(list.id!);
                Navigator.pop(context); // Fecha o diálogo
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lista "${list.listName}" excluída.'),
                    backgroundColor: Colors.red,
                  ),
                );
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
      // Botão Flutuante (FAB) para criar novas listas
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        child: const Icon(Icons.add),
      ),

      // Corpo da tela com o "ouvinte" de listas
      body: StreamBuilder<List<ShoppingListModel>>(
        stream: _firestoreService.getShoppingListsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma lista de compras. Crie uma no botão +!'),
            );
          }

          final lists = snapshot.data!;

          // Constrói a lista de "cards"
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final itemCount = list.items.length;
              
              // Conta quantos itens estão marcados
              final checkedCount = list.items.where((item) => item.isChecked).length;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    list.listName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$checkedCount / $itemCount itens comprados'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToListDetail(list),
                  
                  // --- INÍCIO DA MUDANÇA ---
                  onLongPress: () {
                    _showDeleteListDialog(list);
                  },
                  // --- FIM DA MUDANÇA ---
                ),
              );
            },
          );
        },
      ),
    );
  }
}