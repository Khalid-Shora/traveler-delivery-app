// lib/widgets/buyer_discover/featured_stores_grid.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class FeaturedStoresGrid extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final ValueChanged<Map<String, dynamic>>? onStoreSelected;

  const FeaturedStoresGrid({
    Key? key,
    required this.stores,
    this.onStoreSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return _EmptyStoresState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimens.kPaddingMedium,
        mainAxisSpacing: AppDimens.kPaddingMedium,
        childAspectRatio: 1.1,
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return _StoreCard(
          store: store,
          onTap: () => onStoreSelected?.call(store),
        );
      },
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback? onTap;

  const _StoreCard({
    required this.store,
    this.onTap,
  });

  Future<void> _launchStoreUrl() async {
    final url = store['link'] as String?;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeName = store['name'] as String? ?? 'Unknown Store';
    final assetPath = store['asset'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? _launchStoreUrl,
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          child: Padding(
            padding: AppDimens.kCardPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Store Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    child: assetPath.isNotEmpty
                        ? Image.asset(
                      assetPath,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _StoreInitials(storeName: storeName);
                      },
                    )
                        : _StoreInitials(storeName: storeName),
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Store Name
                Text(
                  storeName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppDimens.kPaddingSmall),

                // Store Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'International',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreInitials extends StatelessWidget {
  final String storeName;

  const _StoreInitials({required this.storeName});

  @override
  Widget build(BuildContext context) {
    final initials = storeName.length >= 2
        ? storeName.substring(0, 2).toUpperCase()
        : storeName.substring(0, 1).toUpperCase();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyStoresState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'No stores found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrolling stores list
class FeaturedStoresList extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final ValueChanged<Map<String, dynamic>>? onStoreSelected;

  const FeaturedStoresList({
    Key? key,
    required this.stores,
    this.onStoreSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingMedium),
        itemCount: stores.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppDimens.kPaddingMedium),
        itemBuilder: (context, index) {
          final store = stores[index];
          return _HorizontalStoreCard(
            store: store,
            onTap: () => onStoreSelected?.call(store),
          );
        },
      ),
    );
  }
}

class _HorizontalStoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback? onTap;

  const _HorizontalStoreCard({
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeName = store['name'] as String? ?? 'Unknown Store';
    final assetPath = store['asset'] as String? ?? '';

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    child: assetPath.isNotEmpty
                        ? Image.asset(
                      assetPath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _StoreInitials(storeName: storeName);
                      },
                    )
                        : _StoreInitials(storeName: storeName),
                  ),
                ),
                const SizedBox(height: AppDimens.kPaddingSmall),
                Text(
                  storeName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}