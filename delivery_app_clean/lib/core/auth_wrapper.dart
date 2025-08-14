// lib/core/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../screens/auth/landing_page.dart';
import '../screens/buyer/buyer_home_screen.dart';
import '../screens/traveler/traveler_home_screen.dart';
import '../screens/auth/complete_profile_screen.dart';

/// Handles authentication state and routes users to appropriate screens
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }

        // User not signed in - show landing page
        if (!snapshot.hasData || snapshot.data == null) {
          return LandingPage();
        }

        // User signed in - check profile completion and role
        return ProfileChecker(user: snapshot.data!);
      },
    );
  }
}

/// Checks if user profile is complete and routes accordingly
class ProfileChecker extends StatelessWidget {
  final User user;

  const ProfileChecker({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // Show loading while checking profile
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }

        // Error state
        if (snapshot.hasError) {
          return AuthErrorScreen(
            error: snapshot.error.toString(),
            onRetry: () {
              // Force rebuild by creating new widget
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
              );
            },
          );
        }

        // No user document found - needs profile completion
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return CompleteProfileScreen(
            uid: user.uid,
            email: user.email,
            name: user.displayName,
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // Check if profile is complete
        if (!_isProfileComplete(userData)) {
          return CompleteProfileScreen(
            uid: user.uid,
            email: user.email ?? userData['email'],
            name: user.displayName ?? userData['name'],
          );
        }

        // Profile complete - route to appropriate home screen
        final role = userData['role'] as String?;
        return _getHomeScreen(role);
      },
    );
  }

  /// Check if user profile has all required fields
  bool _isProfileComplete(Map<String, dynamic> userData) {
    return userData['name'] != null &&
        userData['phone'] != null &&
        userData['role'] != null &&
        userData['name'].toString().trim().isNotEmpty &&
        userData['phone'].toString().trim().isNotEmpty;
  }

  /// Get appropriate home screen based on user role
  Widget _getHomeScreen(String? role) {
    switch (role?.toLowerCase()) {
      case 'buyer':
        return const BuyerHomeScreen();
      case 'traveler':
        return const TravelerHomeScreen();
      default:
      // Default to buyer if role is unclear
        return const BuyerHomeScreen();
    }
  }
}

/// Loading screen shown while checking authentication state
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.local_shipping,
                size: 40,
                color: AppColors.kPrimary,
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Loading indicator
            CircularProgressIndicator(
              color: AppColors.kPrimary,
              strokeWidth: 3,
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Loading text
            Text(
              'Traveler Delivery',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimary,
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingSmall),

            Text(
              'Loading your account...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication checking fails
class AuthErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const AuthErrorScreen({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppDimens.kScreenPadding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.kError,
                ),

                const SizedBox(height: AppDimens.kPaddingLarge),

                // Error title
                Text(
                  'Connection Error',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.kError,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Error message
                Text(
                  'Unable to verify your account. Please check your internet connection and try again.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.kPaddingSmall),

                // Technical error (collapsible)
                ExpansionTile(
                  title: Text(
                    'Technical Details',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.kText,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.kError,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.kPaddingLarge),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: AppButtonStyles.kPrimary,
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Sign out option
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}