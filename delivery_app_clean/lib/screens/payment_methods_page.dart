// lib/screens/payment_methods_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class PaymentMethodsPage extends StatefulWidget {
  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<Map<String, dynamic>> paymentMethods = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to view payment methods");

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .get();

      setState(() {
        paymentMethods = snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _addPaymentMethod() async {
    final result = await Navigator.pushNamed(context, RoutePaths.kAddCard);
    if (result == true) {
      _loadPaymentMethods(); // Refresh the list
    }
  }

  Future<void> _deletePaymentMethod(String docId, String cardName) async {
    final confirmed = await _showDeleteConfirmation(cardName);
    if (!confirmed) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .doc(docId)
          .delete();

      setState(() {
        paymentMethods.removeWhere((method) => method['docId'] == docId);
      });

      _showSuccessSnackBar('Payment method removed successfully');
    } catch (e) {
      _showErrorSnackBar('Error removing payment method: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(String cardName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: const Text('Remove Payment Method'),
        content: Text('Are you sure you want to remove "$cardName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kError),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
      ),
      body: loading ? _buildLoading() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPaymentMethod,
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.kPrimary),
          const SizedBox(height: AppDimens.kPaddingMedium),
          const Text('Loading payment methods...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();
    if (paymentMethods.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadPaymentMethods,
      color: AppColors.kPrimary,
      child: SingleChildScrollView(
        padding: AppDimens.kScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: AppColors.kInfo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(color: AppColors.kInfo.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppColors.kInfo),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.kInfo,
                          ),
                        ),
                        Text(
                          'Your payment information is encrypted and secure',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.kInfo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Payment Methods List
            Text(
              'Saved Payment Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),

            ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),

            const SizedBox(height: AppDimens.kPaddingXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.kError),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Unable to load payment methods',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadPaymentMethods,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.kAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.payment_outlined,
                size: 60,
                color: AppColors.kAccent,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'No Payment Methods',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            const Text(
              'Add payment methods for faster checkout',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add_card),
              label: const Text('Add Your First Card'),
              style: AppButtonStyles.kPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final brand = method['brand']?.toString().toUpperCase() ?? 'CARD';
    final last4 = method['last4']?.toString() ?? '0000';
    final expMonth = method['expMonth']?.toString().padLeft(2, '0') ?? '00';
    final expYear = method['expYear']?.toString() ?? '00';
    final isDefault = method['isDefault'] == true;

    Color brandColor = _getBrandColor(brand);
    IconData brandIcon = _getBrandIcon(brand);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(
          color: isDefault ? AppColors.kPrimary : Theme.of(context).dividerColor,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Padding(
        padding: AppDimens.kCardPadding,
        child: Row(
          children: [
            // Card Icon
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: brandColor.withValues(alpha: 0.3)),
              ),
              child: Icon(brandIcon, color: brandColor, size: 20),
            ),

            const SizedBox(width: AppDimens.kPaddingMedium),

            // Card Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$brand ••• $last4',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.kPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Expires $expMonth/$expYear',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Actions Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'default':
                    _setAsDefault(method['docId']);
                    break;
                  case 'delete':
                    _deletePaymentMethod(method['docId'], '$brand ••• $last4');
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 8),
                        Text('Set as Default'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAsDefault(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Remove default from all cards
      for (final method in paymentMethods) {
        if (method['isDefault'] == true) {
          batch.update(
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('payment_methods')
                  .doc(method['docId']),
              {'isDefault': false}
          );
        }
      }

      // Set new default
      batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('payment_methods')
              .doc(docId),
          {'isDefault': true}
      );

      await batch.commit();
      await _loadPaymentMethods(); // Refresh
      _showSuccessSnackBar('Default payment method updated');
    } catch (e) {
      _showErrorSnackBar('Error updating default payment method: $e');
    }
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
      case 'american express':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6000);
      default:
        return AppColors.kPrimary;
    }
  }

  IconData _getBrandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
      case 'mastercard':
      case 'amex':
      case 'american express':
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}