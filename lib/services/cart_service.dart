import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService {
  static final _cartCollection = FirebaseFirestore.instance.collection('carts');

  /// Get the cart for a specific user
  static Future<CartModel?> getUserCart(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _cartCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CartModel.fromMap(doc.data()!);
  }

  /// Add a product to the user's cart (if exists, increases quantity)
  static Future<void> addToCart(String uid, ProductModel product, {int quantity = 1, String currency = 'USD'}) async {
    final cartDoc = _cartCollection.doc(uid);
    final cartSnap = await cartDoc.get();

    List<CartItem> items = [];
    String cartId = uid;
    double total = 0.0;

    if (cartSnap.exists && cartSnap.data() != null) {
      items = List<Map<String, dynamic>>.from(cartSnap.data()!['items'] ?? [])
          .map((x) => CartItem.fromMap(x))
          .toList();
      cartId = cartSnap.data()!['cartId'] ?? uid;
      total = (cartSnap.data()!['total'] ?? 0.0).toDouble();
    }

    // Check if item exists by productId and link
    final idx = items.indexWhere((item) => item.productId == product.id && item.link == product.link);
    if (idx >= 0) {
      final existing = items[idx];
      items[idx] = CartItem(
        productId: existing.productId,
        name: existing.name,
        image: existing.image,
        link: existing.link,
        price: existing.price,
        quantity: existing.quantity + quantity,
        store: existing.store,
      );
    } else {
      items.add(
        CartItem(
          productId: product.id,
          name: product.name,
          image: product.imageUrl,
          link: product.link,
          price: product.price,
          quantity: quantity,
          store: product.store,
        ),
      );
    }

    total = items.fold(0.0, (sum, it) => sum + (it.price * it.quantity));

    await cartDoc.set({
      'cartId': cartId,
      'uid': uid,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': cartSnap.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update product quantity (set)
  static Future<void> updateQuantity(String uid, String productId, int newQuantity) async {
    final cartDoc = _cartCollection.doc(uid);
    final cartSnap = await cartDoc.get();

    List<CartItem> items = [];
    if (cartSnap.exists && cartSnap.data() != null) {
      items = List<Map<String, dynamic>>.from(cartSnap.data()!['items'] ?? [])
          .map((x) => CartItem.fromMap(x))
          .toList();
    }

    final idx = items.indexWhere((item) => item.productId == productId);
    if (idx >= 0) {
      if (newQuantity <= 0) {
        items.removeAt(idx);
      } else {
        final item = items[idx];
        items[idx] = CartItem(
          productId: item.productId,
          name: item.name,
          image: item.image,
          link: item.link,
          price: item.price,
          quantity: newQuantity,
          store: item.store,
        );
      }
    }

    double total = items.fold(0.0, (sum, it) => sum + (it.price * it.quantity));

    await cartDoc.set({
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove a product from cart
  static Future<void> removeFromCart(String uid, String productId) async {
    final cartDoc = _cartCollection.doc(uid);
    final cartSnap = await cartDoc.get();

    List<CartItem> items = [];
    if (cartSnap.exists && cartSnap.data() != null) {
      items = List<Map<String, dynamic>>.from(cartSnap.data()!['items'] ?? [])
          .map((x) => CartItem.fromMap(x))
          .toList();
    }

    items.removeWhere((item) => item.productId == productId);

    double total = items.fold(0.0, (sum, it) => sum + (it.price * it.quantity));

    await cartDoc.set({
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Clear all cart items
  static Future<void> clearCart(String uid) async {
    await _cartCollection.doc(uid).set({
      'items': [],
      'total': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
