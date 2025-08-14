import '../models/product_model.dart';
import '../models/address_model.dart';


class OrderModel {
  final String orderId;
  final String buyerId;
  final ProductModel product;
  final Address deliveryAddress;
  final String status;
  final String? travelerId;
  final double reward;
  final double shippingFee;
  final double total;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.product,
    required this.deliveryAddress,
    required this.status,
    this.travelerId,
    required this.reward,
    required this.shippingFee,
    required this.total,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    orderId: map['orderId'],
    buyerId: map['buyerId'],
    product: ProductModel.fromMap(map['product']),
    deliveryAddress: Address.fromMap(map['deliveryAddress']),
    status: map['status'],
    travelerId: map['travelerId'],
    reward: (map['reward'] as num).toDouble(),
    shippingFee: (map['shippingFee'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    paymentStatus: map['paymentStatus'],
    createdAt: map['createdAt']?.toDate(),
    updatedAt: map['updatedAt']?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'buyerId': buyerId,
    'product': product.toMap(),
    'deliveryAddress': deliveryAddress.toMap(),
    'status': status,
    'travelerId': travelerId,
    'reward': reward,
    'shippingFee': shippingFee,
    'total': total,
    'paymentStatus': paymentStatus,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
