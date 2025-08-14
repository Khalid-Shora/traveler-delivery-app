// lib/screens/traveler/traveler_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'order_discovery_page.dart';
import 'my_trips_page.dart';
import 'order_management_page.dart';
import 'earnings_page.dart';
import 'traveler_profile_page.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../constants/app_constants.dart';

class TravelerHomeScreen extends StatefulWidget {
  const TravelerHomeScreen({Key? key}) : super(key: key);

  @override
  State<TravelerHomeScreen> createState() => _TravelerHomeScreenState();
}

class _TravelerHomeScreenState extends State<TravelerHomeScreen> {
  int _currentIndex = 0;

  bool _loadingUser = true;
  String? _userError;
  UserModel? _currentUser;

  // Non-profile tabs are created once and kept alive by IndexedStack
  final _staticTabs = const [
    OrderDiscoveryPage(),
    MyTripsPage(),
    OrderManagementPage(),
    EarningsPage(),
    // index 4 (Profile) is built dynamically to pass the loaded user
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _loadingUser = true;
      _userError = null;
    });

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        _currentUser = null;
        _userError = 'Not signed in.';
      } else {
        final model = await UserService.getUser(fbUser.uid);
        if (!mounted) return;
        if (model == null) {
          _currentUser = null;
          _userError = 'User profile not found.';
        } else {
          _currentUser = model;
        }
      }
    } catch (e) {
      if (!mounted) return;
      _currentUser = null;
      _userError = 'Failed to load profile: $e';
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingUser = false;
      });
    }
  }

  Widget _buildProfileTab() {
    if (_loadingUser) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: AppColors.kPrimary),
              SizedBox(height: AppDimens.kPaddingMedium),
              Text('Loading your profile...'),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.kError),
                const SizedBox(height: AppDimens.kPaddingMedium),
                Text(_userError ?? 'Error loading profile'),
                const SizedBox(height: AppDimens.kPaddingMedium),
                ElevatedButton(
                  onPressed: _loadCurrentUser,
                  style: AppButtonStyles.kPrimary,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Only instantiate the profile page when we have a valid user
    return TravelerProfilePage(user: _currentUser!);
  }

  List<Widget> _tabs() => [
    _staticTabs[0],
    _staticTabs[1],
    _staticTabs[2],
    _staticTabs[3],
    _buildProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.flight_takeoff_outlined),
              selectedIcon: Icon(Icons.flight_takeoff),
              label: 'My Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.monetization_on_outlined),
              selectedIcon: Icon(Icons.monetization_on),
              label: 'Earnings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
