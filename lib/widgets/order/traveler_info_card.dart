// lib/widgets/order/traveler_info_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../traveler/verification_badge.dart'; // FIXED: Correct path

class TravelerInfoCard extends StatefulWidget {
  final String travelerId;
  final String? travelerName;
  final double? rating;
  final int? completedOrders;
  final DateTime? memberSince;
  final VoidCallback? onViewProfile;
  final VoidCallback? onContactTraveler;
  final bool showContactButton;
  final bool showStats;

  const TravelerInfoCard({
    Key? key,
    required this.travelerId,
    this.travelerName,
    this.rating,
    this.completedOrders,
    this.memberSince,
    this.onViewProfile,
    this.onContactTraveler,
    this.showContactButton = true,
    this.showStats = true,
  }) : super(key: key);

  @override
  State<TravelerInfoCard> createState() => _TravelerInfoCardState();
}

class _TravelerInfoCardState extends State<TravelerInfoCard> {
  String _verificationStatus = 'not_started';
  Map<String, dynamic>? _travelerData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTravelerInfo();
  }

  Future<void> _loadTravelerInfo() async {
    try {
      // Load traveler's basic info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.travelerId)
          .get();

      // Load verification status
      final verificationDoc = await FirebaseFirestore.instance
          .collection('user_verifications')
          .doc(widget.travelerId)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            _travelerData = userDoc.data();
          }

          _verificationStatus = verificationDoc.exists
              ? (verificationDoc.data()?['status'] ?? 'not_started')
              : 'not_started';

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Convert string status to VerificationStatus enum
  VerificationStatus _getVerificationStatus() {
    switch (_verificationStatus) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = _verificationStatus == 'approved';
    final travelerName = widget.travelerName ?? _travelerData?['name'] ?? 'Traveler';

    return Container(
      padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(
          color: isVerified
              ? AppColors.kSuccess.withValues(alpha: 0.3)
              : theme.dividerColor,
          width: isVerified ? 2 : 1,
        ),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Avatar with verification badge
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isVerified ? AppColors.kSuccess : AppColors.kPrimary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        travelerName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.kPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!_loading)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: VerificationBadge(
                        status: _getVerificationStatus(),
                        size: BadgeSize.small,
                        style: BadgeStyle.icon,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: AppDimens.kPaddingMedium),

              // Traveler Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            travelerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isVerified && !_loading)
                          VerificationBadge(
                            status: VerificationStatus.approved,
                            size: BadgeSize.small,
                            style: BadgeStyle.iconText,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Rating and reviews
                    if (widget.rating != null) ...[
                      TrustScoreIndicator(
                        score: widget.rating!,
                        reviewCount: widget.completedOrders ?? 0,
                        isVerified: isVerified,
                      ),
                    ] else if (isVerified) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.kSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Verified Traveler',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.kSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Rest of the widget remains the same...
        ],
      ),
    );
  }
}