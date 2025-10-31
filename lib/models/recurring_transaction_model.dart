// lib/models/recurring_transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTransactionModel {
  final String? id; // O ID do documento no Firestore
  final String description; // Ex: "Salário", "Netflix"
  final double amount;
  final String type; // "income" ou "expense"
  final String category;
  final int dayOfMonth; // Dia do mês que ela vence (ex: 5, 10, 20)

  // Campos para rastrear o último lançamento
  final int? lastPostedMonth; // O último MÊS que lançamos (ex: 10 para Outubro)
  final int? lastPostedYear;  // O último ANO que lançamos (ex: 2025)

  RecurringTransactionModel({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.dayOfMonth,
    this.lastPostedMonth,
    this.lastPostedYear,
  });

  // --- Métodos de Conversão (para o Firestore) ---

  // Converte nosso objeto Dart para um Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'dayOfMonth': dayOfMonth,
      'lastPostedMonth': lastPostedMonth,
      'lastPostedYear': lastPostedYear,
    };
  }

  // Converte um Snapshot do Firestore de volta para o nosso objeto
  factory RecurringTransactionModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    
    return RecurringTransactionModel(
      id: doc.id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      category: data['category'] as String,
      dayOfMonth: data['dayOfMonth'] as int,
      lastPostedMonth: data['lastPostedMonth'] as int?,
      lastPostedYear: data['lastPostedYear'] as int?,
    );
  }
}