class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String store;
  final String? description;
  final String link;

  ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.store,
    required this.link,
    this.description,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      store: map['store'] ?? '',
      description: map['description'],
      link: map['link'] ?? '',
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      store: json['store'] ?? '',        // <-- هنا التغيير
      description: json['description'],
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'store': store,
      'description': description,
    };
  }
}
