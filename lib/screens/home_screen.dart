// lib/screens/home_screen.dart
import 'package:app_financas/screens/dashboard_screen.dart'; 
import 'package:app_financas/screens/shopping_lists_screen.dart';
import 'package:app_financas/screens/manage_recurring_screen.dart';
import 'package:app_financas/screens/planning_screen.dart';
import 'package:app_financas/services/firestore_service.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import '../services/auth_service.dart';
import 'package:app_financas/models/recurring_transaction_model.dart';
import 'package:app_financas/models/transaction_model.dart';

// Importar os novos pacotes
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState(); 
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService(); 
  final User? currentUser = FirebaseAuth.instance.currentUser; 
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();

  static const List<String> _titles = <String>[ 
    'Início',
    'Listas de Compras',
    'Planejamento',
  ];

  // --- Chaves para o tutorial ---
  final GlobalKey _keySeletorMes = GlobalKey(); 
  final GlobalKey _keyBotaoRecorrentes = GlobalKey();
  final GlobalKey _keyFabDashboard = GlobalKey();
  final GlobalKey _keyAbaListas = GlobalKey();
  final GlobalKey _keyAbaPlaneamento = GlobalKey();
  
  bool _tutorialCheckStarted = false; 

  @override
  void initState() { 
    super.initState();
    Future.delayed(const Duration(seconds: 1), _checkRecurringTransactions);
    // A chamada do tutorial foi movida do initState 
  }

  // Função do Tutorial
  Future<void> _checkIfFirstTime(BuildContext context) async {
    if (_tutorialCheckStarted) return;
    setState(() { 
      _tutorialCheckStarted = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tutorialVisto = prefs.getBool('tutorialVisto') ?? false; 

    if (!tutorialVisto && mounted) {
      // Inicia o showcase
      ShowCaseWidget.of(context).startShowCase([
        _keySeletorMes,
        _keyBotaoRecorrentes,
        _keyFabDashboard,
        _keyAbaListas,
        _keyAbaPlaneamento,
      ]);
      await prefs.setBool('tutorialVisto', true); 
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    }); 
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    }); 
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    }); 
  }
  
  // (Funções de recorrência)
  Future<void> _checkRecurringTransactions() async {
    final now = DateTime.now();
    final allRecurringModels = 
        await _firestoreService.getRecurringTransactionsStream().first;
    final List<RecurringTransactionModel> dueTransactions = [];
    for (var model in allRecurringModels) {
      bool alreadyPosted = (model.lastPostedYear == now.year && 
                            model.lastPostedMonth == now.month);
      if (!alreadyPosted) { 
        dueTransactions.add(model); 
    }
    if (dueTransactions.isNotEmpty && mounted) {
      _showPostingDialog(dueTransactions, now); 
    }
    }
  }
  void _showPostingDialog(List<RecurringTransactionModel> dueTransactions, DateTime now) {
    bool isLoading = false;
    showDialog( 
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) { 
            return AlertDialog(
              title: const Text('Recorrentes Pendentes'),
              content: isLoading 
                ? const Column( mainAxisSize: MainAxisSize.min, children: [ CircularProgressIndicator(), SizedBox(height: 16), Text('Lançando transações...'), ], ) 
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Encontramos ${dueTransactions.length} transações pendentes para este mês:'), 
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.maxFinite,
                        height: 150, 
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
              actions: isLoading ? [] : [ 
                TextButton(
                  child: const Text('Depois'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Lançar'),
                  onPressed: () async {
                    setDialogState(() { isLoading = true; });
                    try {
                      await _firestoreService.postRecurringTransactions(dueTransactions, now); 
                      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Transações recorrentes lançadas!'), backgroundColor: Colors.green, ), ); }
                    } catch (e) {
                      if (mounted) { setDialogState(() { isLoading = false; }); ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao lançar: $e'), backgroundColor: Colors.red, ), ); } 
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
    final List<Widget> _widgetOptions = <Widget>[
      DashboardScreen(
        selectedDate: _selectedDate,
        fabKey: _keyFabDashboard,
      ),
      ShoppingListsScreen(),
      PlanningScreen(selectedDate: _selectedDate),
    ];

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>( 
      stream: _firestoreService.getUserDataStream(),
      builder: (context, snapshot) {
        
        String userName = '';
        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          var data = snapshot.data!.data(); 
          if (data != null && data.containsKey('name')) {
            userName = data['name'];
          } 
        }
        
        return ShowCaseWidget(
          builder: (context) { // --- Este é o 'context' correto! ---
            
            // --- A CORREÇÃO ESTÁ AQUI ---
            // Diz ao Flutter para chamar a função _checkIfFirstTime
            // *depois* que este ecrã (frame) estiver construído.
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context));
            // --- FIM DA CORREÇÃO ---
            
            return Scaffold( 
              appBar: AppBar(
                title: Text(
                  _selectedIndex == 0 
                      ? (userName.isNotEmpty ? 'Bem-vindo, $userName!' : 'Início') 
                      : _titles.elementAt(_selectedIndex)
                ),
                
                bottom: (_selectedIndex == 0 || _selectedIndex == 2) 
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(48.0), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        
                        child: Showcase( 
                          key: _keySeletorMes,
                          title: 'Mude o Mês',
                          description: 'Navegue pelos meses para ver o seu histórico.', 
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface, 
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2), ), ],
                            ), 
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                              child: Row( 
                                mainAxisAlignment: MainAxisAlignment.center, 
                                children: [
                                  IconButton( 
                                    icon: const Icon(Icons.arrow_left),
                                    color: Theme.of(context).colorScheme.onSurface,
                                    onPressed: _previousMonth, 
                                  ),
                                  const SizedBox(width: 4), 
                                  Text( 
                                    DateFormat('MMMM/yyyy', 'pt_BR').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 16, 
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold 
                                    ),
                                  ),
                                  const SizedBox(width: 4), 
                                  IconButton(
                                    icon: const Icon(Icons.arrow_right),
                                    color: Theme.of(context).colorScheme.onSurface, 
                                    onPressed: _nextMonth,
                                  ),
                                ], 
                              ),
                            ),
                          ), 
                        ),
                      ),
                    )
                  : null, 
                
                actions: [
                  Showcase(
                    key: _keyBotaoRecorrentes,
                    title: 'Transações Recorrentes',
                    description: 'Clique aqui para gerir as suas despesas e receitas mensais.', 
                    child: IconButton(
                      icon: const Icon(Icons.autorenew),
                      tooltip: 'Gerir Recorrentes',
                      onPressed: () { 
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageRecurringScreen()),
                        ); 
                      }, 
                    ),
                  ),
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
              
              bottomNavigationBar: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  const BottomNavigationBarItem( 
                    icon: Icon(Icons.dashboard),
                    label: 'Início',
                  ),
                  BottomNavigationBarItem(
                    icon: Showcase( 
                      key: _keyAbaListas,
                      title: 'Listas de Compras',
                      description: 'Aceda aqui às suas listas de compras.',
                      child: const Icon(Icons.list_alt), 
                    ),
                    label: 'Listas',
                  ),
                  BottomNavigationBarItem(
                    icon: Showcase( 
                      key: _keyAbaPlaneamento,
                      title: 'Planeamento',
                      description: 'Crie e acompanhe os seus orçamentos mensais aqui.',
                      child: const Icon(Icons.pie_chart), 
                    ),
                    label: 'Planejamento',
                  ),
                ],
                currentIndex: _selectedIndex, 
                onTap: _onItemTapped, 
              ),
            );
          }, 
        );
      },
    );
  }
}