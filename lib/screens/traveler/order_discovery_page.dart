// lib/screens/traveler/order_discovery_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';

class OrderDiscoveryPage extends StatefulWidget {
  const OrderDiscoveryPage({Key? key}) : super(key: key);

  @override
  State<OrderDiscoveryPage> createState() => _OrderDiscoveryPageState();
}

class _OrderDiscoveryPageState extends State<OrderDiscoveryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> availableOrders = [];
  List<Map<String, dynamic>> myTrips = [];
  bool loading = true;
  String? error;
  String selectedFilter = 'all';

  final filters = [
    {'id': 'all', 'label': 'All Orders', 'icon': Icons.list},
    {'id': 'matching', 'label': 'Matching My Trips', 'icon': Icons.verified},
    {'id': 'high_value', 'label': 'High Value', 'icon': Icons.attach_money},
    {'id': 'urgent', 'label': 'Urgent', 'icon': Icons.schedule},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to discover orders");

      // Load available orders and user's trips concurrently
      final results = await Future.wait([
        _loadAvailableOrders(),
        _loadUserTrips(user.uid),
      ]);

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadAvailableOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'paid')
          .where('travelerId', isNull: true)
          .get();

      availableOrders = snapshot.docs
          // .where((doc) => doc['travelerId'] == null || doc['travelerId'] == '')
          .map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        return data;
      }).toList();

      // Sort by creation date (newest first)
      availableOrders.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _loadUserTrips(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('travelerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      myTrips = snapshot.docs.map((doc) {
        final data = doc.data();
        data['tripId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading trips: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    switch (selectedFilter) {
      case 'matching':
        return _getMatchingOrders();
      case 'high_value':
        return availableOrders.where((order) => (order['total'] as double? ?? 0) >= 100).toList();
      case 'urgent':
        return availableOrders.where((order) {
          final createdAt = order['createdAt'] as Timestamp?;
          if (createdAt == null) return false;
          final daysSinceCreation = DateTime.now().difference(createdAt.toDate()).inDays;
          return daysSinceCreation <= 2;
        }).toList();
      default:
        return availableOrders;
    }
  }

  List<Map<String, dynamic>> _getMatchingOrders() {
    if (myTrips.isEmpty) return [];

    return availableOrders.where((order) {
      final orderAddress = order['address'] as Map<String, dynamic>?;
      if (orderAddress == null) return false;

      final orderCountry = orderAddress['country']?.toString().toLowerCase() ?? '';
      final orderCity = orderAddress['city']?.toString().toLowerCase() ?? '';

      return myTrips.any((trip) {
        final tripTo = trip['to']?.toString().toLowerCase() ?? '';
        return tripTo.contains(orderCountry) || tripTo.contains(orderCity);
      });
    }).toList();
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    // Show trip selection dialog
    final selectedTrip = await _showTripSelectionDialog(order);
    if (selectedTrip == null) return;

    try {
      setState(() => loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to accept orders");

      // Update order with traveler info
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order['orderId'])
          .update({
        'travelerId': user.uid,
        'tripId': selectedTrip['tripId'],
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update trip with order info
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(selectedTrip['tripId'])
          .update({
        'orders': FieldValue.arrayUnion([order['orderId']]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from available orders
      setState(() {
        availableOrders.removeWhere((o) => o['orderId'] == order['orderId']);
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order accepted successfully!'),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
          ),
          action: SnackBarAction(
            label: 'View Trip',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Navigate to trip details
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting order: $e'),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showTripSelectionDialog(Map<String, dynamic> order) async {
    if (myTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to create a trip first to accept orders'),
          backgroundColor: AppColors.kWarning,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Create Trip',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, RoutePaths.kCreateTrip);
            },
          ),
        ),
      );
      return null;
    }

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: const Text('Select Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which trip would you like to assign this order to?'),
            const SizedBox(height: AppDimens.kPaddingMedium),
            ...myTrips.map((trip) => ListTile(
              onTap: () => Navigator.pop(context, trip),
              leading: Icon(Icons.flight_takeoff, color: AppColors.kPrimary),
              title: Text('${trip['from']} → ${trip['to']}'),
              subtitle: Text(_formatTripDate(trip)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
        title: const Text('Discover Orders'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag, size: 20),
                  const SizedBox(width: 8),
                  const Text('Available'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt, size: 20),
                  const SizedBox(width: 8),
                  const Text('Filters'),
                ],
              ),
            ),
          ],
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
          const Text('Loading available orders...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrdersList(),
        _buildFiltersTab(),
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
            Text(
              'Unable to load orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
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

  Widget _buildOrdersList() {
    final filteredOrders = _getFilteredOrders();

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.kPrimary,
      child: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter['id'];
                  return Container(
                    margin: const EdgeInsets.only(right: AppDimens.kPaddingSmall),
                    child: FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedFilter = filter['id'] as String);
                      },
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.kPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(filter['label'] as String),
                        ],
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: AppColors.kPrimary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingMedium),
              itemCount: filteredOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingMedium),
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return Padding(
      padding: AppDimens.kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Options',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.kPaddingLarge),

          ...filters.map((filter) {
            final isSelected = selectedFilter == filter['id'];
            final count = filter['id'] == 'all'
                ? availableOrders.length
                : _getFilteredOrdersForFilter(filter['id'] as String).length;

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.kPrimary.withValues(alpha: 0.1)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(
                  color: isSelected ? AppColors.kPrimary : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? null : AppShadows.kCardShadow,
              ),
              child: ListTile(
                onTap: () {
                  setState(() => selectedFilter = filter['id'] as String);
                  _tabController.animateTo(0); // Switch to orders tab
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.kPrimary
                        : AppColors.kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    filter['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.kPrimary,
                    size: 20,
                  ),
                ),
                title: Text(
                  filter['label'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.kPrimary : null,
                  ),
                ),
                subtitle: Text('$count orders available'),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.kPrimary)
                    : Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          }).toList(),

          const SizedBox(height: AppDimens.kPaddingLarge),

          // Statistics
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('Total Orders', availableOrders.length.toString())),
                    Expanded(child: _buildStatItem('Matching Trips', _getMatchingOrders().length.toString())),
                  ],
                ),
                const SizedBox(height: AppDimens.kPaddingSmall),
                Row(
                  children: [
                    Expanded(child: _buildStatItem('My Active Trips', myTrips.length.toString())),
                    Expanded(child: _buildStatItem('High Value', _getFilteredOrdersForFilter('high_value').length.toString())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.kText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredOrdersForFilter(String filterId) {
    final previousFilter = selectedFilter;
    selectedFilter = filterId;
    final result = _getFilteredOrders();
    selectedFilter = previousFilter;
    return result;
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;

    switch (selectedFilter) {
      case 'matching':
        title = 'No Matching Orders';
        subtitle = 'No orders match your current trips. Try checking all orders or create more trips.';
        icon = Icons.search_off;
        break;
      case 'high_value':
        title = 'No High Value Orders';
        subtitle = 'No orders over \$100 available right now. Check back later!';
        icon = Icons.monetization_on_outlined;
        break;
      case 'urgent':
        title = 'No Urgent Orders';
        subtitle = 'No urgent orders available. Great job keeping up!';
        icon = Icons.schedule;
        break;
      default:
        title = 'No Orders Available';
        subtitle = 'No delivery requests available right now. Check back later for new opportunities!';
        icon = Icons.shopping_bag_outlined;
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
            const SizedBox(height: AppDimens.kPaddingLarge),
            if (selectedFilter != 'all')
              ElevatedButton(
                onPressed: () => setState(() => selectedFilter = 'all'),
                style: AppButtonStyles.kPrimary,
                child: const Text('View All Orders'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final address = order['address'] as Map<String, dynamic>?;
    final total = order['total'] as double? ?? 0;
    final currency = order['currency'] as String? ?? 'USD';
    final createdAt = order['createdAt'] as Timestamp?;

    // Check if order matches user's trips
    final isMatching = _getMatchingOrders().contains(order);
    final isHighValue = total >= 100;
    final isUrgent = createdAt != null &&
        DateTime.now().difference(createdAt.toDate()).inDays <= 2;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Padding(
        padding: AppDimens.kCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order['orderId']?.substring(0, 8) ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kPrimary,
                    ),
                  ),
                ),
                if (isMatching)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MATCH',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isHighValue)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.kWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'HIGH',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.kWarning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isUrgent)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.kError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.kError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Items preview
            if (items.isNotEmpty) ...[
              Text(
                'Items (${items.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingSmall),
              ...items.take(2).map((item) {
                final itemData = item as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Qty: ${itemData['quantity'] ?? 1}',
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
              if (items.length > 2)
                Text(
                  '+${items.length - 2} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.kAccent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: AppDimens.kPaddingMedium),
            ],

            // Delivery address
            if (address != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.kAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery to:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.kText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${address['country'] ?? ''}, ${address['city'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingMedium),
            ],

            // Bottom row with total and accept button
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _acceptOrder(order),
                  style: AppButtonStyles.kPrimarySmall,
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTripDate(Map<String, dynamic> trip) {
    final departDate = (trip['departDate'] as Timestamp?)?.toDate();
    if (departDate == null) return 'Date not set';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[departDate.month - 1]} ${departDate.day}, ${departDate.year}';
  }
}