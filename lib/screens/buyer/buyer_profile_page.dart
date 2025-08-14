// lib/screens/buyer/buyer_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/profile/buyer_profile_header.dart';
import '../../widgets/traveler/verification_badge.dart';
import '../personal_info_page.dart';
import '../addresses_page.dart';
import '../payment_methods_page.dart';

class BuyerProfilePage extends StatefulWidget {
  final UserModel user;

  const BuyerProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  UserModel? _currentUser;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _savedCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadBuyerData();
  }

  Future<void> _loadBuyerData() async {
    setState(() => _loading = true);

    try {
      await Future.wait([
        _loadBuyerStats(),
        _loadRecentOrders(),
        _loadSavedCards(),
        _refreshUserData(),
      ]);
    } catch (e) {
      print('Error loading buyer data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBuyerStats() async {
    try {
      final uid = _currentUser!.uid;

      // Load orders as buyer
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .get();

      // Load cart
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(uid)
          .get();

      // Load payment methods
      final paymentMethodsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payment_methods')
          .get();

      // Calculate stats
      final totalOrders = ordersSnapshot.docs.length;
      final deliveredOrders = ordersSnapshot.docs.where((doc) => doc.data()['status'] == 'delivered').length;
      final pendingOrders = ordersSnapshot.docs.where((doc) {
        final status = doc.data()['status'];
        return status == 'paid' || status == 'processing' || status == 'shipped' || status == 'accepted' || status == 'purchased';
      }).length;

      double totalSpent = 0.0;
      double averageOrderValue = 0.0;

      for (final doc in ordersSnapshot.docs) {
        final order = doc.data();
        if (order['status'] == 'delivered' || order['status'] == 'paid') {
          final total = (order['total'] as num?)?.toDouble() ?? 0.0;
          totalSpent += total;
        }
      }

      if (totalOrders > 0) {
        averageOrderValue = totalSpent / totalOrders;
      }

      final cartItems = cartSnapshot.exists
          ? (cartSnapshot.data()?['items'] as List?)?.length ?? 0
          : 0;

      final savedCards = paymentMethodsSnapshot.docs.length;
      final savedAddresses = _currentUser!.addresses?.length ?? 0;

      setState(() {
        _stats = {
          'totalOrders': totalOrders,
          'deliveredOrders': deliveredOrders,
          'pendingOrders': pendingOrders,
          'totalSpent': totalSpent,
          'averageOrderValue': averageOrderValue,
          'cartItems': cartItems,
          'savedCards': savedCards,
          'savedAddresses': savedAddresses,
          'satisfactionRate': totalOrders > 0 ? (deliveredOrders / totalOrders * 100) : 0.0,
        };
      });
    } catch (e) {
      print('Error loading buyer stats: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final uid = _currentUser!.uid;

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentOrders = ordersSnapshot.docs.map((doc) {
          final data = doc.data();
          data['orderId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error loading recent orders: $e');
    }
  }

  Future<void> _loadSavedCards() async {
    try {
      final uid = _currentUser!.uid;

      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payment_methods')
          .get();

      setState(() {
        _savedCards = cardsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error loading saved cards: $e');
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  void _onProfileUpdated() {
    _loadBuyerData();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kError),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutePaths.kLanding,
                (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppColors.kError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadBuyerData,
        child: CustomScrollView(
          slivers: [
            // Enhanced Header
            SliverToBoxAdapter(
              child: BuyerProfileHeader(
                user: _currentUser!,
                onProfileUpdated: _onProfileUpdated,
              ),
            ),

            // Profile Content
            SliverToBoxAdapter(
              child: Padding(
                padding: AppDimens.kScreenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Quick Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStatCard(
                            title: 'Total Orders',
                            value: '${_stats['totalOrders'] ?? 0}',
                            icon: Icons.shopping_bag,
                            color: AppColors.kPrimary,
                            onTap: () => _navigateToOrderHistory(),
                          ),
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        Expanded(
                          child: _QuickStatCard(
                            title: 'Cart Items',
                            value: '${_stats['cartItems'] ?? 0}',
                            icon: Icons.shopping_cart,
                            color: AppColors.kAccent,
                            onTap: () => Navigator.pushNamed(context, RoutePaths.kCart),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.kPaddingMedium),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickStatCard(
                            title: 'Total Spent',
                            value: '\$${(_stats['totalSpent'] ?? 0.0).toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: AppColors.kSuccess,
                            onTap: () => _navigateToOrderHistory(),
                          ),
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        Expanded(
                          child: _QuickStatCard(
                            title: 'Delivered',
                            value: '${_stats['deliveredOrders'] ?? 0}',
                            icon: Icons.check_circle,
                            color: AppColors.kInfo,
                            onTap: () => _navigateToOrderHistory(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Recent Orders Section
                    if (_recentOrders.isNotEmpty) ...[
                      _buildRecentOrdersSection(),
                      const SizedBox(height: AppDimens.kPaddingLarge),
                    ],

                    // Shopping Menu
                    _buildShoppingMenu(),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Account Settings Menu
                    _buildAccountMenu(),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kError,
                          side: BorderSide(color: AppColors.kError),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.kPaddingXLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimary,
              ),
            ),
            TextButton(
              onPressed: _navigateToOrderHistory,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.kPaddingMedium),

        ...(_recentOrders.take(3).map((order) {
          final status = order['status'] as String;
          final total = (order['total'] as num?)?.toDouble() ?? 0.0;
          final items = order['items'] as List<dynamic>? ?? [];
          final createdAt = (order['createdAt'] as Timestamp?)?.toDate();

          Color statusColor;
          IconData statusIcon;
          switch (status) {
            case 'delivered':
              statusColor = AppColors.kSuccess;
              statusIcon = Icons.check_circle;
              break;
            case 'shipped':
              statusColor = AppColors.kInfo;
              statusIcon = Icons.local_shipping;
              break;
            case 'paid':
            case 'accepted':
            case 'purchased':
              statusColor = AppColors.kWarning;
              statusIcon = Icons.hourglass_top;
              break;
            default:
              statusColor = AppColors.kDisabled;
              statusIcon = Icons.help;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
            padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order['orderId']?.substring(0, 8) ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppDimens.kPaddingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${items.length} item${items.length != 1 ? 's' : ''} • ${createdAt != null ? _formatDate(createdAt) : 'Unknown date'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.kPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(statusIcon, color: statusColor, size: 16),
                  ],
                ),
              ],
            ),
          );
        })).toList(),
      ],
    );
  }

  Widget _buildShoppingMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopping',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.kPaddingMedium),

        _ProfileMenuItem(
          icon: Icons.shopping_bag,
          title: 'My Orders',
          subtitle: 'Track your orders and delivery status',
          trailing: _stats['pendingOrders'] != null && _stats['pendingOrders'] > 0
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_stats['pendingOrders']} Pending',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.kWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : null,
          onTap: () => _navigateToOrderHistory(),
        ),

        _ProfileMenuItem(
          icon: Icons.shopping_cart,
          title: 'My Cart',
          subtitle: 'View and manage your cart items',
          trailing: _stats['cartItems'] != null && _stats['cartItems'] > 0
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_stats['cartItems']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.kAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : null,
          onTap: () => Navigator.pushNamed(context, RoutePaths.kCart),
        ),

        _ProfileMenuItem(
          icon: Icons.favorite,
          title: 'Wishlist',
          subtitle: 'Save items for later',
          onTap: () {
            // TODO: Implement wishlist
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wishlist feature coming soon!')),
            );
          },
        ),

        _ProfileMenuItem(
          icon: Icons.explore,
          title: 'Discover Products',
          subtitle: 'Find products from international stores',
          onTap: () => Navigator.pushNamed(context, RoutePaths.kBuyerDiscover),
        ),
      ],
    );
  }

  Widget _buildAccountMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.kPaddingMedium),

        _ProfileMenuItem(
          icon: Icons.person,
          title: 'Personal Information',
          subtitle: 'Manage your profile details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
          ).then((_) => _onProfileUpdated()),
        ),

        _ProfileMenuItem(
          icon: Icons.location_on,
          title: 'Delivery Addresses',
          subtitle: 'Manage your delivery addresses',
          trailing: _stats['savedAddresses'] != null && _stats['savedAddresses'] > 0
              ? Text(
            '${_stats['savedAddresses']} saved',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.kAccent,
              fontWeight: FontWeight.w600,
            ),
          )
              : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddressesPage()),
          ).then((_) => _onProfileUpdated()),
        ),

        _ProfileMenuItem(
          icon: Icons.payment,
          title: 'Payment Methods',
          subtitle: 'Manage your cards and payment options',
          trailing: _stats['savedCards'] != null && _stats['savedCards'] > 0
              ? Text(
            '${_stats['savedCards']} saved',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.kSuccess,
              fontWeight: FontWeight.w600,
            ),
          )
              : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentMethodsPage()),
          ).then((_) => _onProfileUpdated()),
        ),

        _ProfileMenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Configure your notification preferences',
          onTap: () => Navigator.pushNamed(context, RoutePaths.kNotifications),
        ),

        _ProfileMenuItem(
          icon: Icons.language,
          title: 'Language & Region',
          subtitle: 'Change app language and regional settings',
          onTap: () => Navigator.pushNamed(context, RoutePaths.kLanguageSettings),
        ),

        _ProfileMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () => Navigator.pushNamed(context, RoutePaths.kContactUs),
        ),

        _ProfileMenuItem(
          icon: Icons.privacy_tip,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // TODO: Implement privacy settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon!')),
            );
          },
        ),
      ],
    );
  }

  void _navigateToOrderHistory() {
    // TODO: Implement order history page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order history page coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.kPrimary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.kPaddingLarge,
          vertical: AppDimens.kPaddingSmall,
        ),
      ),
    );
  }
}