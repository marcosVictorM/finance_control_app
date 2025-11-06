// lib/screens/dashboard_screen.dart
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:app_financas/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe o 'intl'
import 'package:pie_chart/pie_chart.dart'; 
import 'package:showcaseview/showcaseview.dart';

class DashboardScreen extends StatefulWidget {
  // --- MUDANÇA 1: Receber a data selecionada ---
  final DateTime selectedDate;
  final GlobalKey fabKey;

  const DashboardScreen({
    super.key, 
    required this.selectedDate, // Agora é obrigatório
    required this.fabKey,
  });
  // --- FIM MUDANÇA 1 ---

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Lista de cores (como já tínhamos)
  final List<Color> _colorList = const [
    Colors.red, Colors.blue, Colors.green, Colors.yellow,
    Colors.orange, Colors.purple, Colors.brown, Colors.teal,
  ];

  // (Função _navigateToAddScreen não muda)
  void _navigateToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
  }

  // (Função _buildBalanceCard não muda)
  Widget _buildBalanceCard(double totalIncome, double totalExpense) {
    final double balance = totalIncome - totalExpense;
    final bool isPositive = balance >= 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo do Mês',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${isPositive ? '+' : ''} R\$ ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Receitas: R\$ ${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Despesas: R\$ ${totalExpense.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (Função _buildPieChartCard não muda)
  Widget _buildPieChartCard(Map<String, double> dataMap) {
    if (dataMap.isEmpty || dataMap.keys.first == "Nenhuma despesa") {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por Categoria (Mês)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 3.2,
              colorList: _colorList,
              legendOptions: const LegendOptions(showLegends: false),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: true,
                showChartValues: true,
                showChartValuesInPercentage: true,
                showChartValuesOutside: false,
                decimalPlaces: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // (Função _showCategoryDetailsDialog não muda)
  void _showCategoryDetailsDialog(String category, double totalValue, List<TransactionModel> categoryExpenses) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Gasto: R\$ ${totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                const Text(
                  'Transações:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categoryExpenses.length,
                    itemBuilder: (context, index) {
                      final transaction = categoryExpenses[index];
                      return ListTile(
                        title: Text(transaction.description),
                        trailing: Text(
                          '- R\$ ${transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        subtitle: Text(DateFormat('dd/MM').format(transaction.date)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
  
  // (Função _buildClickableLegend não muda)
  Widget _buildClickableLegend(Map<String, double> dataMap, List<TransactionModel> monthExpenses) {
    if (dataMap.isEmpty || dataMap.keys.first == "Nenhuma despesa") {
      return const SizedBox.shrink();
    }
    final double totalExpenses = dataMap.values.fold(0.0, (sum, item) => sum + item);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo por Categoria',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...dataMap.entries.toList().asMap().entries.map((entry) {
            int index = entry.key;
            String category = entry.value.key;
            double value = entry.value.value;
            double percentage = (value / totalExpenses) * 100;
            final categoryExpenses = monthExpenses
                .where((t) => t.category == category)
                .toList();
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  color: _colorList[index % _colorList.length],
                ),
                title: Text(category),
                trailing: Text(
                  'R\$ ${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  _showCategoryDetailsDialog(category, value, categoryExpenses);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  // (Função _buildTransactionList não muda)
  Widget _buildTransactionList(List<TransactionModel> monthTransactions) {
    if (monthTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhuma transação este mês. Adicione uma!'),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: monthTransactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final transaction = monthTransactions[index];
        final isExpense = transaction.type == 'expense';
        
        // --- INÍCIO DA MUDANÇA ---
        
        // 1. Criar o texto do subtítulo dinamicamente
        String subtitleText = transaction.category;
        if (transaction.paymentMethod != null && transaction.paymentMethod!.isNotEmpty) {
          // Ex: "Alimentação • Cartão de Crédito"
          subtitleText = '$subtitleText • ${transaction.paymentMethod}'; 
        }
        
        // --- FIM DA MUDANÇA ---
        
        return Dismissible(
          key: Key(transaction.id!), 
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _firestoreService.deleteTransaction(transaction.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${transaction.description}" removida.'),
                backgroundColor: Colors.red,
              ),
            );
          },
          
          child: GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    transactionToEdit: transaction,
                  ),
                ),
              );
            },
            
            child: ListTile(
              leading: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? Colors.red : Colors.green,
              ),
              title: Text(transaction.description),
              
              // --- INÍCIO DA MUDANÇA ---
              // 2. Usar o novo texto do subtítulo
              subtitle: Text(subtitleText), 
              // --- FIM DA MUDANÇA ---
              
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'} R\$ ${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM').format(transaction.date),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showBalanceReportDialog(
    List<TransactionModel> monthTransactions, 
    double totalIncome, 
    double totalExpense
  ) {
    // 1. Separar as listas
    final incomes = monthTransactions.where((t) => t.type == 'income').toList();
    final expenses = monthTransactions.where((t) => t.type == 'expense').toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Relatório do Mês'),
          // O conteúdo precisa ser "SingleChildScrollView" para o caso de muitas transações
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite, // Para o diálogo usar a largura máxima
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- SEÇÃO DE RECEITAS ---
                  Text(
                    'Receitas (Total: R\$ ${totalIncome.toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lista de Receitas
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: incomes.length,
                    itemBuilder: (context, index) {
                      final item = incomes[index];
                      return ListTile(
                        dense: true, // Deixa o item da lista mais "apertado"
                        title: Text(item.description),
                        trailing: Text('+ R\$ ${item.amount.toStringAsFixed(2)}'),
                      );
                    },
                  ),
                  // Se não houver receitas, mostra uma mensagem
                  if (incomes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Nenhuma receita este mês.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),

                  const Divider(height: 24, thickness: 1),

                  // --- SEÇÃO DE DESPESAS ---
                  Text(
                    'Despesas (Total: R\$ ${totalExpense.toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lista de Despesas
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      return ListTile(
                        dense: true,
                        title: Text(item.description),
                        subtitle: Text(item.category),
                        trailing: Text('- R\$ ${item.amount.toStringAsFixed(2)}'),
                      );
                    },
                  ),
                  // Se não houver despesas, mostra uma mensagem
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Nenhuma despesa este mês.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
  
  // --- O MÉTODO BUILD PRINCIPAL (ATUALIZADO) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- INÍCIO DA MUDANÇA ---
      floatingActionButton: Showcase(
        key: widget.fabKey, // Passa a chave aqui
        title: 'Adicionar Transação',
        description: 'Clique aqui para adicionar uma nova receita ou despesa.',
        child: FloatingActionButton(
          onPressed: _navigateToAddScreen,
          child: const Icon(Icons.add),
        ),
      ),
      
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma transação encontrada. Adicione uma!'));
          }

          final allTransactions = snapshot.data!;
          // --- MUDANÇA 2: Usa a data recebida em vez de DateTime.now() ---
          final now = widget.selectedDate;

          final List<TransactionModel> monthTransactions = allTransactions.where((t) {
            return t.date.month == now.month && t.date.year == now.year;
          }).toList();
          
          final double totalIncome = monthTransactions
              .where((t) => t.type == 'income')
              .fold(0.0, (sum, t) => sum + t.amount);
              
          final double totalExpense = monthTransactions
              .where((t) => t.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.amount);
          
          final List<TransactionModel> monthExpenses = monthTransactions
              .where((t) => t.type == 'expense')
              .toList();

          Map<String, double> dataMap = {};
          if (monthExpenses.isEmpty) {
            dataMap["Nenhuma despesa"] = 1.0;
          } else {
            for (var expense in monthExpenses) {
              dataMap[expense.category] = 
                  (dataMap[expense.category] ?? 0) + expense.amount;
            }
          }

          return SingleChildScrollView( 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // --- INÍCIO DA MUDANÇA ---
        // 1. Adicionamos um GestureDetector para tornar o Card clicável
        GestureDetector(
          onTap: () {
            // 2. Ao tocar, chamamos a nova função de relatório
            _showBalanceReportDialog(
              monthTransactions, 
              totalIncome, 
              totalExpense
            );
          },
          // 3. O Card de Saldo agora é o "filho" (child) do GestureDetector
          child: _buildBalanceCard(totalIncome, totalExpense), 
        ),
        // --- FIM DA MUDANÇA ---
        
        _buildPieChartCard(dataMap), // O resto do código continua igual
        _buildClickableLegend(dataMap, monthExpenses),
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Transações do Mês',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTransactionList(monthTransactions),
        const SizedBox(height: 80), 
      ],
    ),
  );
        },
      ),
    );
  }
}