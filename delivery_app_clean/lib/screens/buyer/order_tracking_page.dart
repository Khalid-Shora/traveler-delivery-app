// lib/screens/buyer/order_tracking_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? orderId;

  const OrderTrackingPage({Key? key, this.orderId}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Map<String, dynamic>? orderData;
  bool loading = true;
  String? error;

  final orderStatuses = [
    {'id': 'pending', 'title': 'Order Placed', 'description': 'Your order has been placed', 'icon': Icons.shopping_cart},
    {'id': 'paid', 'title': 'Payment Confirmed', 'description': 'Payment received successfully', 'icon': Icons.payment},
    {'id': 'processing', 'title': 'Processing', 'description': 'Preparing your order', 'icon': Icons.inventory},
    {'id': 'shipped', 'title': 'Shipped', 'description': 'Order is on the way', 'icon': Icons.local_shipping},
    {'id': 'delivered', 'title': 'Delivered', 'description': 'Order delivered successfully', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    if (widget.orderId == null) {
      setState(() {
        error = "Order ID not provided";
        loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = "Order not found";
          loading = false;
        });
        return;
      }

      setState(() {
        orderData = doc.data();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  int _getCurrentStatusIndex() {
    if (orderData == null) return 0;
    final status = orderData!['status'] as String;
    return orderStatuses.indexWhere((s) => s['id'] == status);
  }

  Color _getStatusColor(int index) {
    final currentIndex = _getCurrentStatusIndex();
    if (index <= currentIndex) return AppColors.kSuccess;
    return AppColors.kDisabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.orderId != null ? 'Track Order' : 'Order Tracking'),
        centerTitle: true,
        actions: [
          if (orderData != null)
            IconButton(
              onPressed: () {
                // TODO: Contact support
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact support feature coming soon')),
                );
              },
              icon: const Icon(Icons.support_agent),
              tooltip: 'Contact Support',
            ),
        ],
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
          const Text('Loading order details...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();
    if (orderData == null) return _buildNoOrder();

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      color: AppColors.kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDimens.kScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: AppDimens.kPaddingLarge),
            _buildStatusTimeline(),
            const SizedBox(height: AppDimens.kPaddingLarge),
            _buildDeliveryInfo(),
            const SizedBox(height: AppDimens.kPaddingLarge),
            _buildOrderItems(),
            const SizedBox(height: AppDimens.kPaddingLarge),
            _buildOrderSummary(),
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
              'Unable to load order',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadOrderData,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrder() {
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
              child: Icon(Icons.receipt_long, size: 60, color: AppColors.kAccent),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'No Order Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            const Text('The order you\'re looking for doesn\'t exist or has been removed.'),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: AppButtonStyles.kPrimary,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final orderId = orderData!['orderId'] ?? widget.orderId;
    final createdAt = orderData!['createdAt'] as Timestamp?;
    final total = orderData!['total'] as double;
    final currency = orderData!['currency'] as String? ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                ),
                child: Icon(Icons.receipt, color: AppColors.kPrimary, size: 20),
              ),
              const SizedBox(width: AppDimens.kPaddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId?.substring(0, 8) ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        'Placed on ${_formatDate(createdAt.toDate())}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '$currency ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.kPaddingLarge),

          ...orderStatuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = index <= _getCurrentStatusIndex();
            final isActive = index == _getCurrentStatusIndex();
            final isLast = index == orderStatuses.length - 1;

            return Column(
              children: [
                Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.kSuccess : AppColors.kDisabled.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppColors.kSuccess : (isCompleted ? AppColors.kSuccess : AppColors.kDisabled),
                          width: isActive ? 3 : 2,
                        ),
                      ),
                      child: Icon(
                        status['icon'] as IconData,
                        color: isCompleted ? Colors.white : AppColors.kDisabled,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: AppDimens.kPaddingMedium),

                    // Status Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppColors.kPrimary : AppColors.kDisabled,
                            ),
                          ),
                          Text(
                            status['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                                  : AppColors.kDisabled,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Check
                    if (isCompleted)
                      Icon(Icons.check, color: AppColors.kSuccess, size: 20),
                  ],
                ),

                // Connector Line
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    width: 2,
                    height: 30,
                    color: isCompleted ? AppColors.kSuccess : AppColors.kDisabled.withValues(alpha: 0.3),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final address = orderData!['address'] as Map<String, dynamic>?;
    if (address == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                ),
                child: Icon(Icons.location_on, color: AppColors.kAccent, size: 20),
              ),
              const SizedBox(width: AppDimens.kPaddingMedium),
              Text(
                'Delivery Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),

          Text(
            address['label'] ?? 'Delivery Address',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${address['country'] ?? ''}, ${address['city'] ?? ''}\n${address['street'] ?? ''}\n${address['details'] ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = orderData!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),

          ...items.map((item) {
            final itemData = item as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                      color: AppColors.kBackground,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                      child: Image.network(
                        itemData['image'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: AppColors.kText,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimens.kPaddingMedium),

                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData['name'] ?? 'Product',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemData['store'] ?? 'Store',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.kAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${itemData['quantity'] ?? 1} × \$${(itemData['price'] ?? 0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Item Total
                  Text(
                    '\$${((itemData['price'] ?? 0) * (itemData['quantity'] ?? 1)).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = orderData!['subtotal'] as double? ?? 0;
    final deliveryFee = orderData!['deliveryFee'] as double? ?? 0;
    final total = orderData!['total'] as double? ?? 0;
    final currency = orderData!['currency'] as String? ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),

          _buildSummaryRow('Subtotal', '$currency ${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: AppDimens.kPaddingSmall),
          _buildSummaryRow('Delivery Fee', '$currency ${deliveryFee.toStringAsFixed(2)}'),
          const Divider(height: AppDimens.kPaddingLarge),
          _buildSummaryRow('Total', '$currency ${total.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          )
              : Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}