// lib/screens/buyer/buyer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'buyer_discover_page.dart';
import 'cart_page.dart';
import 'buyer_profile_page.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../constants/app_constants.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      print('Current Firebase user: ${currentUser?.uid}');

      if (currentUser != null) {
        print('Attempting to load user data for: ${currentUser.uid}');
        final user = await UserService.getUser(currentUser.uid);
        print('Loaded user: ${user?.toString()}');

        setState(() {
          _currentUser = user;
          _loadingUser = false;
        });
      } else {
        print('No authenticated user found');
        setState(() => _loadingUser = false);
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _loadingUser = false);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: AppColors.kError,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadCurrentUser,
            ),
          ),
        );
      }
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const BuyerDiscoverPage();
      case 1:
        return const CartPage();
      case 2:
        if (_loadingUser) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.kPrimary),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  const Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }
        if (_currentUser == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.kError),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  const Text('Error loading profile'),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  ElevatedButton(
                    onPressed: _loadCurrentUser,
                    style: AppButtonStyles.kPrimary,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return BuyerProfilePage(user: _currentUser!);
      default:
        return const BuyerDiscoverPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _getCurrentPage(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.kPrimary,
          unselectedItemColor: AppColors.kText.withValues(alpha: 0.6),
          backgroundColor: Theme.of(context).cardColor,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Discover'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile'
            ),
          ],
        ),
      ),
    );
  }
}