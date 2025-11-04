// lib/services/firestore_service.dart

// 1. GARANTA QUE ESTA LINHA DE IMPORTAÇÃO ESTÁ AQUI NO TOPO:
import 'package:cloud_firestore/cloud_firestore.dart'; 
// ---
import '../models/shopping_list_model.dart';
import '../models/shopping_list_item_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart'; // Importa nosso modelo
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';

class FirestoreService {
  // Instâncias dos serviços do Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- MÉTODOS DE ESCRITA (Salvar/Criar) ---

  // Método para adicionar uma nova transação
  Future<void> addTransaction(TransactionModel transaction) async {
    // 1. Pegar o usuário logado
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      throw Exception("Usuário não autenticado. Não é possível salvar.");
    }

    // 2. Acessar a subcoleção do usuário e adicionar a transação
    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid) // O ID do usuário logado
          .collection('transactions') // A subcoleção dele
          .add(transaction.toJson()); // Adiciona os dados convertidos
    } catch (e) {
      print("Erro ao adicionar transação: $e");
      // Re-lança o erro para a UI (a tela) poder tratar
      throw Exception("Falha ao salvar a transação.");
    }
  }

  // --- MÉTODOS DE LEITURA (Ler/Obter) ---
  // --- MÉTODOS DAS LISTAS DE COMPRAS ---

  // 1. Criar uma nova lista de compras (vazia)
  Future<void> createShoppingList(String listName) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    // Cria um novo objeto ShoppingListModel
    final newList = ShoppingListModel(
      listName: listName,
      items: [], // Começa com uma lista de itens vazia
    );

    try {
      // Salva na nova subcoleção 'shopping_lists'
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shopping_lists')
          .add(newList.toJson());
    } catch (e) {
      print("Erro ao criar lista de compras: $e");
      throw Exception("Falha ao criar lista.");
    }
  }

  // 2. Ler todas as listas de compras em tempo real (Stream)
  Stream<List<ShoppingListModel>> getShoppingListsStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('shopping_lists')
        .snapshots() // "Ouve" a coleção
        .map((snapshot) {
          // Converte cada documento de volta para nosso objeto Model
          return snapshot.docs.map((doc) {
            return ShoppingListModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          }).toList();
        });
  }

  // 3. Atualizar os itens de uma lista específica
  // (Esta é a função chave: para adicionar, remover ou marcar itens)
  Future<void> updateShoppingListItems(String listId, List<ShoppingListItemModel> items) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    // Converte a lista de objetos Dart para uma lista de JSON (Maps)
    final List<Map<String, dynamic>> itemsAsJson = 
        items.map((item) => item.toJson()).toList();

    try {
      // Encontra o documento da lista e atualiza *apenas* o campo 'items'
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shopping_lists')
          .doc(listId)
          .update({'items': itemsAsJson});
    } catch (e) {
      print("Erro ao atualizar itens da lista: $e");
      throw Exception("Falha ao atualizar lista.");
    }
  }

  // 4. Deletar uma lista de compras inteira
  Future<void> deleteShoppingList(String listId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shopping_lists')
          .doc(listId)
          .delete();
    } catch (e) {
      print("Erro ao deletar lista: $e");
      throw Exception("Falha ao deletar lista.");
    }
  }
  // 1. Criar um novo orçamento
  Future<void> createBudget(BudgetModel budget) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      // Salva na nova subcoleção 'budgets'
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('budgets') 
          .add(budget.toJson());
    } catch (e) {
      print("Erro ao criar orçamento: $e");
      throw Exception("Falha ao criar orçamento.");
    }
  }

  // 2. Ler os orçamentos de um MÊS e ANO específicos (Stream)
  Stream<List<BudgetModel>> getBudgetsStream(int month, int year) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    // Nós filtramos para pegar apenas os orçamentos do período selecionado
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('budgets')
        .where('month', isEqualTo: month) // Filtra pelo mês
        .where('year', isEqualTo: year)   // Filtra pelo ano
        .snapshots() // "Ouve" a coleção
        .map((snapshot) {
          // Converte cada documento de volta para nosso objeto Model
          return snapshot.docs.map((doc) {
            return BudgetModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          }).toList();
        });
  }

  // 3. Atualizar o valor de um orçamento
  Future<void> updateBudgetLimit(String budgetId, double newLimitAmount) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('budgets')
          .doc(budgetId)
          .update({'limitAmount': newLimitAmount}); // Atualiza só o valor limite
    } catch (e) {
      print("Erro ao atualizar orçamento: $e");
      throw Exception("Falha ao atualizar orçamento.");
    }
  }

  // 4. Deletar um orçamento
  Future<void> deleteBudget(String budgetId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('budgets')
          .doc(budgetId)
          .delete();
    } catch (e) {
      print("Erro ao deletar orçamento: $e");
      throw Exception("Falha ao deletar orçamento.");
    }
  }
  // 1. Criar um novo "molde" de transação recorrente
  // lib/services/firestore_service.dart

  // 1. Criar um novo "molde" de transação recorrente
  Future<String> createRecurringTransaction(RecurringTransactionModel recurring) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      // Salva na nova subcoleção 'recurring_transactions'
      final docRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recurring_transactions')
          .add(recurring.toJson());
      
      return docRef.id; // <-- MUDANÇA AQUI: Retorna o ID do novo documento
      
    } catch (e) {
      print("Erro ao criar transação recorrente: $e");
      throw Exception("Falha ao criar transação recorrente.");
    }
  }
  // 2. Ler todos os "moldes" recorrentes (Stream)
  // Usado para a tela de gerenciamento
  Stream<List<RecurringTransactionModel>> getRecurringTransactionsStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('recurring_transactions')
        .snapshots() // "Ouve" a coleção
        .map((snapshot) {
          // Converte cada documento de volta para nosso objeto Model
          return snapshot.docs.map((doc) {
            return RecurringTransactionModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          }).toList();
        });
  }

  // 3. Atualizar a data do último lançamento de um recorrente
  // Este é o método chave após o usuário aprovar o lançamento
  Future<void> updateRecurringTransactionPostedDate(String recurringId, int month, int year) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recurring_transactions')
          .doc(recurringId)
          .update({
            'lastPostedMonth': month,
            'lastPostedYear': year,
          });
    } catch (e) {
      print("Erro ao atualizar data do recorrente: $e");
      throw Exception("Falha ao atualizar data.");
    }
  }

  // 4. Deletar um "molde" recorrente
  Future<void> deleteRecurringTransaction(String recurringId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('recurring_transactions')
          .doc(recurringId)
          .delete();
    } catch (e) {
      print("Erro ao deletar recorrente: $e");
      throw Exception("Falha ao deletar recorrente.");
    }
  }
  // lib/services/firestore_service.dart

  // 5. LANÇAR TRANSAÇÕES RECORRENTES (VERSÃO CORRIGIDA - SEM BATCH)
  Future<void> postRecurringTransactions(
    List<RecurringTransactionModel> transactionsToPost,
    DateTime postDate,
  ) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    // Vamos iterar e fazer duas chamadas 'await' separadas
    // em vez de usar um WriteBatch.
    
    final int lastDayOfMonth = DateTime(postDate.year, postDate.month + 1, 0).day;

    for (var model in transactionsToPost) {
      // 1. Garante que o dia é válido (evita bug de "dia 31" em Fevereiro)
      int day = model.dayOfMonth;
      if (day > lastDayOfMonth) {
        day = lastDayOfMonth;
      }
      final dateToPost = DateTime(postDate.year, postDate.month, day);

      // 2. Cria a nova transação (a transação real)
      final newTransaction = TransactionModel(
        description: model.description,
        amount: model.amount,
        type: model.type,
        category: model.category,
        date: dateToPost,
      );

      try {
        // 3. Operação 1: Adicionar a nova transação
        // (Usamos o método que já sabemos que funciona!)
        await addTransaction(newTransaction);
        
        // 4. Operação 2: Atualizar a data do "molde" recorrente
        // (Usamos o método que já existe!)
        await updateRecurringTransactionPostedDate(
            model.id!, postDate.month, postDate.year);
            
      } catch (e) {
        // Se qualquer uma das etapas falhar, nós paramos e avisamos.
        print("Erro ao postar transação recorrente: $e");
        throw Exception("Falha ao lançar ${model.description}.");
      }
    }
  }
