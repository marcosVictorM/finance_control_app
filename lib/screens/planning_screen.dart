// lib/screens/planning_screen.dart
import 'package:app_financas/models/budget_model.dart';
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 1. Estado para controlar o mês/ano selecionado
  DateTime _selectedDate = DateTime.now();

  // Lista de categorias de despesa (para o dropdown)
  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];

  // 2. Função para mostrar o pop-up de "Novo Orçamento"
  void _showCreateBudgetDialog() {
    final TextEditingController amountController = TextEditingController();
    String? selectedCategory; // Categoria selecionada no dropdown

    showDialog(
      context: context,
      builder: (context) {
        // Usamos StatefulWidgetBuilder para o dropdown poder atualizar
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Orçamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown para Categoria
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text('Selecione uma categoria'),
                    items: _expenseCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Campo de Valor Limite
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
                        month: _selectedDate.month, // Usa o mês/ano da tela
                        year: _selectedDate.year,
                      );
                      // Usa nosso serviço para criar o orçamento
                      _firestoreService.createBudget(newBudget);
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

  // 3. O "Cérebro" da tela: combina os dados de 2 Streams
  Widget _buildBudgetsView(List<BudgetModel> budgets, List<TransactionModel> transactions) {
    
    // Se não há orçamentos definidos, mostra uma mensagem
    if (budgets.isEmpty) {
      return const Center(
        child: Text('Nenhum orçamento definido para este mês. Crie um no botão +!'),
      );
    }

    // Filtra as transações para pegar apenas as despesas do mês/ano selecionado
    List<TransactionModel> monthExpenses = transactions.where((t) {
      return t.type == 'expense' && 
             t.date.month == _selectedDate.month && 
             t.date.year == _selectedDate.year;
    }).toList();

    // Constrói a lista de "cards" de orçamento
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        
        // 4. Calcula o Gasto Atual para esta categoria
        double currentSpending = monthExpenses
            .where((t) => t.category == budget.category) // Filtra pela categoria do orçamento
            .fold(0.0, (sum, t) => sum + t.amount); // Soma os valores

        double progress = 0.0;
        if (budget.limitAmount > 0) {
          progress = currentSpending / budget.limitAmount;
        }
        // Garante que o progresso não passe de 100% (para a barra)
        if (progress > 1.0) progress = 1.0; 

        Color progressColor = Colors.green;
        if (progress > 0.7) progressColor = Colors.orange;
        if (progress >= 1.0) progressColor = Colors.red;

        // 5. O Card do Orçamento
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Título e Limite
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
                
                // Linha 2: Barra de Progresso
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                const SizedBox(height: 8),

                // Linha 3: Texto (Gasto / Limite)
                Text(
                  'Gasto: R\$ ${currentSpending.toStringAsFixed(2)} de R\$ ${budget.limitAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
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
      
      // 6. O "Ouvinte" Duplo
      // Usamos um StreamBuilder para ouvir os Orçamentos
      body: StreamBuilder<List<BudgetModel>>(
        stream: _firestoreService.getBudgetsStream(_selectedDate.month, _selectedDate.year),
        builder: (context, budgetSnapshot) {
          
          // Usamos um *segundo* StreamBuilder aninhado para ouvir as Transações
          return StreamBuilder<List<TransactionModel>>(
            stream: _firestoreService.getTransactionsStream(),
            builder: (context, transactionSnapshot) {

              // Se qualquer um dos streams estiver carregando
              if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                  transactionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Se qualquer um der erro
              if (budgetSnapshot.hasError) return Center(child: Text('Erro ao carregar orçamentos: ${budgetSnapshot.error}'));
              if (transactionSnapshot.hasError) return Center(child: Text('Erro ao carregar transações: ${transactionSnapshot.error}'));

              // Se ambos tiverem dados (ou lista vazia)
              final budgets = budgetSnapshot.data ?? [];
              final transactions = transactionSnapshot.data ?? [];

              // Chama a função que constrói a UI com os dois conjuntos de dados
              return _buildBudgetsView(budgets, transactions);
            },
          );
        },
      ),
    );
  }
}