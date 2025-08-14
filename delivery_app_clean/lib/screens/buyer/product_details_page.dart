// lib/screens/buyer/product_details_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cart_model.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../services/cart_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isAddingToCart = false;
  int _quantity = 1;
  bool _isFavorite = false;

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      await CartService.addToCart(
        user.uid,
        widget.product,
        quantity: _quantity,
        currency: 'USD',
      );

      if (mounted) {
        _showSuccessSnackBar('Added to cart successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error adding to cart: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _viewOnStore() async {
    final url = widget.product.link;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Cannot open store link');
      }
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to add items to your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RoutePaths.kLogin);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, RoutePaths.kCart),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Product Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.cardColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimens.kBorderRadiusLarge),
                    bottomRight: Radius.circular(AppDimens.kBorderRadiusLarge),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimens.kBorderRadiusLarge),
                    bottomRight: Radius.circular(AppDimens.kBorderRadiusLarge),
                  ),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.kBackground,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: AppColors.kText,
                              ),
                              const SizedBox(height: AppDimens.kPaddingSmall),
                              Text(
                                'Image not available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.kText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.kBackground,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.kPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppColors.kError : theme.iconTheme.color,
                ),
              ),
            ],
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: AppDimens.kScreenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Product Name
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kPrimary,
                    ),
                  ),

                  const SizedBox(height: AppDimens.kPaddingSmall),

                  // Store Name
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.kPaddingMedium,
                      vertical: AppDimens.kPaddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: AppColors.kAccent,
                        ),
                        const SizedBox(width: AppDimens.kPaddingSmall),
                        Text(
                          widget.product.store,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Price
                  Row(
                    children: [
                      Text(
                        '\$${widget.product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimary,
                        ),
                      ),
                      const SizedBox(width: AppDimens.kPaddingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.kPaddingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.kSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'USD',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.kSuccess,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Quantity Selector
                  Container(
                    padding: AppDimens.kCardPadding,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                      boxShadow: AppShadows.kCardShadow,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Quantity:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: const Icon(Icons.remove),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                              Container(
                                width: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  _quantity.toString(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quantity < 10
                                    ? () => setState(() => _quantity++)
                                    : null,
                                icon: const Icon(Icons.add),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Description
                  if (widget.product.description != null && widget.product.description!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: AppDimens.kCardPadding,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                        boxShadow: AppShadows.kCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimens.kPaddingMedium),
                          Text(
                            widget.product.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.kPaddingLarge),
                  ],

                  // Product Link Button
                  OutlinedButton.icon(
                    onPressed: _viewOnStore,
                    icon: const Icon(Icons.launch),
                    label: const Text('View on Store'),
                    style: AppButtonStyles.kOutlined,
                  ),

                  const SizedBox(height: AppDimens.kPaddingXLarge),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: AppDimens.kScreenPadding,
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Total Price
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '\$${(widget.product.price * _quantity).toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Add to Cart Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  icon: _isAddingToCart
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                      : const Icon(Icons.shopping_cart_outlined),
                  label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
                  style: AppButtonStyles.kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}