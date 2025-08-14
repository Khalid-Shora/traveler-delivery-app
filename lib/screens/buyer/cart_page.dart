// lib/screens/buyer/cart_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cart_model.dart';
import '../../services/cart_service.dart';
import '../../constants/app_constants.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  CartModel? _cart;
  bool _isLoading = true;
  String? _error;
  final Set<String> _updatingItems = <String>{}; // Track which items are being updated

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) {
      setState(() {
        _error = "Please log in to view your cart";
        _isLoading = false;
      });
      return;
    }

    try {
      final cart = await CartService.getUserCart(uid);
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantityOptimistic(String productId, int newQuantity) async {
    if (_cart == null || _updatingItems.contains(productId)) return;

    // Find the item
    final itemIndex = _cart!.items.indexWhere((item) => item.productId == productId);
    if (itemIndex == -1) return;

    final originalItem = _cart!.items[itemIndex];

    // Optimistic update - update UI immediately
    setState(() {
      _updatingItems.add(productId);

      if (newQuantity <= 0) {
        // Remove item
        _cart!.items.removeAt(itemIndex);
      } else {
        // Update quantity
        _cart!.items[itemIndex] = CartItem(
          productId: originalItem.productId,
          name: originalItem.name,
          image: originalItem.image,
          link: originalItem.link,
          price: originalItem.price,
          quantity: newQuantity,
          store: originalItem.store,
        );
      }

      // Recalculate total
      final newTotal = _cart!.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      _cart = CartModel(
        cartId: _cart!.cartId,
        uid: _cart!.uid,
        items: _cart!.items,
        total: newTotal,
        currency: _cart!.currency,
        createdAt: _cart!.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    // Update backend
    try {
      await CartService.updateQuantity(_cart!.cartId, productId, newQuantity);
    } catch (e) {
      // Revert optimistic update on error
      await _loadCart();
      _showErrorSnackBar('Failed to update cart: $e');
    } finally {
      if (mounted) {
        setState(() {
          _updatingItems.remove(productId);
        });
      }
    }
  }

  Future<void> _removeItemOptimistic(String productId, String productName) async {
    final confirmed = await _showRemoveConfirmation(productName);
    if (!confirmed || _cart == null || _updatingItems.contains(productId)) return;

    // Find the item
    final itemIndex = _cart!.items.indexWhere((item) => item.productId == productId);
    if (itemIndex == -1) return;

    final originalItems = List<CartItem>.from(_cart!.items);

    // Optimistic update - remove item from UI immediately
    setState(() {
      _updatingItems.add(productId);
      _cart!.items.removeAt(itemIndex);

      // Recalculate total
      final newTotal = _cart!.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      _cart = CartModel(
        cartId: _cart!.cartId,
        uid: _cart!.uid,
        items: _cart!.items,
        total: newTotal,
        currency: _cart!.currency,
        createdAt: _cart!.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    // Update backend
    try {
      await CartService.removeFromCart(_cart!.cartId, productId);
      _showSuccessSnackBar('$productName removed from cart');
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _cart = CartModel(
          cartId: _cart!.cartId,
          uid: _cart!.uid,
          items: originalItems,
          total: originalItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
          currency: _cart!.currency,
          createdAt: _cart!.createdAt,
          updatedAt: _cart!.updatedAt,
        );
      });
      _showErrorSnackBar('Failed to remove item: $e');
    } finally {
      if (mounted) {
        setState(() {
          _updatingItems.remove(productId);
        });
      }
    }
  }

  Future<void> _refreshCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _loadCart();
  }

  Future<bool> _showRemoveConfirmation(String productName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "$productName" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kError),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;
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
        duration: const Duration(seconds: 2),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    if (_cart == null || _cart!.items.isEmpty) {
      return _buildEmptyCartState();
    }

    return _buildCartContent(_cart!);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.kPrimary),
          const SizedBox(height: AppDimens.kPaddingMedium),
          Text(
            'Loading your cart...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.kError,
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Error loading cart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.kError,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _refreshCart,
              style: AppButtonStyles.kPrimary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.kAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppColors.kAccent,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Your cart is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(
              'Add some products to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingXLarge),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
              style: AppButtonStyles.kPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartModel cart) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Cart Items
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCart,
            color: AppColors.kPrimary,
            child: ListView.separated(
              padding: AppDimens.kScreenPadding,
              itemCount: cart.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingMedium),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _CartItemCard(
                  item: item,
                  onQuantityChanged: (newQuantity) {
                    _updateQuantityOptimistic(item.productId, newQuantity);
                  },
                  onRemove: () {
                    _removeItemOptimistic(item.productId, item.name);
                  },
                  isUpdating: _updatingItems.contains(item.productId),
                );
              },
            ),
          ),
        ),

        // Cart Summary
        _buildCartSummary(cart),
      ],
    );
  }

  Widget _buildCartSummary(CartModel cart) {
    final theme = Theme.of(context);
    final itemCount = cart.items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
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
        child: Column(
          children: [
            // Order Summary
            Container(
              padding: AppDimens.kCardPadding,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items ($itemCount)',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${cart.currency} ${cart.total.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.kPaddingSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shipping',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Calculated at checkout',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.kAccent,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppDimens.kPaddingLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${cart.currency} ${cart.total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Checkout Button
            ElevatedButton.icon(
              onPressed: cart.items.isEmpty || _updatingItems.isNotEmpty
                  ? null
                  : () => Navigator.pushNamed(context, RoutePaths.kCheckout),
              icon: const Icon(Icons.payment),
              label: const Text('Proceed to Checkout'),
              style: AppButtonStyles.kPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final bool isUpdating;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Padding(
        padding: AppDimens.kCardPadding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.kBackground,
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.kText,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: AppDimens.kPaddingMedium),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.store,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.kAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.price.toStringAsFixed(2)} USD',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove Button
                IconButton(
                  onPressed: isUpdating ? null : onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: isUpdating ? Colors.grey : AppColors.kError,
                    size: 20,
                  ),
                  tooltip: 'Remove item',
                ),
              ],
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Quantity and Subtotal Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: (item.quantity > 1 && !isUpdating)
                            ? () => onQuantityChanged(item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: isUpdating
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.kPrimary,
                          ),
                        )
                            : Text(
                          item.quantity.toString(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: (item.quantity < 10 && !isUpdating)
                            ? () => onQuantityChanged(item.quantity + 1)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${(item.price * item.quantity).toStringAsFixed(2)} USD',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}