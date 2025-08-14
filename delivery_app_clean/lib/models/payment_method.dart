// lib/models/payment_method.dart

import 'package:flutter/material.dart';

/// Simple payment method model for UI purposes
class PaymentMethodModel {
  final String id;
  final String name;
  final IconData icon;
  final String? brand;
  final String? last4;
  final String? expMonth;
  final String? expYear;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.icon,
    this.brand,
    this.last4,
    this.expMonth,
    this.expYear,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentMethodModel(
      id: docId,
      name: map['name'] ?? '${map['brand'] ?? 'Card'} ••• ${map['last4'] ?? '0000'}',
      icon: _getIconForBrand(map['brand']),
      brand: map['brand'],
      last4: map['last4'],
      expMonth: map['expMonth'],
      expYear: map['expYear'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
    };
  }

  static IconData _getIconForBrand(String? brand) {
    if (brand == null) return Icons.credit_card;

    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}

/// Widget for displaying payment method selection
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool selected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? theme.primaryColor : theme.dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          method.icon,
          color: selected ? theme.primaryColor : theme.iconTheme.color,
        ),
        title: Text(
          method.name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? theme.primaryColor : null,
          ),
        ),
        trailing: selected
            ? Icon(Icons.radio_button_checked, color: theme.primaryColor)
            : Icon(Icons.radio_button_off, color: theme.disabledColor),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}