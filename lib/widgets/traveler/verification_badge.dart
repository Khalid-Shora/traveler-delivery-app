// lib/widgets/traveler/verification_badge.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

enum VerificationStatus {
  notStarted,
  pending,
  approved,
  rejected,
  expired,
}

enum BadgeSize {
  small,   // 16x16 - For lists, cards
  medium,  // 24x24 - For profiles, headers
  large,   // 32x32 - For prominent display
  xlarge,  // 48x48 - For status pages
}

enum BadgeStyle {
  icon,     // Just the icon
  iconText, // Icon with text
  chip,     // Chip style with background
  card,     // Full card with details
}

// Extension to convert string status to enum - MOVED TO TOP
extension VerificationStatusExtension on String {
  VerificationStatus toVerificationStatus() {
    switch (this.toLowerCase()) {
      case 'approved':
        return VerificationStatus.approved;
      case 'pending':
        return VerificationStatus.pending;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'expired':
        return VerificationStatus.expired;
      default:
        return VerificationStatus.notStarted;
    }
  }
}

class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final BadgeSize size;
  final BadgeStyle style;
  final VoidCallback? onTap;
  final bool showTooltip;

  const VerificationBadge({
    Key? key,
    required this.status,
    this.size = BadgeSize.medium,
    this.style = BadgeStyle.icon,
    this.onTap,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BadgeStyle.icon:
        return _buildIcon(context);
      case BadgeStyle.iconText:
        return _buildIconText(context);
      case BadgeStyle.chip:
        return _buildChip(context);
      case BadgeStyle.card:
        return _buildCard(context);
    }
  }

  Widget _buildIcon(BuildContext context) {
    final config = _getStatusConfig();
    final iconSize = _getIconSize();

    Widget icon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(iconSize / 2),
        boxShadow: status == VerificationStatus.approved ? [
          BoxShadow(
            color: config.color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Icon(
        config.icon,
        color: Colors.white,
        size: iconSize * 0.6,
      ),
    );

    if (showTooltip && config.tooltip.isNotEmpty) {
      icon = Tooltip(
        message: config.tooltip,
        child: icon,
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: icon)
        : icon;
  }

  Widget _buildIconText(BuildContext context) {
    final config = _getStatusConfig();
    final iconSize = _getIconSize();
    final theme = Theme.of(context);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: config.color,
            borderRadius: BorderRadius.circular(iconSize / 2),
          ),
          child: Icon(
            config.icon,
            color: Colors.white,
            size: iconSize * 0.6,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          config.label,
          style: _getTextStyle(theme).copyWith(
            color: config.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (showTooltip && config.tooltip.isNotEmpty) {
      content = Tooltip(
        message: config.tooltip,
        child: content,
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: content)
        : content;
  }

  Widget _buildChip(BuildContext context) {
    final config = _getStatusConfig();
    final iconSize = _getIconSize();
    final theme = Theme.of(context);

    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == BadgeSize.small ? 8 : 12,
        vertical: size == BadgeSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: config.color,
            size: iconSize * 0.8,
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: _getTextStyle(theme).copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (showTooltip && config.tooltip.isNotEmpty) {
      chip = Tooltip(
        message: config.tooltip,
        child: chip,
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: chip)
        : chip;
  }

  Widget _buildCard(BuildContext context) {
    final config = _getStatusConfig();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  config.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.kPaddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: config.color,
                      ),
                    ),
                    if (config.description.isNotEmpty)
                      Text(
                        config.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (status == VerificationStatus.approved && onTap != null) ...[
            const SizedBox(height: AppDimens.kPaddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: AppColors.kSuccess, size: 16),
                  const SizedBox(width: AppDimens.kPaddingSmall),
                  Expanded(
                    child: Text(
                      'You have access to premium traveler features',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onTap != null && (status == VerificationStatus.notStarted || status == VerificationStatus.rejected)) ...[
            const SizedBox(height: AppDimens.kPaddingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  status == VerificationStatus.notStarted ? Icons.verified_user : Icons.refresh,
                  size: 18,
                ),
                label: Text(
                  status == VerificationStatus.notStarted
                      ? 'Get Verified'
                      : 'Retry Verification',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 16;
      case BadgeSize.medium:
        return 24;
      case BadgeSize.large:
        return 32;
      case BadgeSize.xlarge:
        return 48;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case BadgeSize.small:
        return theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
      case BadgeSize.medium:
        return theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
      case BadgeSize.large:
        return theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
      case BadgeSize.xlarge:
        return theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18);
    }
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case VerificationStatus.approved:
        return _StatusConfig(
          icon: Icons.verified,
          color: AppColors.kSuccess,
          label: 'Verified',
          title: 'Verified Traveler',
          description: 'This traveler has been verified and can be trusted',
          tooltip: 'This traveler is verified and trusted',
        );
      case VerificationStatus.pending:
        return _StatusConfig(
          icon: Icons.hourglass_top,
          color: AppColors.kWarning,
          label: 'Pending',
          title: 'Verification Pending',
          description: 'Verification is currently being reviewed',
          tooltip: 'Verification in progress',
        );
      case VerificationStatus.rejected:
        return _StatusConfig(
          icon: Icons.cancel,
          color: AppColors.kError,
          label: 'Rejected',
          title: 'Verification Rejected',
          description: 'Verification was rejected. Please resubmit with correct documents',
          tooltip: 'Verification was rejected',
        );
      case VerificationStatus.expired:
        return _StatusConfig(
          icon: Icons.schedule,
          color: AppColors.kWarning,
          label: 'Expired',
          title: 'Verification Expired',
          description: 'Your verification has expired. Please renew to continue',
          tooltip: 'Verification has expired',
        );
      case VerificationStatus.notStarted:
        return _StatusConfig(
          icon: Icons.verified_user,
          color: AppColors.kInfo,
          label: 'Get Verified',
          title: 'Get Verified',
          description: 'Complete verification to unlock premium features',
          tooltip: 'Start verification process',
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final String description;
  final String tooltip;

  _StatusConfig({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.description,
    required this.tooltip,
  });
}

// Helper widget for verified traveler info card
class VerifiedTravelerCard extends StatelessWidget {
  final String travelerName;
  final String? verificationDate;
  final VoidCallback? onViewProfile;
  final Widget? trailing;

  const VerifiedTravelerCard({
    Key? key,
    required this.travelerName,
    this.verificationDate,
    this.onViewProfile,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        border: Border.all(
          color: AppColors.kSuccess.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const VerificationBadge(
            status: VerificationStatus.approved,
            size: BadgeSize.medium,
            style: BadgeStyle.icon,
          ),
          const SizedBox(width: AppDimens.kPaddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      travelerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• Verified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (verificationDate != null)
                  Text(
                    'Verified $verificationDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onViewProfile != null)
            TextButton(
              onPressed: onViewProfile,
              child: const Text('View Profile'),
            ),
        ],
      ),
    );
  }
}

// Trust score indicator for verified travelers
class TrustScoreIndicator extends StatelessWidget {
  final double score; // 0.0 to 5.0
  final int reviewCount;
  final bool isVerified;

  const TrustScoreIndicator({
    Key? key,
    required this.score,
    required this.reviewCount,
    required this.isVerified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.kSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified) ...[
            const VerificationBadge(
              status: VerificationStatus.approved,
              size: BadgeSize.small,
              style: BadgeStyle.icon,
              showTooltip: false,
            ),
            const SizedBox(width: 4),
          ],
          Icon(Icons.star, color: AppColors.kWarning, size: 16),
          const SizedBox(width: 2),
          Text(
            score.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            ' (${reviewCount})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Verification prompt widget for unverified travelers
class VerificationPrompt extends StatelessWidget {
  final VoidCallback onVerify;
  final bool isCompact;

  const VerificationPrompt({
    Key? key,
    required this.onVerify,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
        decoration: BoxDecoration(
          color: AppColors.kInfo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
          border: Border.all(color: AppColors.kInfo.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.kInfo, size: 20),
            const SizedBox(width: AppDimens.kPaddingSmall),
            Expanded(
              child: Text(
                'Get verified for more orders',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.kInfo,
                ),
              ),
            ),
            TextButton(
              onPressed: onVerify,
              child: const Text('Verify'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  color: AppColors.kInfo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                ),
                child: Icon(Icons.verified_user, color: AppColors.kInfo, size: 24),
              ),
              const SizedBox(width: AppDimens.kPaddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a Verified Traveler',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kInfo,
                      ),
                    ),
                    Text(
                      'Unlock premium features and earn more',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.kPaddingMedium),

          // Benefits list
          ...[
            '📈 Higher earning potential',
            '⭐ Priority order matching',
            '🛡️ Trust badge on profile',
            '🎯 Access premium features',
          ].map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              benefit,
              style: theme.textTheme.bodySmall,
            ),
          )).toList(),

          const SizedBox(height: AppDimens.kPaddingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.verified_user, size: 18),
              label: const Text('Start Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kInfo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}