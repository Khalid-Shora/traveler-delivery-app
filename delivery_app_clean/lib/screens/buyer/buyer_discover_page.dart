// lib/screens/buyer/buyer_discover_page.dart

import 'package:flutter/material.dart';
import '../../widgets/buyer_discover/link_intro_card.dart';
import '../../widgets/buyer_discover/section_header.dart';
import '../../widgets/buyer_discover/featured_stores_grid.dart';
import '../../constants/app_constants.dart';
import '../../services/product_service.dart';
import '../../data/stores.dart';
import 'product_details_page.dart';

class BuyerDiscoverPage extends StatefulWidget {
  const BuyerDiscoverPage({Key? key}) : super(key: key);

  @override
  State<BuyerDiscoverPage> createState() => _BuyerDiscoverPageState();
}

class _BuyerDiscoverPageState extends State<BuyerDiscoverPage> {
  final TextEditingController _linkController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid product link'),
          backgroundColor: AppColors.kError,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final product = await ProductService.instance.fetchByUrl(link);
      setState(() => _loading = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
            ),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Convert stores list to proper format
    final List<Map<String, String>> cleanedStoresList = storesList
        .map((store) => {
      'name': store['name']?.toString() ?? '',
      'asset': store['asset']?.toString() ?? '',
      'link': store['link'].toString(),
    })
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Padding(
                padding: AppDimens.kScreenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Products',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.kPaddingSmall),
                    Text(
                      'Shop from international stores worldwide',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Link Intro + Input
              LinkIntroCard(
                controller: _linkController,
                onContinue: _handleContinue,
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Loading indicator
              if (_loading)
                Container(
                  padding: AppDimens.kScreenPadding,
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.kPrimary,
                        ),
                        const SizedBox(height: AppDimens.kPaddingMedium),
                        Text(
                          'Loading product details...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Featured Stores Section
              const SectionHeader(
                title: 'Featured stores',
              ),

              const SizedBox(height: AppDimens.kPaddingSmall),

              FeaturedStoresGrid(stores: cleanedStoresList),

              const SizedBox(height: AppDimens.kPaddingXLarge),

              // Additional Info Card
              Container(
                margin: AppDimens.kScreenPadding,
                padding: AppDimens.kCardPadding,
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.kAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.kAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        Expanded(
                          child: Text(
                            'How it works',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    _InfoStep(
                      step: '1',
                      title: 'Share Product Link',
                      description: 'Copy and paste any product link from international stores',
                    ),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    _InfoStep(
                      step: '2',
                      title: 'We Handle Purchase',
                      description: 'Our system processes your order and handles payment',
                    ),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    _InfoStep(
                      step: '3',
                      title: 'Traveler Delivers',
                      description: 'A trusted traveler brings your item directly to you',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _InfoStep({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.kPaddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}