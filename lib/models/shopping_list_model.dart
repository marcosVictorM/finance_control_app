// lib/models/shopping_list_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_list_item_model.dart'; // Importa o modelo do item

class ShoppingListModel {
  final String? id; // ID do documento no Firestore
  final String listName;
  final List<ShoppingListItemModel> items; // Uma lista de itens!

  ShoppingListModel({
    this.id,
    required this.listName,
    required this.items,
  });

  // --- Métodos de Conversão (para o Firestore) ---

  // Converte o nosso objeto Lista para um Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'listName': listName,
      // Converte cada item da lista para JSON também
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Converte um Snapshot do Firestore de volta para o nosso objeto Lista
  factory ShoppingListModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    
    // Pega o array 'items' do Firestore
    var itemsList = data['items'] as List<dynamic>;
    
    // Converte cada item do array de volta para um ShoppingListItemModel
    List<ShoppingListItemModel> convertedItems = itemsList
        .map((itemJson) => ShoppingListItemModel.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return ShoppingListModel(
      id: doc.id,
      listName: data['listName'] as String,
      items: convertedItems,
    );
  }
}