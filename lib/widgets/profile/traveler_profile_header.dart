// lib/widgets/profile/traveler_profile_header.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../traveler/verification_badge.dart'; // keep this path

class TravelerProfileHeader extends StatefulWidget {
  final UserModel user;
  final VoidCallback onProfileUpdated;

  const TravelerProfileHeader({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<TravelerProfileHeader> createState() => _TravelerProfileHeaderState();
}

class _TravelerProfileHeaderState extends State<TravelerProfileHeader> {
  Map<String, dynamic>? _verificationData;
  String _verificationStatus = 'not_started';
  bool _loading = true;

  // Demo stats (replace with real aggregates later if needed)
  double _trustScore = 4.8;
  int _reviewCount = 23;
  int _completedOrders = 15;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final uid = widget.user.uid;
      if (uid.isEmpty) {
        if (!mounted) return;
        setState(() {
          _verificationStatus = 'not_started';
          _verificationData = const {'status': 'not_started'};
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('user_verifications')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;
      setState(() {
        if (doc.exists && doc.data() != null) {
          _verificationData = doc.data();
          _verificationStatus =
              (_verificationData!['status'] ?? 'not_started').toString();
        } else {
          _verificationStatus = 'not_started';
          _verificationData = const {'status': 'not_started'};
        }
      });
    } catch (e) {
      debugPrint('Error loading verification status: $e');
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'not_started';
        _verificationData = const {'status': 'not_started'};
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  VerificationStatus _mapStatus(String s) {
    switch (s) {
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

  void _navigateToVerification() {
    Navigator.pushNamed(context, '/traveler-verification');
  }

  String _safeInitials(String name) {
    final n = (name).trim();
    if (n.isEmpty) return 'T';
    final parts = n.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return n.characters.first.toUpperCase();
    if (parts.length == 1) return parts[0].characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  /// Safely try common avatar fields on UserModel without compile-time getters.
  String _avatarFromUser(UserModel u) {
    String? v;

    try {
      final d = (u as dynamic).avatarUrl;
      if (d is String && d.trim().isNotEmpty) v = d.trim();
    } catch (_) {}
    if (v == null) {
      try {
        final d = (u as dynamic).photoUrl;
        if (d is String && d.trim().isNotEmpty) v = d.trim();
      } catch (_) {}
    }
    if (v == null) {
      try {
        final d = (u as dynamic).imageUrl;
        if (d is String && d.trim().isNotEmpty) v = d.trim();
      } catch (_) {}
    }
    if (v == null) {
      try {
        final d = (u as dynamic).profileImage;
        if (d is String && d.trim().isNotEmpty) v = d.trim();
      } catch (_) {}
    }
    if (v == null) {
      try {
        final d = (u as dynamic).avatar;
        if (d is String && d.trim().isNotEmpty) v = d.trim();
      } catch (_) {}
    }

    return v ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayName = (widget.user.name ?? '').trim().isEmpty
        ? 'Traveler'
        : widget.user.name!.trim();

    final avatarUrl = _avatarFromUser(widget.user);
    final hasAvatar = avatarUrl.isNotEmpty;

    final isVerified = _verificationStatus == 'approved';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.kPrimary,
            AppColors.kPrimary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
          child: Column(
            children: [
              // Profile row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar + verification badge
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasAvatar
                            ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialsAvatar(letter: _safeInitials(displayName)),
                        )
                            : _InitialsAvatar(letter: _safeInitials(displayName)),
                      ),
                      if (!_loading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: VerificationBadge(
                            status: _mapStatus(_verificationStatus),
                            size: BadgeSize.medium,
                            style: BadgeStyle.icon,
                            onTap: !isVerified ? _navigateToVerification : null,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: AppDimens.kPaddingLarge),

                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row + edit callback
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: widget.onProfileUpdated,
                              icon: Icon(Icons.edit,
                                  color: Colors.white.withOpacity(0.9)),
                              tooltip: 'Edit profile',
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Trust score if verified; otherwise compact badge
                        if (isVerified)
                          TrustScoreIndicator(
                            score: _trustScore,
                            reviewCount: _reviewCount,
                            isVerified: true,
                          )
                        else if (!_loading)
                          VerificationBadge(
                            status: _mapStatus(_verificationStatus),
                            size: BadgeSize.small,
                            style: BadgeStyle.iconText,
                            onTap: _navigateToVerification,
                          ),

                        const SizedBox(height: 8),

                        // Subtext
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.85),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Professional Traveler',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Settings button (placeholder)
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                    icon: Icon(Icons.settings,
                        color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Stats row
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                          'Orders', _completedOrders.toString(), Icons.local_shipping),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildStatItem(
                          'Rating', _trustScore.toStringAsFixed(1), Icons.star),
                    ),
                  ],
                ),
              ),

              // Inline verification tip
              if (!isVerified && !_loading) ...[
                const SizedBox(height: AppDimens.kPaddingMedium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.white.withOpacity(0.9), size: 20),
                      const SizedBox(width: AppDimens.kPaddingSmall),
                      Expanded(
                        child: Text(
                          _verificationTipText(_verificationStatus),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // ⚠️ FIX: Constrain the button so theme can't force infinite width
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0),
                        child: TextButton(
                          onPressed: _navigateToVerification,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Verify Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _verificationTipText(String status) {
    switch (status) {
      case 'pending':
        return 'Your verification is being reviewed';
      case 'rejected':
        return 'Verification rejected. Resubmit documents';
      case 'expired':
        return 'Your verification has expired';
      default:
        return 'Get verified to unlock premium features';
    }
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String letter;
  const _InitialsAvatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Simple trust score row (kept from your original UI)
class TrustScoreIndicator extends StatelessWidget {
  final double score;
  final int reviewCount;
  final bool isVerified;

  const TrustScoreIndicator({
    super.key,
    required this.score,
    required this.reviewCount,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(isVerified ? Icons.verified : Icons.verified_outlined,
            size: 18, color: Colors.white.withOpacity(0.95)),
        const SizedBox(width: 6),
        Text(
          '$score • $reviewCount reviews',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
