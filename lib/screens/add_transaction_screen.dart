// lib/screens/add_transaction_screen.dart
import 'package:app_financas/models/transaction_model.dart';
import 'package:app_financas/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Controladores dos campos
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Instância do nosso serviço
  final _firestoreService = FirestoreService();

  // Listas de categorias (baseado no que definimos)
  final List<String> _expenseCategories = [
    'Moradia', 'Alimentação', 'Transporte', 'Lazer', 
    'Saúde', 'Dívidas', 'Financiamentos', 'Educacional', 'Assinaturas e Serviços'
  ];
  final List<String> _incomeCategories = ['Salário', 'Renda Extra'];

  // Variáveis de estado do formulário
  String _selectedType = 'expense'; // "expense" ou "income"
  String? _selectedCategory; // Categoria começa nula
  DateTime _selectedDate = DateTime.now(); // Data começa como "hoje"
  bool _isLoading = false;

  // Dentro de _AddTransactionScreenState (arquivo lib/screens/add_transaction_screen.dart)

Future<void> _saveTransaction() async {
    // 1. Validação (continua igual)
    if (_amountController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 2. Criar o Modelo (continua igual)
      final newTransaction = TransactionModel(
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        type: _selectedType,
        category: _selectedCategory!,
        date: _selectedDate,
      );

      // 3. Salvar no Firestore (continua igual)
      await _firestoreService.addTransaction(newTransaction);

      // 4. CAMINHO DE SUCESSO (CORRIGIDO)
      if (mounted) {
        // PRIMEIRO: Para o loading
        setState(() { _isLoading = false; });
        
        // SEGUNDO: Mostra o feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação salva!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // TERCEIRO: Fecha a tela
        Navigator.pop(context); // Volta para a HomeScreen
      }

    } catch (e) {
      // 5. CAMINHO DE ERRO (CORRIGIDO)
      if (mounted) {
        // PRIMEIRO: Para o loading
        setState(() { _isLoading = false; });

        // SEGUNDO: Mostra o erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // (Vamos adicionar o seletor de data no futuro, por enquanto usamos "hoje")

  @override
  Widget build(BuildContext context) {
    // Escolhe a lista de categorias correta baseada no tipo
    final currentCategories = _selectedType == 'expense' 
        ? _expenseCategories 
        : _incomeCategories;
    
    // Reseta a categoria se ela não estiver na lista nova
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
                // Seletor de Tipo (Despesa / Receita)
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

                // Campo de Descrição
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de Valor
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor de Categoria (Dropdown)
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
                const SizedBox(height: 32),

                // Botão Salvar
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