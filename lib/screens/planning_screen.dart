// lib/screens/planning_screen.dart
import 'package:app_financas/models/budget_model.dart';
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanningScreen extends StatefulWidget {
  // --- MUDANÇA 1: Receber a data selecionada ---
  final DateTime selectedDate;
  
  const PlanningScreen({
    super.key,
    required this.selectedDate, // Agora é obrigatório
  });
  // --- FIM MUDANÇA 1 ---

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- MUDANÇA 2: Remover o estado local de data ---
  // DateTime _selectedDate = DateTime.now(); // REMOVIDO
  // --- FIM MUDANÇA 2 ---

  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];

  void _showCreateBudgetDialog() {
    final TextEditingController amountController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Orçamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text('Selecione uma categoria'),
                    items: _expenseCategories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() { selectedCategory = newValue; });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(hintText: "Valor Limite (R\$)"),
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
                  child: const Text('Criar'),
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && selectedCategory != null) {
                      final newBudget = BudgetModel(
                        category: selectedCategory!,
                        limitAmount: amount,
                        // --- MUDANÇA 3: Usar a data do widget ---
                        month: widget.selectedDate.month,
                        year: widget.selectedDate.year,
                        // --- FIM MUDANÇA 3 ---
                      );
                      _firestoreService.createBudget(newBudget);
                      Navigator.pop(context);
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

  // (Função _showDeleteBudgetDialog não muda)
  void _showDeleteBudgetDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Orçamento'),
          content: Text('Tem certeza que deseja excluir o orçamento da categoria "${budget.category}"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () {
                _firestoreService.deleteBudget(budget.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Orçamento "${budget.category}" excluído.'),
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
  void _showBudgetOptionsDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(budget.category),
          content: const Text('O que deseja fazer com este orçamento?'),
          actions: [
            // Botão de Excluir
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context); // Fecha o menu de opções
                _showDeleteBudgetDialog(budget); // Abre o diálogo de exclusão (que já existe)
              },
            ),
            // Botão de Editar
            ElevatedButton(
              child: const Text('Editar Limite'),
              onPressed: () {
                Navigator.pop(context); // Fecha o menu de opções
                _showEditBudgetDialog(budget); // Abre o diálogo de edição
              },
            ),
          ],
        );
      },
    );
  }
  void _showEditBudgetDialog(BudgetModel budget) {
    // Pré-preenche o campo com o valor limite atual
    final TextEditingController amountController = TextEditingController(
      text: budget.limitAmount.toStringAsFixed(2)
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Limite para "${budget.category}"'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: "Novo Valor Limite (R\$)"),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                final newAmount = double.tryParse(amountController.text);
                
                // Validação simples
                if (newAmount != null && newAmount >= 0) {
                  // 1. Chama o serviço para atualizar o Firestore
                  _firestoreService.updateBudgetLimit(budget.id!, newAmount);
                  
                  // 2. Fecha o pop-up
                  Navigator.pop(context); 
                  
                  // 3. Dá o feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orçamento atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Feedback de erro se o valor for inválido
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Valor inválido.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildBudgetsView(List<BudgetModel> budgets, List<TransactionModel> transactions) {
    if (budgets.isEmpty) {
      return const Center(
        child: Text('Nenhum orçamento definido para este mês. Crie um no botão +!'),
      );
    }

    // --- MUDANÇA 4: Usar a data do widget ---
    List<TransactionModel> monthExpenses = transactions.where((t) {
      return t.type == 'expense' && 
             t.date.month == widget.selectedDate.month && 
             t.date.year == widget.selectedDate.year;
    }).toList();
    // --- FIM MUDANÇA 4 ---

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        double currentSpending = monthExpenses
            .where((t) => t.category == budget.category)
            .fold(0.0, (sum, t) => sum + t.amount);
        double progress = 0.0;
        if (budget.limitAmount > 0) {
          progress = currentSpending / budget.limitAmount;
        }
        if (progress > 1.0) progress = 1.0; 
        Color progressColor = Colors.green;
        if (progress > 0.7) progressColor = Colors.orange;
        if (progress >= 1.0) progressColor = Colors.red;

        return InkWell(
          onLongPress: () {
            _showBudgetOptionsDialog(budget); 
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'R\$ ${budget.limitAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gasto: R\$ ${currentSpending.toStringAsFixed(2)} de R\$ ${budget.limitAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBudgetDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BudgetModel>>(
        // --- MUDANÇA 5: Usar a data do widget ---
        stream: _firestoreService.getBudgetsStream(widget.selectedDate.month, widget.selectedDate.year),
        // --- FIM MUDANÇA 5 ---
        builder: (context, budgetSnapshot) {
          return StreamBuilder<List<TransactionModel>>(
            stream: _firestoreService.getTransactionsStream(),
            builder: (context, transactionSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                  transactionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (budgetSnapshot.hasError) return Center(child: Text('Erro ao carregar orçamentos: ${budgetSnapshot.error}'));
              if (transactionSnapshot.hasError) return Center(child: Text('Erro ao carregar transações: ${transactionSnapshot.error}'));

              final budgets = budgetSnapshot.data ?? [];
              final transactions = transactionSnapshot.data ?? [];

              return _buildBudgetsView(budgets, transactions);
            },
          );
        },
      ),
    );
  }
}