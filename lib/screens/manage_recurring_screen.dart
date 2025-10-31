// lib/screens/manage_recurring_screen.dart
import 'package:app_financas/models/recurring_transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageRecurringScreen extends StatefulWidget {
  const ManageRecurringScreen({super.key});

  @override
  State<ManageRecurringScreen> createState() => _ManageRecurringScreenState();
}

class _ManageRecurringScreenState extends State<ManageRecurringScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Listas de categorias (para o dropdown)
  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];
  final List<String> _incomeCategories = ['Salário', 'Renda Extra'];

  // Função para mostrar o pop-up de "Novo Recorrente"
  void _showCreateRecurringDialog() {
    // Controladores
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController();

    // Estados do diálogo
    String selectedType = 'expense';
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) {
        // Usamos StatefulWidgetBuilder para atualizar o diálogo (dropdown)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            final currentCategories = selectedType == 'expense' 
                ? _expenseCategories 
                : _incomeCategories;
            
            if (selectedCategory != null && !currentCategories.contains(selectedCategory)) {
              selectedCategory = null;
            }
            
            return AlertDialog(
              title: const Text('Novo Recorrente'),
              scrollable: true, // Permite rolar se o teclado aparecer
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seletor de Tipo (Despesa / Receita)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Despesa')),
                      ButtonSegment(value: 'income', label: Text('Receita')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),

                  // Seletor de Categoria (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text('Categoria'),
                    items: currentCategories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),

                  TextField(
                    controller: dayController,
                    decoration: const InputDecoration(labelText: 'Dia do Mês (1-31)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
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
                    final amount = double.tryParse(amountController.text);
                    final day = int.tryParse(dayController.text);
                    
                    if (amount != null && day != null && selectedCategory != null) {
                      final newRecurring = RecurringTransactionModel(
                        description: descriptionController.text,
                        amount: amount,
                        type: selectedType,
                        category: selectedCategory!,
                        dayOfMonth: day,
                        // Não definimos 'lastPosted' para que ele seja sugerido
                      );
                      
                      _firestoreService.createRecurringTransaction(newRecurring);
                      Navigator.pop(context); // Fecha o pop-up
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorrentes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRecurringDialog,
        child: const Icon(Icons.add),
      ),
      
      // Corpo com o "ouvinte" dos modelos recorrentes
      body: StreamBuilder<List<RecurringTransactionModel>>(
        stream: _firestoreService.getRecurringTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma transação recorrente. Crie uma no botão +!'),
            );
          }

          final recurrents = snapshot.data!;

          return ListView.builder(
            itemCount: recurrents.length,
            itemBuilder: (context, index) {
              final item = recurrents[index];
              final isExpense = item.type == 'expense';

              return ListTile(
                leading: Icon(
                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isExpense ? Colors.red : Colors.green,
                ),
                title: Text(item.description),
                subtitle: Text('Todo dia ${item.dayOfMonth} - Categoria: ${item.category}'),
                trailing: Text(
                  '${isExpense ? '-' : '+'} R\$ ${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isExpense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Vamos adicionar o 'delete' num long-press
                onLongPress: () {
                   _firestoreService.deleteRecurringTransaction(item.id!);
                },
              );
            },
          );
        },
      ),
    );
  }
}