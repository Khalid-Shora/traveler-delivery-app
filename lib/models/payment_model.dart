class PaymentModel {
  final String paymentId;
  final String orderId;
  final String buyerId;
  final String travelerId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final DateTime? createdAt;
  final String? transactionId;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.buyerId,
    required this.travelerId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.createdAt,
    this.transactionId,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    paymentId: map['paymentId'],
    orderId: map['orderId'],
    buyerId: map['buyerId'],
    travelerId: map['travelerId'],
    amount: (map['amount'] as num).toDouble(),
    currency: map['currency'],
    method: map['method'],
    status: map['status'],
    createdAt: map['createdAt']?.toDate(),
    transactionId: map['transactionId'],
  );

  Map<String, dynamic> toMap() => {
    'paymentId': paymentId,
    'orderId': orderId,
    'buyerId': buyerId,
    'travelerId': travelerId,
    'amount': amount,
    'currency': currency,
    'method': method,
    'status': status,
    'createdAt': createdAt,
    'transactionId': transactionId,
  };
}
