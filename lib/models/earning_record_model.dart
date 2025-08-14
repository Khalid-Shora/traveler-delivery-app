import 'package:cloud_firestore/cloud_firestore.dart';

class EarningRecordModel {
  final String id;
  final String userId;
  final String orderId;
  final double amount;
  final String status; // 'pending', 'paid', etc.
  final Timestamp createdAt;

  EarningRecordModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  EarningRecordModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    double? amount,
    String? status,
    Timestamp? createdAt,
  }) {
    return EarningRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory EarningRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return EarningRecordModel(
      id: id,
      userId: map['userId'] ?? '',
      orderId: map['orderId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderId': orderId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
