// lib/screens/dashboard_screen.dart
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:app_financas/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
// 1. IMPORTAR O NOVO PACOTE DE GRÁFICO
import 'package:pie_chart/pie_chart.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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
                Text(
                  'Receitas: R\$ ${totalIncome.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                ),
                Text(
                  'Despesas: R\$ ${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. WIDGET PARA O GRÁFICO DE PIZZA
  Widget _buildPieChartCard(List<TransactionModel> monthExpenses) {
    // Processa os dados: Agrupa despesas por categoria
    Map<String, double> dataMap = {};
    if (monthExpenses.isEmpty) {
      dataMap["Nenhuma despesa"] = 1.0; // Estado "vazio" para o gráfico
    } else {
      for (var expense in monthExpenses) {
        dataMap[expense.category] = 
            (dataMap[expense.category] ?? 0) + expense.amount;
      }
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
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
                legendTextStyle: TextStyle(fontWeight: FontWeight.w500),
              ),
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
      shrinkWrap: true, // Para o ListView caber dentro do Column
      physics: const NeverScrollableScrollPhysics(), // Para o ListView não rolar (a tela inteira rola)
      itemBuilder: (context, index) {
        final transaction = monthTransactions[index];
        final isExpense = transaction.type == 'expense';
        return ListTile(
          leading: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red : Colors.green,
          ),
          title: Text(transaction.description),
          subtitle: Text(transaction.category),
          trailing: Text(
            '${isExpense ? '-' : '+'} R\$ ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }


  // --- O MÉTODO BUILD PRINCIPAL (ATUALIZADO) ---
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
            // Se não houver transações NENHUMA
            return Center(child: Text('Nenhuma transação encontrada. Adicione uma!'));
          }

          final allTransactions = snapshot.data!;
          final now = DateTime.now();

          // 5. FILTRA TRANSAÇÕES PARA O MÊS ATUAL
          final List<TransactionModel> monthTransactions = allTransactions.where((t) {
            return t.date.month == now.month && t.date.year == now.year;
          }).toList();
          
          // 6. CALCULA OS TOTAIS DO MÊS
          final double totalIncome = monthTransactions
              .where((t) => t.type == 'income')
              .fold(0.0, (sum, t) => sum + t.amount);
              
          final double totalExpense = monthTransactions
              .where((t) => t.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.amount);
          
          final List<TransactionModel> monthExpenses = monthTransactions
              .where((t) => t.type == 'expense')
              .toList();


          // 7. CONSTRÓI A TELA EM UMA LISTA ROLÁVEL
          return SingleChildScrollView( // Permite a tela rolar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD DE SALDO
                _buildBalanceCard(totalIncome, totalExpense),
                
                // CARD DO GRÁFICO
                _buildPieChartCard(monthExpenses),
                
                // TÍTULO DA LISTA
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Transações do Mês',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // LISTA DE TRANSAÇÕES
                _buildTransactionList(monthTransactions),
                
                const SizedBox(height: 80), // Espaço para o FAB não cobrir o último item
              ],
            ),
          );
        },
      ),
    );
  }
}