Future<void> deleteTransaction(String transactionId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não autenticado.");

    try {
      // Navega até a transação específica e a deleta
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      print("Erro ao deletar transação: $e");
      throw Exception("Falha ao deletar transação.");
    }
  }
  // Método para LER todas as transações em tempo real (Stream)
  Stream<List<TransactionModel>> getTransactionsStream() {
    // 1. Pegar o usuário logado
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Se não há usuário, retorna um "fluxo" vazio
      return Stream.value([]);
    }

    // 2. Acessar a subcoleção, ordenar por data e "ouvir" as mudanças
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('transactions')
        .orderBy('date', descending: true) // Ordena da mais nova para a mais antiga
        .snapshots() // Retorna um Stream que atualiza em tempo real
        .map((snapshot) {
          // 3. Para cada "foto" da coleção, converte os documentos
          return snapshot.docs.map((doc) {
            
            // ESTA É A LINHA DO ERRO (LINHA 62)
            // O 'doc' é um QueryDocumentSnapshot<Object?>
            // Nosso factory 'fromSnapshot' espera um DocumentSnapshot<Map<String, dynamic>>
            // O 'as' faz essa conversão de tipo.
            // O erro acontece porque 'DocumentSnapshot' não é conhecido.
            
            // Com a importação adicionada no topo, esta linha funcionará:
            return TransactionModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          }).toList(); // Converte tudo para uma Lista
        });
  }
}