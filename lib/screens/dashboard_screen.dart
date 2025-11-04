// lib/screens/dashboard_screen.dart
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:app_financas/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
// 1. IMPORTAR O NOVO PACOTE DE GRÁFICO
import 'package:pie_chart/pie_chart.dart'; 
// (no topo do dashboard_screen.dart)
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 1. ADICIONE ESTA LISTA DE CORES
final List<Color> _colorList = const [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.purple,
  Colors.brown,
  Colors.teal,
];
// 3. ADICIONE ESTA NOVA FUNÇÃO (O POP-UP)
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
              // Lista de transações daquela categoria
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

// 4. ADICIONE ESTA NOVA FUNÇÃO (A LEGENDA CLICÁVEL)
Widget _buildClickableLegend(Map<String, double> dataMap, List<TransactionModel> monthExpenses) {
  if (dataMap.isEmpty || dataMap.keys.first == "Nenhuma despesa") {
    return const SizedBox.shrink(); // Não mostra nada se não houver gastos
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
        // Constrói a lista da legenda
        ...dataMap.entries.toList().asMap().entries.map((entry) {
          int index = entry.key;
          String category = entry.value.key;
          double value = entry.value.value;
          double percentage = (value / totalExpenses) * 100;

          // Pega as transações SÓ dessa categoria para o pop-up
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
                color: _colorList[index % _colorList.length], // Pega a cor
              ),
              title: Text(category),
              trailing: Text(
                'R\$ ${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                // CHAMA O POP-UP
                _showCategoryDetailsDialog(category, value, categoryExpenses);
              },
            ),
          );
        }).toList(),
      ],
    ),
  );
}
  // Função para navegar (sem mudanças)
  void _navigateToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
  }

  // --- WIDGETS DE UI (NOVOS) ---

  // 2. WIDGET PARA O CARD DE SALDO
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
                Flexible( // Usamos Flexible para permitir que o texto se ajuste
                  child: Text(
                    'Receitas: R\$ ${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                    overflow: TextOverflow.ellipsis, // Corta o texto com "..." se não couber
                  ),
                ),
                const SizedBox(width: 8), // Pequeno espaço entre os textos
                Flexible( // Usamos Flexible para permitir que o texto se ajuste
                  child: Text(
                    'Despesas: R\$ ${totalExpense.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    overflow: TextOverflow.ellipsis, // Corta o texto com "..." se não couber
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. WIDGET PARA O GRÁFICO DE PIZZA
  // 2. SUBSTITUA A FUNÇÃO _buildPieChartCard
Widget _buildPieChartCard(Map<String, double> dataMap) {
  // Se não houver dados, não mostra o card do gráfico
  if (dataMap.isEmpty || dataMap.keys.first == "Nenhuma despesa") {
    return const SizedBox.shrink(); // Retorna um widget vazio
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

            // --- MUDANÇAS AQUI ---
            colorList: _colorList, // Usa nossa lista de cores
            legendOptions: const LegendOptions(
              showLegends: false, // 1. Desliga a legenda padrão
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: true,
              showChartValues: true,
              showChartValuesInPercentage: true, // 2. Mantém a porcentagem
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
            // --- FIM DAS MUDANÇAS ---
          ),
        ],
      ),
    ),
  );
}

  // 4. WIDGET PARA A LISTA DE TRANSAÇÕES (O que já tínhamos)
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
      
      // --- ESTAS SÃO AS LINHAS DA CORREÇÃO ---
      shrinkWrap: true, // Diz ao ListView para "encolher" ao tamanho dos filhos
      physics: const NeverScrollableScrollPhysics(), // Desliga o scroll do ListView
      // --- FIM DA CORREÇÃO ---
      
      itemBuilder: (context, index) {
        final transaction = monthTransactions[index];
        final isExpense = transaction.type == 'expense';
        
        // Retorna o Dismissible (arrastar para excluir)
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
          // O ListTile com a data
          child: ListTile(
            leading: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: isExpense ? Colors.red : Colors.green,
            ),
            title: Text(transaction.description),
            subtitle: Text(transaction.category),
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
        );
      },
    );
  }

 // 5. SUBSTITUA O MÉTODO 'build' PRINCIPAL
@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToAddScreen,
      child: const Icon(Icons.add),
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
        final now = DateTime.now();

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

        // Processa os dados do gráfico (DataMap)
        Map<String, double> dataMap = {};
        if (monthExpenses.isEmpty) {
          dataMap["Nenhuma despesa"] = 1.0;
        } else {
          for (var expense in monthExpenses) {
            dataMap[expense.category] = 
                (dataMap[expense.category] ?? 0) + expense.amount;
          }
        }

        // CONSTRÓI A TELA EM UMA LISTA ROLÁVEL
        return SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD DE SALDO
              _buildBalanceCard(totalIncome, totalExpense),

              // CARD DO GRÁFICO (agora sem legenda)
              _buildPieChartCard(dataMap),

              // A NOVA LEGENDA CLICÁVEL
              _buildClickableLegend(dataMap, monthExpenses),

              // TÍTULO DA LISTA
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // Ajuste no padding
                child: Text(
                  'Transações do Mês',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // LISTA DE TRANSAÇÕES
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