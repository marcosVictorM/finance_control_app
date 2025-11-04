// lib/screens/home_screen.dart
import 'package:app_financas/screens/dashboard_screen.dart'; 
import 'package:app_financas/screens/shopping_lists_screen.dart';
import 'package:app_financas/screens/manage_recurring_screen.dart';
import 'package:app_financas/screens/planning_screen.dart';
import 'package:app_financas/services/firestore_service.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../services/auth_service.dart';
import 'package:app_financas/models/recurring_transaction_model.dart';
// import 'package:app_financas/models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 0;

  // 2. ADICIONAR A TELA À LISTA
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ShoppingListsScreen(),
    PlanningScreen(), // <-- Adicionada
  ];

  // 4. ATUALIZAR OS TÍTULOS
  static const List<String> _titles = <String>[
    'Dashboard',
    'Listas de Compras',
    'Planejamento', // <-- Adicionado
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
// 1. Adiciona o FirestoreService aqui
  final FirestoreService _firestoreService = FirestoreService();

  // 2. Adiciona o initState
  @override
  void initState() {
    super.initState();
    // Atraso de 1 segundo para garantir que o usuário está logado
    // e para não sobrecarregar a UI imediatamente.
    Future.delayed(const Duration(seconds: 1), _checkRecurringTransactions);
  }

  // 3. NOVA FUNÇÃO: Lógica de Detecção
  Future<void> _checkRecurringTransactions() async {
    final now = DateTime.now();
    
    // Pega os "moldes" recorrentes UMA VEZ
    final allRecurringModels = 
        await _firestoreService.getRecurringTransactionsStream().first;
    
    // Filtra para encontrar os que estão pendentes
    final List<RecurringTransactionModel> dueTransactions = [];
    for (var model in allRecurringModels) {
      // Verifica se já foi lançado neste mês/ano
      bool alreadyPosted = (model.lastPostedYear == now.year && 
                            model.lastPostedMonth == now.month);
      
      if (!alreadyPosted) {
        dueTransactions.add(model);
      }
    }

    // Se houver transações pendentes, mostra o pop-up
    if (dueTransactions.isNotEmpty && mounted) {
      _showPostingDialog(dueTransactions, now);
    }
  }

  // 4. NOVA FUNÇÃO: O Pop-up de Confirmação
  void _showPostingDialog(List<RecurringTransactionModel> dueTransactions, DateTime now) {
    bool isLoading = false; // Estado de loading do pop-up

    showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar clicando fora
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Recorrentes Pendentes'),
              content: isLoading 
                ? const Column( // Mostra o loading
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Lançando transações...'),
                    ],
                  )
                : Column( // Mostra a lista
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Encontramos ${dueTransactions.length} transações pendentes para este mês:'),
                      const SizedBox(height: 16),
                      // Container com scroll para a lista
                      SizedBox(
                        width: double.maxFinite,
                        height: 150, // Limita a altura
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: dueTransactions.length,
                          itemBuilder: (context, index) {
                            final item = dueTransactions[index];
                            final isExpense = item.type == 'expense';
                            return Text(
                              '• ${item.description} (R\$ ${item.amount.toStringAsFixed(2)})',
                              style: TextStyle(color: isExpense ? Colors.red : Colors.green),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Deseja lançá-las agora?'),
                    ],
                  ),
              actions: isLoading ? [] : [ // Esconde botões se estiver carregando
                TextButton(
                  child: const Text('Depois'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Lançar'),
                  onPressed: () async {
                    setDialogState(() { isLoading = true; }); // Inicia o loading
                    
                    try {
                      // Chama nosso novo método de serviço
                      await _firestoreService.postRecurringTransactions(dueTransactions, now);
                      
                      if (mounted) {
                        Navigator.pop(context); // Fecha o pop-up
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transações recorrentes lançadas!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Trata o erro
                      if (mounted) {
                        setDialogState(() { isLoading = false; });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao lançar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
      }
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
        title: Text(_titles.elementAt(_selectedIndex)),
        actions: [
          
          // 2. ADICIONAR O BOTÃO AQUI
          IconButton(
            icon: const Icon(Icons.autorenew), // Ícone de "recorrente"
            tooltip: 'Gerir Recorrentes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageRecurringScreen()),
              );
            },
          ),
          
          // Botão de Sair (Logout)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.signOut();
            },
          )
        ],
      ),
      
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // 3. ADICIONAR A NOVA ABA
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Listas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart), // <-- Nova aba
            label: 'Planejamento',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}