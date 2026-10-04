class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;
  final bool isActive;
  final String commerceId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isActive,
    required this.commerceId,
  });

  // Convierte el producto a un formato que Firebase entiende
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'commerceId': commerceId,
    };
  }

  // Convierte lo que viene de Firebase en un producto
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      commerceId: map['commerceId'] ?? '',
    );
  }
}