// lib/widgets/profile/buyer_profile_header.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class BuyerProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onProfileUpdated;

  const BuyerProfileHeader({
    Key? key,
    required this.user,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberSince = user.createdAt;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            AppColors.kPrimaryDark,
            AppColors.kSecondaryDark,
          ]
              : [
            AppColors.kPrimary,
            AppColors.kSecondary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: user.name != null && user.name!.isNotEmpty
                          ? Container(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            _getInitials(user.name!),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                          : Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimens.kPaddingLarge),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name?.isNotEmpty == true ? user.name! : 'Valued Customer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Email
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Member Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Buyer Account',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit Profile Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // TODO: Navigate to edit profile or show profile options
                        _showProfileOptions(context);
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      tooltip: 'Edit Profile',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Stats Row
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Member Since
                      Expanded(
                        child: _HeaderStatItem(
                          icon: Icons.date_range,
                          label: 'Member Since',
                          value: memberSince != null ? _formatMemberSince(memberSince) : 'Recently',
                        ),
                      ),

                      VerticalDivider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1,
                        width: AppDimens.kPaddingLarge,
                      ),

                      // Total Orders
                      Expanded(
                        child: _HeaderStatItem(
                          icon: Icons.shopping_bag,
                          label: 'Total Orders',
                          value: '0', // This will be updated from the parent
                        ),
                      ),

                      VerticalDivider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1,
                        width: AppDimens.kPaddingLarge,
                      ),

                      // Loyalty Status
                      Expanded(
                        child: _HeaderStatItem(
                          icon: Icons.star,
                          label: 'Status',
                          value: _getBuyerStatus(),
                        ),
                      ),
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

  void _showProfileOptions(BuildContext context) {
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
              'Profile Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: AppColors.kPrimary),
              ),
              title: const Text('Edit Personal Info'),
              subtitle: const Text('Update your name, email, and phone'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RoutePaths.kPersonalInfo);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: AppColors.kAccent),
              ),
              title: const Text('Profile Picture'),
              subtitle: const Text('Add or change your profile photo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement profile picture upload
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile picture upload coming soon!')),
                );
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.privacy_tip, color: AppColors.kSuccess),
              ),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Manage your privacy preferences'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement privacy settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon!')),
                );
              },
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatMemberSince(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getBuyerStatus() {
    // TODO: Implement buyer status logic based on order count, total spent, etc.
    return 'New';
  }
}

class _HeaderStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}