// lib/screens/earnings_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({Key? key}) : super(key: key);

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Data
  double totalEarnings = 0.0;
  double pendingEarnings = 0.0;
  double availableBalance = 0.0;
  double withdrawnAmount = 0.0;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> completedOrders = [];
  Map<String, double> monthlyEarnings = {};

  // State
  bool loading = true;
  String? error;
  bool withdrawing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to view earnings");

      // Load traveler's orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('travelerId', isEqualTo: user.uid)
          .get();

      // Load withdrawal history
      final withdrawalsSnapshot = await FirebaseFirestore.instance
          .collection('withdrawals')
          .where('travelerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _calculateEarnings(ordersSnapshot.docs, withdrawalsSnapshot.docs);
      _buildTransactionHistory(ordersSnapshot.docs, withdrawalsSnapshot.docs);

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _calculateEarnings(List<QueryDocumentSnapshot> orders, List<QueryDocumentSnapshot> withdrawals) {
    double total = 0.0;
    double pending = 0.0;
    double withdrawn = 0.0;
    Map<String, double> monthly = {};
    List<Map<String, dynamic>> completed = [];

    // Calculate earnings from orders
    for (final doc in orders) {
      final order = doc.data() as Map<String, dynamic>;
      final status = order['status'] as String;
      final reward = (order['reward'] as num?)?.toDouble() ?? 0.0;
      final total_amount = (order['total'] as num?)?.toDouble() ?? 0.0;

      // Calculate commission (let's say 10% of order total as default reward)
      final commission = reward > 0 ? reward : total_amount * 0.10;

      if (status == 'delivered') {
        total += commission;
        completed.add({
          'orderId': doc.id,
          'amount': commission,
          'orderTotal': total_amount,
          'deliveredAt': order['deliveredAt'],
          'status': status,
        });

        // Group by month for analytics
        final deliveredAt = (order['deliveredAt'] as Timestamp?)?.toDate();
        if (deliveredAt != null) {
          final monthKey = '${deliveredAt.year}-${deliveredAt.month.toString().padLeft(2, '0')}';
          monthly[monthKey] = (monthly[monthKey] ?? 0.0) + commission;
        }
      } else if (status == 'shipped' || status == 'purchased' || status == 'accepted') {
        pending += commission;
      }
    }

    // Calculate withdrawn amount
    for (final doc in withdrawals) {
      final withdrawal = doc.data() as Map<String, dynamic>;
      if (withdrawal['status'] == 'completed') {
        withdrawn += (withdrawal['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    setState(() {
      totalEarnings = total;
      pendingEarnings = pending;
      withdrawnAmount = withdrawn;
      availableBalance = total - withdrawn;
      monthlyEarnings = monthly;
      completedOrders = completed;
    });
  }

  void _buildTransactionHistory(List<QueryDocumentSnapshot> orders, List<QueryDocumentSnapshot> withdrawals) {
    List<Map<String, dynamic>> allTransactions = [];

    // Add earnings from completed orders
    for (final doc in orders) {
      final order = doc.data() as Map<String, dynamic>;
      if (order['status'] == 'delivered') {
        final deliveredAt = (order['deliveredAt'] as Timestamp?)?.toDate();
        final reward = (order['reward'] as num?)?.toDouble() ?? 0.0;
        final total_amount = (order['total'] as num?)?.toDouble() ?? 0.0;
        final commission = reward > 0 ? reward : total_amount * 0.10;

        allTransactions.add({
          'id': doc.id,
          'type': 'earning',
          'description': 'Order #${doc.id.substring(0, 8)} delivered',
          'amount': commission,
          'date': deliveredAt ?? DateTime.now(),
          'status': 'completed',
        });
      }
    }

    // Add withdrawals
    for (final doc in withdrawals) {
      final withdrawal = doc.data() as Map<String, dynamic>;
      final createdAt = (withdrawal['createdAt'] as Timestamp?)?.toDate();

      allTransactions.add({
        'id': doc.id,
        'type': 'withdrawal',
        'description': 'Withdrawal to ${withdrawal['method'] ?? 'bank account'}',
        'amount': -((withdrawal['amount'] as num?)?.toDouble() ?? 0.0),
        'date': createdAt ?? DateTime.now(),
        'status': withdrawal['status'] ?? 'pending',
      });
    }

    // Sort by date (newest first)
    allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      transactions = allTransactions.take(20).toList(); // Show last 20 transactions
    });
  }

  Future<void> _requestWithdrawal() async {
    if (availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available balance to withdraw')),
      );
      return;
    }

    final amount = await _showWithdrawalDialog();
    if (amount == null || amount <= 0) return;

    if (amount > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds available balance')),
      );
      return;
    }

    setState(() => withdrawing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('withdrawals').add({
        'travelerId': user!.uid,
        'amount': amount,
        'method': 'bank_transfer', // Could be dynamic
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Withdrawal request submitted successfully'),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
          ),
        ),
      );

      await _loadEarningsData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting withdrawal: $e'),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => withdrawing = false);
    }
  }

  Future<double?> _showWithdrawalDialog() async {
    final controller = TextEditingController();
    return await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: const Text('Request Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available balance: \$${availableBalance.toStringAsFixed(2)}'),
            const SizedBox(height: AppDimens.kPaddingMedium),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to withdraw',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            style: AppButtonStyles.kPrimary,
            child: const Text('Request'),
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
        title: const Text('My Earnings'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadEarningsData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Analytics'),
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
          const Text('Loading earnings data...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (error != null) return _buildError();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTransactionsTab(),
        _buildAnalyticsTab(),
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
              'Unable to load earnings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadEarningsData,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.kPrimary,
      child: SingleChildScrollView(
        padding: AppDimens.kScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Cards
            Row(
              children: [
                Expanded(
                  child: _EarningsCard(
                    title: 'Total Earned',
                    amount: totalEarnings,
                    color: AppColors.kSuccess,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: _EarningsCard(
                    title: 'Available',
                    amount: availableBalance,
                    color: AppColors.kPrimary,
                    icon: Icons.monetization_on,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            Row(
              children: [
                Expanded(
                  child: _EarningsCard(
                    title: 'Pending',
                    amount: pendingEarnings,
                    color: AppColors.kWarning,
                    icon: Icons.hourglass_top,
                  ),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: _EarningsCard(
                    title: 'Withdrawn',
                    amount: withdrawnAmount,
                    color: AppColors.kInfo,
                    icon: Icons.credit_score,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Withdrawal Section
            Container(
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
                      Icon(Icons.account_balance, color: AppColors.kPrimary),
                      const SizedBox(width: AppDimens.kPaddingSmall),
                      Text(
                        'Withdraw Earnings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  Text(
                    'Available for withdrawal: \$${availableBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingSmall),
                  Text(
                    'Withdrawals are processed within 2-3 business days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (availableBalance > 0 && !withdrawing) ? _requestWithdrawal : null,
                      icon: withdrawing
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                          : const Icon(Icons.account_balance),
                      label: withdrawing
                          ? const Text('Processing...')
                          : const Text('Request Withdrawal'),
                      style: AppButtonStyles.kPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Recent Completed Orders
            if (completedOrders.isNotEmpty) ...[
              Text(
                'Recent Completed Orders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingMedium),
              ...completedOrders.take(5).map((order) => Container(
                margin: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
                padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.kSuccess,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: AppDimens.kPaddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['orderId'].substring(0, 8)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Order value: \$${order['orderTotal'].toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+\$${order['amount'].toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.kSuccess,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Commission',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.kSuccess,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (transactions.isEmpty) {
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
                  Icons.receipt_long,
                  size: 60,
                  color: AppColors.kAccent,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingLarge),
              Text(
                'No Transactions Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingSmall),
              const Text(
                'Complete your first delivery to start earning!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.kPrimary,
      child: ListView.separated(
        padding: AppDimens.kScreenPadding,
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingSmall),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _TransactionTile(transaction: transaction);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.kPrimary,
      child: SingleChildScrollView(
        padding: AppDimens.kScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Earnings Chart
            Container(
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
                    'Monthly Earnings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingLarge),
                  if (monthlyEarnings.isEmpty)
                    Center(
                      child: Text(
                        'No earnings data available yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: _SimpleBarChart(data: monthlyEarnings),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Statistics
            Container(
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
                    'Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  _StatRow('Completed Orders', completedOrders.length.toString()),
                  _StatRow('Average per Order', completedOrders.isNotEmpty
                      ? '\$${(totalEarnings / completedOrders.length).toStringAsFixed(2)}'
                      : '\$0.00'),
                  _StatRow('Commission Rate', '10%'),
                  _StatRow('Total Withdrawals', withdrawnAmount > 0 ? '${(withdrawnAmount / totalEarnings * 100).toStringAsFixed(1)}%' : '0%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _StatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _EarningsCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isEarning = transaction['type'] == 'earning';
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as DateTime;
    final status = transaction['status'] as String;

    Color statusColor;
    if (status == 'completed') {
      statusColor = isEarning ? AppColors.kSuccess : AppColors.kInfo;
    } else if (status == 'pending') {
      statusColor = AppColors.kWarning;
    } else {
      statusColor = AppColors.kError;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isEarning ? Icons.trending_up : Icons.trending_down,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.kPaddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount >= 0 ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Map<String, double> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Container();

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sortedEntries.map((entry) {
        final height = (entry.value / maxValue) * 150;
        final month = entry.key.split('-')[1];

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\${entry.value.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.kPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMonthName(int.parse(month)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}