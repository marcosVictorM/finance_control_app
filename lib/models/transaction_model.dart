// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id; 
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  
  // --- 1. NOVO CAMPO ADICIONADO ---
  final String? paymentMethod; // Ex: "Dinheiro", "Pix", "Cartão de Crédito"

  TransactionModel({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.paymentMethod, // --- 2. ADICIONADO AO CONSTRUTOR ---
  });

  // --- Métodos de Conversão ---

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod, // --- 3. ADICIONADO AO JSON ---
    };
  }

  factory TransactionModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    
    return TransactionModel(
      id: doc.id,
      description: data['description'],
      amount: (data['amount'] as num).toDouble(),
      type: data['type'],
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(),
      // --- 4. ADICIONADO DO SNAPSHOT ---
      // (Será 'null' para transações antigas, o que é perfeito)
      paymentMethod: data['paymentMethod'] as String?, 
    );
  }
}