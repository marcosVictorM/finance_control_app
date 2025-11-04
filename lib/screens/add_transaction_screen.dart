// lib/screens/add_transaction_screen.dart
import 'package:app_financas/models/recurring_transaction_model.dart'; 
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddTransactionScreen extends StatefulWidget {
  // --- MUDANÇA 1: Adicionar campos para pré-preenchimento ---
  final String? initialDescription;
  final double? initialAmount;
  
  // O construtor agora aceita os valores iniciais (opcionais)
  const AddTransactionScreen({
    super.key, 
    this.initialDescription, 
    this.initialAmount,
  });
  // --- FIM MUDANÇA 1 ---

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Controladores agora são inicializados no initState
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  final _dayController = TextEditingController();
  
  bool _isRecurring = false; 
  final _firestoreService = FirestoreService();

  // (Listas de categorias não mudam)
  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];
  final List<String> _incomeCategories = ['Salário', 'Renda Extra'];

  String _selectedType = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now(); 
  bool _isLoading = false;

  // --- MUDANÇA 2: Inicializar os controladores ---
  @override
  void initState() {
    super.initState();
    // Pré-preenche os campos se os valores foram passados
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _amountController = TextEditingController(
      text: widget.initialAmount != null 
            ? widget.initialAmount!.toStringAsFixed(2) 
            : null
    );
  }
  // --- FIM MUDANÇA 2 ---

  // (O resto do arquivo: _showPostNowDialog, _saveTransaction, build...
  // ... não muda nada. Copie e cole o resto do seu arquivo aqui)
  
  // (Cole aqui as funções _showPostNowDialog e _saveTransaction que já funcionam)
  // ...
  // ... (vou colar por segurança para garantir que esteja completo) ...

  void _showPostNowDialog(RecurringTransactionModel newRecurringWithId, BuildContext addTransactionContext) {
    bool isPosting = false; 
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lançar Transação?'),
              content: isPosting 
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Lançando...'),
                    ],
                  )
                : Text('Deseja lançar "${newRecurringWithId.description}" para o mês atual?'),
              actions: isPosting ? [] : [
                TextButton(
                  child: const Text('Não'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(addTransactionContext);
                  },
                ),
                ElevatedButton(
                  child: const Text('Sim, Lançar'),
                  onPressed: () async {
                    setDialogState(() { isPosting = true; });

                    try {
                      await _firestoreService.postRecurringTransactions([newRecurringWithId], DateTime.now());
                      
                      if (mounted) {
                         Navigator.pop(dialogContext);
                         Navigator.pop(addTransactionContext);
                      }
                    } catch (e) {
                      setDialogState(() { isPosting = false; });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao lançar: $e'), backgroundColor: Colors.red),
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

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _selectedCategory == null ||
        (_isRecurring && _dayController.text.isEmpty)
        ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final description = _descriptionController.text;
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      if (_isRecurring) {
        final day = int.tryParse(_dayController.text);
        if (day == null || day < 1 || day > 31) {
           throw Exception("Dia do mês inválido.");
        }

        final newRecurring = RecurringTransactionModel(
          description: description,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory!,
          dayOfMonth: day,
        );

        final String newId = await _firestoreService.createRecurringTransaction(newRecurring);

        final RecurringTransactionModel newRecurringWithId = RecurringTransactionModel(
          id: newId, 
          description: newRecurring.description,
          amount: newRecurring.amount,
          type: newRecurring.type,
          category: newRecurring.category,
          dayOfMonth: newRecurring.dayOfMonth,
        );
        
        if (mounted) {
          _showPostNowDialog(newRecurringWithId, context); 
        }

      } else {
        final newTransaction = TransactionModel(
          description: description,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory!,
          date: _selectedDate, 
        );
        await _firestoreService.addTransaction(newTransaction);
        
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transação salva!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentCategories = _selectedType == 'expense' 
        ? _expenseCategories 
        : _incomeCategories;
    
    if (_selectedCategory != null && !currentCategories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Transação'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Despesa'), icon: Icon(Icons.arrow_downward)),
                    ButtonSegment(value: 'income', label: Text('Receita'), icon: Icon(Icons.arrow_upward)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _descriptionController, // Agora inicializado no initState
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController, // Agora inicializado no initState
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Selecione uma categoria'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: currentCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('É uma transação recorrente?'),
                  value: _isRecurring,
                  onChanged: (bool newValue) {
                    setState(() {
                      _isRecurring = newValue;
                    });
                  },
                  secondary: const Icon(Icons.autorenew),
                ),
                if (_isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextField(
                      controller: _dayController,
                      decoration: const InputDecoration(
                        labelText: 'Dia do Mês (1-31)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [ FilteringTextInputFormatter.digitsOnly ],
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Salvar Transação'),
                ),
              ],
            ),
      ),
    );
  }
}