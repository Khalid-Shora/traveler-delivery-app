// lib/screens/auth/landing_page.dart - PRODUCTION VERSION

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppDimens.kScreenPadding,
          child: Column(
            children: [
              // Spacer to push content to center
              const Spacer(flex: 2),

              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: AppColors.kPrimary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: AppColors.kPrimary,
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingXLarge),

              // App Title
              Text(
                "Traveler Delivery",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.kPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // App Subtitle/Description
              Text(
                "Shop internationally with trusted travelers",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimens.kPaddingSmall),

              // Features highlight
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeatureBadge(
                    icon: Icons.verified_user,
                    label: 'Verified',
                    color: AppColors.kSuccess,
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  _FeatureBadge(
                    icon: Icons.security,
                    label: 'Secure',
                    color: AppColors.kInfo,
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  _FeatureBadge(
                    icon: Icons.flash_on,
                    label: 'Fast',
                    color: AppColors.kWarning,
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: AppButtonStyles.kPrimary.copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: AppButtonStyles.kOutlined.copyWith(
                    minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const Spacer(),

              // Footer
              Text(
                '© 2024 Traveler Delivery. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.kPaddingMedium,
        vertical: AppDimens.kPaddingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}