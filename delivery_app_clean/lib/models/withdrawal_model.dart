// lib/models/withdrawal_model.dart

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

enum PaymentMethodType {
  bankAccount,
  paypal,
  stripe,
  wise,
}

class PaymentMethod {
  final PaymentMethodType type;
  final String accountId;
  final String accountName;
  final String? bankName;
  final String? accountNumber; // Masked
  final String? routingNumber; // Masked
  final String? swift;
  final String? iban;

  PaymentMethod({
    required this.type,
    required this.accountId,
    required this.accountName,
    this.bankName,
    this.accountNumber,
    this.routingNumber,
    this.swift,
    this.iban,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'accountId': accountId,
      'accountName': accountName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'swift': swift,
      'iban': iban,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: PaymentMethodType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => PaymentMethodType.bankAccount,
      ),
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? '',
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      routingNumber: map['routingNumber'],
      swift: map['swift'],
      iban: map['iban'],
    );
  }
}

class IncludedOrder {
  final String orderId;
  final double earnings;
  final double commission;
  final DateTime completedAt;

  IncludedOrder({
    required this.orderId,
    required this.earnings,
    required this.commission,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'earnings': earnings,
      'commission': commission,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  factory IncludedOrder.fromMap(Map<String, dynamic> map) {
    return IncludedOrder(
      orderId: map['orderId'] ?? '',
      earnings: (map['earnings'] as num?)?.toDouble() ?? 0.0,
      commission: (map['commission'] as num?)?.toDouble() ?? 0.0,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ProcessorResponse {
  final String code;
  final String message;
  final String? referenceId;

  ProcessorResponse({
    required this.code,
    required this.message,
    this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'referenceId': referenceId,
    };
  }

  factory ProcessorResponse.fromMap(Map<String, dynamic> map) {
    return ProcessorResponse(
      code: map['code'] ?? '',
      message: map['message'] ?? '',
      referenceId: map['referenceId'],
    );
  }
}

class WithdrawalModel {
  final String id;
  final String travelerId;
  final double amount;
  final String currency;
  final WithdrawalStatus status;

  final PaymentMethod paymentMethod;
  final String? transactionId;
  final double processorFee;
  final double netAmount;

  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? estimatedArrival;

  final List<IncludedOrder> includedOrders;
  final ProcessorResponse? processorResponse;
  final String? adminNotes;
  final String? failureReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalModel({
    required this.id,
    required this.travelerId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    required this.processorFee,
    required this.netAmount,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.estimatedArrival,
    required this.includedOrders,
    this.processorResponse,
    this.adminNotes,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'travelerId': travelerId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'paymentMethod': paymentMethod.toMap(),
      'transactionId': transactionId,
      'processorFee': processorFee,
      'netAmount': netAmount,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'estimatedArrival': estimatedArrival != null ? Timestamp.fromDate(estimatedArrival!) : null,
      'includedOrders': includedOrders.map((order) => order.toMap()).toList(),
      'processorResponse': processorResponse?.toMap(),
      'adminNotes': adminNotes,
      'failureReason': failureReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WithdrawalModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WithdrawalModel(
      id: map['id'] ?? documentId,
      travelerId: map['travelerId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      status: WithdrawalStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      paymentMethod: PaymentMethod.fromMap(map['paymentMethod'] ?? {}),
      transactionId: map['transactionId'],
      processorFee: (map['processorFee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      estimatedArrival: (map['estimatedArrival'] as Timestamp?)?.toDate(),
      includedOrders: (map['includedOrders'] as List?)
          ?.map((order) => IncludedOrder.fromMap(order))
          .toList() ?? [],
      processorResponse: map['processorResponse'] != null
          ? ProcessorResponse.fromMap(map['processorResponse'])
          : null,
      adminNotes: map['adminNotes'],
      failureReason: map['failureReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  WithdrawalModel copyWith({
    String? id,
    String? travelerId,
    double? amount,
    String? currency,
    WithdrawalStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    double? processorFee,
    double? netAmount,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? estimatedArrival,
    List<IncludedOrder>? includedOrders,
    ProcessorResponse? processorResponse,
    String? adminNotes,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WithdrawalModel(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      processorFee: processorFee ?? this.processorFee,
      netAmount: netAmount ?? this.netAmount,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      includedOrders: includedOrders ?? this.includedOrders,
      processorResponse: processorResponse ?? this.processorResponse,
      adminNotes: adminNotes ?? this.adminNotes,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isCompleted => status == WithdrawalStatus.completed;
  bool get isFailed => status == WithdrawalStatus.failed;
  bool get canCancel => status == WithdrawalStatus.pending;

  String get statusText {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending Review';
      case WithdrawalStatus.processing:
        return 'Processing';
      case WithdrawalStatus.completed:
        return 'Completed';
      case WithdrawalStatus.failed:
        return 'Failed';
      case WithdrawalStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case WithdrawalStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case WithdrawalStatus.processing:
        return const Color(0xFF42A5F5); // Blue
      case WithdrawalStatus.completed:
        return const Color(0xFF66BB6A); // Green
      case WithdrawalStatus.failed:
      case WithdrawalStatus.cancelled:
        return const Color(0xFFEF5350); // Red
    }
  }

  double get totalEarnings => includedOrders.fold(0.0, (sum, order) => sum + order.earnings);
  int get orderCount => includedOrders.length;
}