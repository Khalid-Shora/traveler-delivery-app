// lib/screens/traveler/order_management_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> myOrders = [];
  bool loading = true;
  String? error;

  final orderStatuses = [
    {'id': 'accepted', 'title': 'Accepted', 'icon': Icons.check_circle, 'color': AppColors.kSuccess},
    {'id': 'purchased', 'title': 'Purchased', 'icon': Icons.shopping_cart, 'color': AppColors.kInfo},
    {'id': 'shipped', 'title': 'Shipped', 'icon': Icons.local_shipping, 'color': AppColors.kWarning},
    {'id': 'delivered', 'title': 'Delivered', 'icon': Icons.done_all, 'color': AppColors.kPrimary},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to view your orders");

      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('travelerId', isEqualTo: user.uid)
          .get();

      setState(() {
        myOrders = snapshot.docs.map((doc) {
          final data = doc.data();
          data['orderId'] = doc.id;
          return data;
        }).toList();

        // Sort by acceptance date (newest first)
        myOrders.sort((a, b) {
          final aTime = a['acceptedAt'] as Timestamp?;
          final bTime = b['acceptedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getOrdersForStatus(String status) {
    return myOrders.where((order) => order['status'] == status).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'purchased') 'purchasedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'shipped') 'shippedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'delivered') 'deliveredAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        final orderIndex = myOrders.indexWhere((order) => order['orderId'] == orderId);
        if (orderIndex != -1) {
          myOrders[orderIndex]['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as ${newStatus.toLowerCase()}'),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOrderActions(Map<String, dynamic> order) {
    final currentStatus = order['status'] as String;
    final availableActions = _getAvailableActions(currentStatus);

    if (availableActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No actions available for this order')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.kBorderRadiusLarge)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            Text(
              'Order Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),

            Text(
              'Order #${order['orderId']?.substring(0, 8) ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.kText,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            ...availableActions.map((action) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action['icon'], color: action['color']),
              ),
              title: Text(action['title']),
              subtitle: Text(action['description']),
              onTap: () {
                Navigator.pop(context);
                _showStatusConfirmDialog(order['orderId'], action['status'], action['title']);
              },
            )).toList(),

            // Order details button
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info, color: AppColors.kAccent),
              ),
              title: const Text('View Order Details'),
              subtitle: const Text('See complete order information'),
              onTap: () {
                Navigator.pop(context);
                _showOrderDetails(order);
              },
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return [
          {
            'status': 'purchased',
            'title': 'Mark as Purchased',
            'description': 'You have bought the items',
            'icon': Icons.shopping_cart,
            'color': AppColors.kInfo,
          },
        ];
      case 'purchased':
        return [
          {
            'status': 'shipped',
            'title': 'Mark as Shipped',
            'description': 'Items are being shipped to destination',
            'icon': Icons.local_shipping,
            'color': AppColors.kWarning,
          },
        ];
      case 'shipped':
        return [
          {
            'status': 'delivered',
            'title': 'Mark as Delivered',
            'description': 'Items delivered to customer',
            'icon': Icons.done_all,
            'color': AppColors.kPrimary,
          },
        ];
      default:
        return [];
    }
  }

  void _showStatusConfirmDialog(String orderId, String newStatus, String actionTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: Text(actionTitle),
        content: Text('Are you sure you want to update this order status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(orderId, newStatus);
            },
            style: AppButtonStyles.kPrimary,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderDetailSection('Order ID', order['orderId']?.substring(0, 12) ?? 'Unknown'),
                      _buildOrderDetailSection('Status', order['status']?.toUpperCase() ?? 'UNKNOWN'),
                      _buildOrderDetailSection('Total Value', '${order['currency'] ?? 'USD'} ${(order['total'] as double? ?? 0).toStringAsFixed(2)}'),

                      const SizedBox(height: AppDimens.kPaddingMedium),
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.kPaddingSmall),

                      ...(order['items'] as List<dynamic>? ?? []).map((item) {
                        final itemData = item as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
                          padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                          decoration: BoxDecoration(
                            color: AppColors.kBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemData['image'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.kText,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimens.kPaddingSmall),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemData['name'] ?? 'Product',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Qty: ${itemData['quantity'] ?? 1} • \$${(itemData['price'] as double? ?? 0).toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.kText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: AppDimens.kPaddingMedium),

                      // Delivery address
                      if (order['address'] != null) ...[
                        Text(
                          'Delivery Address',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimens.kPaddingSmall),
                        Container(
                          padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.kBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['address']['label'] ?? 'Delivery Address',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order['address']['country'] ?? ''}, ${order['address']['city'] ?? ''}\n${order['address']['street'] ?? ''}\n${order['address']['details'] ?? ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.kText,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.kText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: orderStatuses.map((status) {
            final count = _getOrdersForStatus(status['id'] as String).length;
            return Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status['title'] as String),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status['color'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          labelColor: AppColors.kPrimary,
          unselectedLabelColor: AppColors.kText,
          indicatorColor: AppColors.kPrimary,
        ),
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
          const Text('Loading your orders...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();

    return TabBarView(
      controller: _tabController,
      children: orderStatuses.map((status) => _buildOrdersList(status['id'] as String)).toList(),
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
              'Unable to load orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadOrders,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    final filteredOrders = _getOrdersForStatus(status);

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.kPrimary,
      child: ListView.separated(
        padding: AppDimens.kScreenPadding,
        itemCount: filteredOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingMedium),
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle;
    IconData icon;

    switch (status) {
      case 'accepted':
        title = 'No Accepted Orders';
        subtitle = 'Orders you accept will appear here. Start by discovering available orders!';
        icon = Icons.inbox_outlined;
        break;
      case 'purchased':
        title = 'No Purchased Orders';
        subtitle = 'Mark orders as purchased after you buy the items';
        icon = Icons.shopping_cart_outlined;
        break;
      case 'shipped':
        title = 'No Shipped Orders';
        subtitle = 'Orders being shipped to destination will appear here';
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        title = 'No Delivered Orders';
        subtitle = 'Completed deliveries will appear here. Great work!';
        icon = Icons.done_all;
        break;
      default:
        title = 'No Orders';
        subtitle = 'Orders will appear here';
        icon = Icons.list_alt;
    }

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
              child: Icon(icon, size: 60, color: AppColors.kAccent),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (status == 'accepted') ...[
              const SizedBox(height: AppDimens.kPaddingLarge),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to order discovery
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to Order Discovery')),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Discover Orders'),
                style: AppButtonStyles.kPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final items = order['items'] as List<dynamic>? ?? [];
    final total = order['total'] as double? ?? 0;
    final currency = order['currency'] as String? ?? 'USD';
    final acceptedAt = order['acceptedAt'] as Timestamp?;
    final address = order['address'] as Map<String, dynamic>?;

    final statusInfo = orderStatuses.firstWhere(
          (s) => s['id'] == status,
      orElse: () => {'title': status.toUpperCase(), 'icon': Icons.help, 'color': AppColors.kDisabled},
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: InkWell(
        onTap: () => _showOrderActions(order),
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        child: Padding(
          padding: AppDimens.kCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (statusInfo['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'] as IconData,
                      color: statusInfo['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['orderId']?.substring(0, 8) ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusInfo['title'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusInfo['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, color: AppColors.kText),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // Items summary
              if (items.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.shopping_bag, size: 16, color: AppColors.kAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${items.length} item${items.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.kPaddingSmall),
              ],

              // Delivery address
              if (address != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.kAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${address['country'] ?? ''}, ${address['city'] ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.kText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.kPaddingSmall),
              ],

              // Date
              if (acceptedAt != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.kAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Accepted ${_formatDate(acceptedAt.toDate())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.kText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
              ],

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Value',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.kText,
                        ),
                      ),
                      Text(
                        '$currency ${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_getAvailableActions(status).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Action Required',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}