// lib/models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id; // O ID do documento no Firestore
  final String category; // Ex: "Alimentação", "Lazer"
  final double limitAmount; // O valor máximo (ex: 500.00)
  final int month; // O mês (ex: 11 para Novembro)
  final int year; // O ano (ex: 2025)

  BudgetModel({
    this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  // --- Métodos de Conversão (para o Firestore) ---

  // Converte nosso objeto Dart para um Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
    };
  }

  // Converte um Snapshot do Firestore de volta para o nosso objeto BudgetModel
  factory BudgetModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    
    return BudgetModel(
      id: doc.id,
      category: data['category'] as String,
      limitAmount: (data['limitAmount'] as num).toDouble(),
      month: data['month'] as int,
      year: data['year'] as int,
    );
  }
}