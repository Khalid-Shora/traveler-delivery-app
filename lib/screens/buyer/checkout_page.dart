// lib/screens/buyer/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cart_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import '../../services/user_service.dart';
import '../../constants/app_constants.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Data
  CartModel? cart;
  UserModel? user;
  List<Map<String, dynamic>> savedCards = [];

  // State
  bool loading = true;
  bool loadingCards = false;
  bool paying = false;
  String? error;

  // Selections
  int selectedAddressIndex = 0;
  String selectedPaymentMethodId = 'googlepay';
  String selectedDeliveryOption = 'standard';

  // Delivery options
  final deliveryOptions = [
    {'id': 'standard', 'name': 'Standard Delivery', 'description': '5-7 business days', 'price': 15.0, 'icon': Icons.local_shipping},
    {'id': 'express', 'name': 'Express Delivery', 'description': '2-3 business days', 'price': 25.0, 'icon': Icons.flash_on},
    {'id': 'priority', 'name': 'Priority Delivery', 'description': '1-2 business days', 'price': 35.0, 'icon': Icons.rocket_launch},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Calculate totals
  double get deliveryFee => deliveryOptions.firstWhere((o) => o['id'] == selectedDeliveryOption)['price'] as double;
  double get totalWithDelivery => (cart?.total ?? 0) + deliveryFee;

  // Load data
  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Please log in to continue");

      final results = await Future.wait([
        UserService.getUser(uid),
        CartService.getUserCart(uid),
        _loadSavedCards(uid),
      ]);

      setState(() {
        user = results[0] as UserModel?;
        cart = results[1] as CartModel?;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadSavedCards(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payment_methods')
          .get();

      savedCards = snap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      // Set default payment method
      if (savedCards.isNotEmpty) {
        selectedPaymentMethodId = 'saved_${savedCards[0]['docId']}';
      }
    } catch (e) {
      print('Error loading saved cards: $e');
    }
  }

  // Place order
  Future<void> _placeOrder() async {
    if (cart == null || user == null) return;
    if (user!.addresses == null || user!.addresses!.isEmpty) {
      setState(() => error = "Please add a delivery address first");
      return;
    }

    setState(() {
      error = null;
      paying = true;
    });

    try {
      // Create order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'uid': user!.uid,
        'items': cart!.items.map((e) => e.toMap()).toList(),
        'subtotal': cart!.total,
        'deliveryFee': deliveryFee,
        'total': totalWithDelivery,
        'currency': cart!.currency,
        'createdAt': FieldValue.serverTimestamp(),
        'address': user!.addresses![selectedAddressIndex].toMap(),
        'paymentMethod': selectedPaymentMethodId,
        'deliveryOption': selectedDeliveryOption,
        'status': 'pending',
        'travelerId': null,
      });

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update order as paid
      await orderRef.update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'orderId': orderRef.id,
      });

      // Clear cart
      await CartService.clearCart(user!.uid);

      setState(() => paying = false);
      _showSuccessDialog(orderRef.id);

    } catch (e) {
      setState(() {
        error = e.toString();
        paying = false;
      });
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.kBorderRadius)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.check_circle, size: 50, color: AppColors.kSuccess),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Order Placed Successfully!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text('Order ID: $orderId', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: AppButtonStyles.kPrimary,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: loading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.kPrimary),
          const SizedBox(height: AppDimens.kPaddingMedium),
          const Text('Loading checkout...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();
    if (cart == null || cart!.items.isEmpty) return _buildEmptyCart();

    final hasAddresses = user?.addresses != null && user!.addresses!.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppDimens.kScreenPadding,
            child: Column(
              children: [
                _buildAddressSection(),
                const SizedBox(height: AppDimens.kPaddingLarge),
                _buildDeliverySection(),
                const SizedBox(height: AppDimens.kPaddingLarge),
                _buildPaymentSection(),
                const SizedBox(height: AppDimens.kPaddingLarge),
                _buildOrderSummary(),
              ],
            ),
          ),
        ),
        _buildBottomSection(hasAddresses),
      ],
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
            Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadData,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
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
              child: Icon(Icons.shopping_cart_outlined, size: 60, color: AppColors.kAccent),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text('Your cart is empty', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppDimens.kPaddingMedium),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.kPrimary,
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.kPrimary, size: 20),
        ),
        const SizedBox(width: AppDimens.kPaddingMedium),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Delivery Address', Icons.location_on),
        const SizedBox(height: AppDimens.kPaddingMedium),

        if (user?.addresses == null || user!.addresses!.isEmpty)
          _buildNoAddressCard()
        else
          ...user!.addresses!.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            final isSelected = selectedAddressIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.kPrimary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(
                  color: isSelected ? AppColors.kPrimary : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: AppShadows.kCardShadow,
              ),
              child: ListTile(
                onTap: () => setState(() => selectedAddressIndex = index),
                leading: Icon(Icons.location_on, color: isSelected ? AppColors.kPrimary : AppColors.kAccent),
                title: Text(address.label, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(address.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.kPrimary) : null,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildNoAddressCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.kWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(color: AppColors.kWarning.withValues(alpha: 0.3)),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, size: 48, color: AppColors.kWarning),
          const SizedBox(height: AppDimens.kPaddingMedium),
          Text('No delivery address', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimens.kPaddingSmall),
          const Text('Please add a delivery address to continue', textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.kPaddingMedium),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RoutePaths.kAddresses),
            icon: const Icon(Icons.add_location),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kWarning, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Delivery Options', Icons.local_shipping),
        const SizedBox(height: AppDimens.kPaddingMedium),

        ...deliveryOptions.map((option) {
          final isSelected = selectedDeliveryOption == option['id'];

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.kPrimary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              border: Border.all(
                color: isSelected ? AppColors.kPrimary : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: AppShadows.kCardShadow,
            ),
            child: ListTile(
              onTap: () => setState(() => selectedDeliveryOption = option['id'] as String),
              leading: Icon(option['icon'] as IconData, color: isSelected ? AppColors.kPrimary : AppColors.kAccent),
              title: Text(option['name'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(option['description'] as String),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${(option['price'] as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (isSelected) Icon(Icons.check_circle, color: AppColors.kPrimary, size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Method', Icons.payment),
        const SizedBox(height: AppDimens.kPaddingMedium),

        // Google Pay
        _buildPaymentMethodTile(
          id: 'googlepay',
          title: 'Google Pay',
          subtitle: 'Quick payment with Google Pay',
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Text('G', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Pay', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),

        // Saved Cards
        ...savedCards.map((card) {
          return _buildPaymentMethodTile(
            id: 'saved_${card['docId']}',
            title: '${card['brand']?.toUpperCase() ?? 'CARD'} ••• ${card['last4'] ?? '0000'}',
            subtitle: 'Expires ${card['expMonth'] ?? '00'}/${card['expYear'] ?? '00'}',
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getCardColor(card['brand']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getCardColor(card['brand']).withValues(alpha: 0.3)),
              ),
              child: Text(
                card['brand']?.toUpperCase() ?? 'CARD',
                style: TextStyle(color: _getCardColor(card['brand']), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),

        // Add New Card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: AppShadows.kCardShadow,
          ),
          child: ListTile(
            onTap: () async {
              final result = await Navigator.pushNamed(context, RoutePaths.kAddCard);
              if (result == true) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await _loadSavedCards(uid);
                  if (savedCards.isNotEmpty) {
                    setState(() => selectedPaymentMethodId = 'saved_${savedCards.last['docId']}');
                  }
                }
              }
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.add, color: AppColors.kPrimary, size: 20),
            ),
            title: Text('Add new card', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kPrimary)),
            subtitle: const Text('Pay with a new credit or debit card'),
            trailing: Icon(Icons.arrow_forward_ios, color: AppColors.kPrimary, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required Widget leading,
  }) {
    final isSelected = selectedPaymentMethodId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(
          color: isSelected ? AppColors.kPrimary : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: ListTile(
        onTap: () => setState(() => selectedPaymentMethodId = id),
        leading: leading,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.kPrimary : Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
          child: isSelected
              ? Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.kPrimary),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Order Summary', Icons.receipt),
        const SizedBox(height: AppDimens.kPaddingMedium),

        Container(
          padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
            boxShadow: AppShadows.kCardShadow,
          ),
          child: Column(
            children: [
              // Items
              ...cart!.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingSmall),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.kBackground,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: AppColors.kText, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.kPaddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${item.quantity} x \$${item.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),

              const Divider(height: AppDimens.kPaddingLarge),

              // Totals
              _buildSummaryRow('Subtotal', '\$${cart!.total.toStringAsFixed(2)}'),
              const SizedBox(height: AppDimens.kPaddingSmall),
              _buildSummaryRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
              const Divider(height: AppDimens.kPaddingLarge),
              _buildSummaryRow('Total', '\$${totalWithDelivery.toStringAsFixed(2)}', isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.kPrimary)
              : Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool hasAddresses) {
    return Container(
      padding: AppDimens.kScreenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Error
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.kError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kError.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.kError, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: TextStyle(color: AppColors.kError))),
                  ],
                ),
              ),
            ],

            // Total
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount'),
                      Text(
                        '\$${totalWithDelivery.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (paying || !hasAddresses) ? null : _placeOrder,
                style: AppButtonStyles.kPrimary.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
                ),
                child: paying
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
                    : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            // Security
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.kSuccess),
                const SizedBox(width: 4),
                Text(
                  'Secure payment protected by encryption',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kSuccess),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa': return const Color(0xFF1A1F71);
      case 'mastercard': return const Color(0xFFEB001B);
      case 'amex': return const Color(0xFF006FCF);
      default: return AppColors.kPrimary;
    }
  }
}