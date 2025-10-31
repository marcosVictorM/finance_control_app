// lib/models/shopping_list_item_model.dart

class ShoppingListItemModel {
  final String itemName;
  final String? link;
  final double? price; // <-- NOVO CAMPO ADICIONADO
  bool isChecked;

  ShoppingListItemModel({
    required this.itemName,
    this.link,
    this.price, // <-- ADICIONADO AO CONSTRUTOR
    this.isChecked = false,
  });

  // --- Métodos de Conversão (para o Array do Firestore) ---

  // Converte nosso objeto Dart para um Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'link': link,
      'price': price, // <-- ADICIONADO AO JSON
      'isChecked': isChecked,
    };
  }

  // Converte um Map (JSON) de volta para nosso objeto Dart
  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemModel(
      itemName: json['itemName'] as String,
      link: json['link'] as String?,
      // Converte de 'num' (que pode ser int ou double) para double
      price: (json['price'] as num?)?.toDouble(), // <-- ADICIONADO DO JSON
      isChecked: json['isChecked'] as bool,
    );
  }
}