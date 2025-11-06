// lib/screens/add_transaction_screen.dart
import 'package:app_financas/models/recurring_transaction_model.dart'; 
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialDescription;
  final double? initialAmount;
  final TransactionModel? transactionToEdit;
  
  const AddTransactionScreen({
    super.key, 
    this.initialDescription, 
    this.initialAmount,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  final _dayController = TextEditingController();
  
  bool _isRecurring = false; 
  final _firestoreService = FirestoreService();

  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];
  final List<String> _incomeCategories = ['Salário', 'Renda Extra'];

  String _selectedType = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now(); 
  bool _isLoading = false;
  bool _isEditing = false;

  // --- MUDANÇA 1: Novas variáveis de estado ---
  final List<String> _paymentMethods = [
    'Dinheiro', 
    'Pix', 
    'Cartão de Débito', 
    'Cartão de Crédito',
    'Transferência Bancária'
  ];
  String? _selectedPaymentMethod;
  // --- FIM MUDANÇA 1 ---

  @override
  void initState() {
    super.initState();
    
    _isEditing = widget.transactionToEdit != null;

    _descriptionController = TextEditingController(text: widget.transactionToEdit?.description ?? widget.initialDescription);
    _amountController = TextEditingController(
      text: (widget.transactionToEdit?.amount ?? widget.initialAmount)?.toStringAsFixed(2)
    );

    if (_isEditing) {
      _selectedType = widget.transactionToEdit!.type;
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = widget.transactionToEdit!.date;
      // --- MUDANÇA 2: Pré-preencher o método de pagamento ---
      _selectedPaymentMethod = widget.transactionToEdit!.paymentMethod;
      // --- FIM MUDANÇA 2 ---
      _isRecurring = false;
    } else if (widget.initialAmount != null) {
      // Veio da lista de compras
      _selectedType = 'expense';
    }
  }

  // (A função _showPostNowDialog não muda)
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
                ? const Column( mainAxisSize: MainAxisSize.min, children: [ CircularProgressIndicator(), SizedBox(height: 16), Text('Lançando...'), ],)
                : Text('Deseja lançar "${newRecurringWithId.description}" para o mês atual?'),
              actions: isPosting ? [] : [
                TextButton(
                  child: const Text('Não'),
                  onPressed: () { Navigator.pop(dialogContext); Navigator.pop(addTransactionContext); },
                ),
                ElevatedButton(
                  child: const Text('Sim, Lançar'),
                  onPressed: () async {
                    setDialogState(() { isPosting = true; });
                    try {
                      await _firestoreService.postRecurringTransactions([newRecurringWithId], DateTime.now());
                      if (mounted) { Navigator.pop(dialogContext); Navigator.pop(addTransactionContext); }
                    } catch (e) {
                      setDialogState(() { isPosting = false; });
                      if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao lançar: $e'), backgroundColor: Colors.red), ); }
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

  // --- MUDANÇA 3: Atualizar a lógica de salvamento ---
  Future<void> _handleUpdate() async {
    final updatedTransaction = TransactionModel(
      id: widget.transactionToEdit!.id,
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      type: _selectedType,
      category: _selectedCategory!,
      date: _selectedDate,
      // Passa o método de pagamento (ou null se for receita)
      paymentMethod: _selectedType == 'expense' ? _selectedPaymentMethod : null,
    );
    
    await _firestoreService.updateTransaction(widget.transactionToEdit!.id!, updatedTransaction);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação atualizada!'), backgroundColor: Colors.green),
      );
    }
  }

  // (_handleCreateRecurring não muda, pois não salva paymentMethod)
  Future<void> _handleCreateRecurring() async {
    final day = int.tryParse(_dayController.text);
    if (day == null || day < 1 || day > 31) throw Exception("Dia do mês inválido.");
    
    final newRecurring = RecurringTransactionModel(
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
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
  }

  Future<void> _handleCreateNormal() async {
    final newTransaction = TransactionModel(
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      type: _selectedType,
      category: _selectedCategory!,
      date: _selectedDate,
      // Passa o método de pagamento (ou null se for receita)
      paymentMethod: _selectedType == 'expense' ? _selectedPaymentMethod : null,
    );
    
    await _firestoreService.addTransaction(newTransaction);
    
    if (mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação salva!'), backgroundColor: Colors.green),
      );
    }
  }

  // (_saveTransaction não muda)
  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _selectedCategory == null ||
        (_isRecurring && _dayController.text.isEmpty) ||
        // Validação extra: se for despesa (não recorrente/editando), precisa de método de pagamento?
        // Vamos deixar opcional por enquanto.
        // (_selectedType == 'expense' && !_isRecurring && !_isEditing && _selectedPaymentMethod == null)
        false
        ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (_isEditing) {
        await _handleUpdate();
      } else if (_isRecurring) {
        await _handleCreateRecurring();
      } else {
        await _handleCreateNormal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }
  // --- FIM MUDANÇA 3 ---
  
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
        title: Text(_isEditing ? 'Editar Transação' : 'Adicionar Transação'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (SegmentedButton de Tipo não muda)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Despesa'), icon: Icon(Icons.arrow_downward)),
                    ButtonSegment(value: 'income', label: Text('Receita'), icon: Icon(Icons.arrow_upward)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: _isEditing ? null : (newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // (TextField de Descrição não muda)
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // (TextField de Valor não muda)
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // (Dropdown de Categoria não muda)
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
                
                // --- MUDANÇA 4: Adicionar o Dropdown de Método de Pagamento ---
                // Só mostra se for 'Despesa' E não for 'Recorrente'
                if (_selectedType == 'expense' && !_isRecurring) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    hint: const Text('Método de Pagamento (Opcional)'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPaymentMethod = newValue;
                      });
                    },
                  ),
                ],
                // --- FIM MUDANÇA 4 ---

                const SizedBox(height: 16),
                // (Switch de Recorrente não muda)
                SwitchListTile(
                  title: const Text('É uma transação recorrente?'),
                  value: _isRecurring,
                  onChanged: _isEditing ? null : (bool newValue) {
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
                // (Botão de Salvar não muda)
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(_isEditing ? 'Atualizar Transação' : 'Salvar Transação'),
                ),
              ],
            ),
      ),
    );
  }
}