// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Esta classe é o nosso "molde" para uma transação
class TransactionModel {
  // Atributos (campos) que toda transação terá
  final String? id; // O ID único do documento no Firestore (útil para editar/deletar)
  final String description; // Ex: "Conta de Luz", "Salário"
  final double amount; // O valor (sempre positivo)
  final String type; // O tipo: "income" (entrada) ou "expense" (saída)
  final String category; // Ex: "Moradia", "Alimentação", "Salário"
  final DateTime date; // A data que a transação ocorreu

  // Construtor da classe
  TransactionModel({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  // --- Métodos de Conversão ---

  // 1. Método `toJson()`
  // Converte o nosso objeto TransactionModel para um formato (Map)
  // que o Firestore consegue entender e salvar.
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date), // O Firestore usa um objeto 'Timestamp'
    };
  }

  // 2. Método `factory fromSnapshot()` (Fábrica)
  // Este é o oposto: ele pega um documento (um "Snapshot") do Firestore
  // e o transforma de volta no nosso objeto TransactionModel.
  // Usaremos isso para LER os dados do banco.
  factory TransactionModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!; // Pega os dados do documento
    
    return TransactionModel(
      id: doc.id, // Pega o ID único do documento
      description: data['description'],
      amount: (data['amount'] as num).toDouble(), // Converte de 'num' para 'double'
      type: data['type'],
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(), // Converte de 'Timestamp' para 'DateTime'
    );
  }
}