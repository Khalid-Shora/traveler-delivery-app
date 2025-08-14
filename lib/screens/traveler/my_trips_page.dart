// lib/screens/my_trips_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import 'create_trip_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({Key? key}) : super(key: key);

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> trips = [];
  bool loading = true;
  String? error;

  final tripStatuses = ['active', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Safe padding that clears bottom nav + FAB comfortably
  EdgeInsets _listSafePadding(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const extraForFab = 96.0; // FAB + spacing
    return EdgeInsets.fromLTRB(
      AppDimens.kPaddingLarge,
      AppDimens.kPaddingLarge,
      AppDimens.kPaddingLarge,
      bottomInset + kBottomNavigationBarHeight + extraForFab,
    );
  }

  Future<void> _loadTrips() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to view your trips");

      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('travelerId', isEqualTo: user.uid)
          .get();

      setState(() {
        trips = snapshot.docs.map((doc) {
          final data = doc.data();
          data['tripId'] = doc.id;
          return data;
        }).toList();

        // Sort trips in memory by createdAt (newest first)
        trips.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
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

  List<Map<String, dynamic>> _getTripsForStatus(String status) {
    return trips.where((trip) => trip['status'] == status).toList();
  }

  Future<void> _createTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripPage()),
    );
    if (result == true) {
      _loadTrips();
    }
  }

  Future<void> _editTrip(Map<String, dynamic> trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTripPage(existingTrip: trip),
      ),
    );
    if (result == true) {
      _loadTrips();
    }
  }

  Future<void> _updateTripStatus(String tripId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        final tripIndex = trips.indexWhere((trip) => trip['tripId'] == tripId);
        if (tripIndex != -1) {
          trips[tripIndex]['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${newStatus == 'cancelled' ? 'cancelled' : 'updated'} successfully'),
          backgroundColor: newStatus == 'cancelled' ? AppColors.kWarning : AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating trip: $e'),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTripActions(Map<String, dynamic> trip) {
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
              'Trip Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            // Edit Trip
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: AppColors.kPrimary),
              ),
              title: const Text('Edit Trip'),
              subtitle: const Text('Update trip details'),
              onTap: () {
                Navigator.pop(context);
                _editTrip(trip);
              },
            ),

            // Mark as Completed (only for active trips)
            if (trip['status'] == 'active')
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.kSuccess),
                ),
                title: const Text('Mark as Completed'),
                subtitle: const Text('Trip has been completed'),
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmDialog(
                    'Complete Trip',
                    'Are you sure you want to mark this trip as completed?',
                        () => _updateTripStatus(trip['tripId'], 'completed'),
                  );
                },
              ),

            // Cancel Trip (only for active trips)
            if (trip['status'] == 'active')
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kError.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cancel, color: AppColors.kError),
                ),
                title: const Text('Cancel Trip'),
                subtitle: const Text('Trip will be cancelled'),
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmDialog(
                    'Cancel Trip',
                    'Are you sure you want to cancel this trip? This action cannot be undone.',
                        () => _updateTripStatus(trip['tripId'], 'cancelled'),
                  );
                },
              ),

            const SizedBox(height: AppDimens.kPaddingMedium),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Cancel') ? AppColors.kError : AppColors.kSuccess,
            ),
            child: Text(title.contains('Cancel') ? 'Cancel Trip' : 'Complete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _getTripsForStatus('active').length;
    final completedCount = _getTripsForStatus('completed').length;
    final cancelledCount = _getTripsForStatus('cancelled').length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _TabWithCounter(label: 'Active', count: activeCount, color: AppColors.kSuccess),
            _TabWithCounter(label: 'Completed', count: completedCount, color: AppColors.kPrimary),
            _TabWithCounter(label: 'Cancelled', count: cancelledCount, color: AppColors.kWarning),
          ],
          labelColor: AppColors.kPrimary,
          unselectedLabelColor: AppColors.kText,
          indicatorColor: AppColors.kPrimary,
        ),
      ),
      body: SafeArea(
        bottom: false, // we'll handle bottom padding ourselves
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? _buildLoading()
                  : (error != null
                  ? _buildError()
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildTripsList('active'),
                  _buildTripsList('completed'),
                  _buildTripsList('cancelled'),
                ],
              )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTrip,
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppDimens.kPaddingMedium),
          Text('Loading your trips...'),
        ],
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.kError),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Unable to load trips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadTrips,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(String status) {
    final filteredTrips = _getTripsForStatus(status);

    if (filteredTrips.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppColors.kPrimary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listSafePadding(context),
        itemCount: filteredTrips.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingMedium),
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle, buttonText;
    IconData icon;

    switch (status) {
      case 'active':
        title = 'No Active Trips';
        subtitle = 'Create your first trip to start earning from deliveries';
        buttonText = 'Create Trip';
        icon = Icons.flight_takeoff;
        break;
      case 'completed':
        title = 'No Completed Trips';
        subtitle = 'Your completed trips will appear here';
        buttonText = 'Create New Trip';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        title = 'No Cancelled Trips';
        subtitle = 'Your cancelled trips will appear here';
        buttonText = 'Create New Trip';
        icon = Icons.cancel_outlined;
        break;
      default:
        title = 'No Trips';
        subtitle = 'Start creating trips';
        buttonText = 'Create Trip';
        icon = Icons.flight;
    }

    // Use a scrollable ListView so there's never a bottom overflow
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _listSafePadding(context),
      children: [
        const SizedBox(height: 32),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(Icons.flight_takeoff, size: 60, color: AppColors.kAccent),
        ),
        const SizedBox(height: AppDimens.kPaddingLarge),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimens.kPaddingSmall),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppDimens.kPaddingLarge),
        Center(
          child: ElevatedButton.icon(
            onPressed: _createTrip,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
            style: AppButtonStyles.kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = trip['status'] as String? ?? '';
    final from = trip['from'] as String? ?? '—';
    final to = trip['to'] as String? ?? '—';
    final departDate = (trip['departDate'] as Timestamp?)?.toDate();
    final arriveDate = (trip['arriveDate'] as Timestamp?)?.toDate();
    final availableWeight = (trip['availableWeight'] as num?)?.toDouble();
    final orders = trip['orders'] as List? ?? [];

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'active':
        statusColor = AppColors.kSuccess;
        statusIcon = Icons.flight_takeoff;
        break;
      case 'completed':
        statusColor = AppColors.kPrimary;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppColors.kWarning;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.kDisabled;
        statusIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: InkWell(
        onTap: () => _showTripActions(trip),
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        child: Padding(
          padding: AppDimens.kCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$from → $to',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // Trip details
              Row(
                children: [
                  Expanded(
                    child: _buildTripDetail(
                      Icons.calendar_today,
                      'Departure',
                      departDate != null ? _formatDate(departDate) : 'Not set',
                    ),
                  ),
                  if (arriveDate != null) ...[
                    const SizedBox(width: AppDimens.kPaddingSmall),
                    Expanded(
                      child: _buildTripDetail(
                        Icons.event,
                        'Arrival',
                        _formatDate(arriveDate),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _buildTripDetail(
                      Icons.luggage,
                      'Capacity',
                      '${availableWeight?.toStringAsFixed(1) ?? '0'} kg',
                    ),
                  ),
                  const SizedBox(width: AppDimens.kPaddingSmall),
                  Expanded(
                    child: _buildTripDetail(
                      Icons.shopping_bag,
                      'Orders',
                      '${orders.length} active',
                    ),
                  ),
                ],
              ),

              if (trip['notes'] != null && (trip['notes'] as String).isNotEmpty) ...[
                const SizedBox(height: AppDimens.kPaddingMedium),
                Container(
                  padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.kBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['notes'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildTripDetail(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.kAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _TabWithCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabWithCounter({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // kTextTabBarHeight is the default TabBar height (typically 46.0)
    // We keep a tiny inner padding so content never exceeds it.
    return Tab(
      child: SizedBox(
        height: kTextTabBarHeight - 4, // constrain to avoid 1px overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, textAlign: TextAlign.center),
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2), // smaller than before
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

