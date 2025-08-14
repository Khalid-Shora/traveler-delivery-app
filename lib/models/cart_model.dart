class CartModel {
  final String cartId;
  final String uid;
  final List<CartItem> items;
  final double total;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartModel({
    required this.cartId,
    required this.uid,
    required this.items,
    required this.total,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });

  factory CartModel.fromMap(Map<String, dynamic> map) => CartModel(
    cartId: map['cartId'],
    uid: map['uid'],
    items: (map['items'] as List)
        .map((x) => CartItem.fromMap(x))
        .toList(),
    total: (map['total'] as num).toDouble(),
    currency: map['currency'],
    createdAt: map['createdAt']?.toDate(),
    updatedAt: map['updatedAt']?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'cartId': cartId,
    'uid': uid,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'currency': currency,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class CartItem {
  final String productId;
  final String name;
  final String image;
  final String link;
  final double price;
  final int quantity;
  final String store;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.link,
    required this.price,
    required this.quantity,
    required this.store,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    productId: map['productId'],
    name: map['name'],
    image: map['image'],
    link: map['link'],
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'],
    store: map['store'],
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'image': image,
    'link': link,
    'price': price,
    'quantity': quantity,
    'store': store,
  };
}
