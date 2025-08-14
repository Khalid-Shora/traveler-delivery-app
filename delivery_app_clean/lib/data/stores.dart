// lib/data/stores.dart

/// Featured stores data for the discover page
final List<Map<String, dynamic>> storesList = [
  {
    'name': 'Amazon',
    'asset': 'assets/icons/amazon.png',
    'link': 'https://amazon.com',
    'category': 'general',
    'trending': true,
  },
  {
    'name': 'Apple',
    'asset': 'assets/icons/apple.png',
    'link': 'https://apple.com',
    'category': 'electronics',
    'trending': true,
  },
  {
    'name': 'Nike',
    'asset': 'assets/icons/nike.png',
    'link': 'https://nike.com',
    'category': 'fashion',
    'trending': true,
  },
  {
    'name': 'Adidas',
    'asset': 'assets/icons/adidas.png',
    'link': 'https://adidas.com',
    'category': 'fashion',
    'trending': false,
  },
  {
    'name': 'Zara',
    'asset': 'assets/icons/zara.png',
    'link': 'https://zara.com',
    'category': 'fashion',
    'trending': true,
  },
  {
    'name': 'H&M',
    'asset': 'assets/icons/hm.png',
    'link': 'https://hm.com',
    'category': 'fashion',
    'trending': false,
  },
  {
    'name': 'Best Buy',
    'asset': 'assets/icons/bestbuy.png',
    'link': 'https://bestbuy.com',
    'category': 'electronics',
    'trending': false,
  },
  {
    'name': 'Target',
    'asset': 'assets/icons/target.png',
    'link': 'https://target.com',
    'category': 'general',
    'trending': false,
  },
  {
    'name': 'Walmart',
    'asset': 'assets/icons/walmart.png',
    'link': 'https://walmart.com',
    'category': 'general',
    'trending': false,
  },
  {
    'name': 'eBay',
    'asset': 'assets/icons/ebay.png',
    'link': 'https://ebay.com',
    'category': 'general',
    'trending': false,
  },
  {
    'name': 'Samsung',
    'asset': 'assets/icons/samsung.png',
    'link': 'https://samsung.com',
    'category': 'electronics',
    'trending': true,
  },
  {
    'name': 'IKEA',
    'asset': 'assets/icons/ikea.png',
    'link': 'https://ikea.com',
    'category': 'home',
    'trending': false,
  },
];

/// Categories for filtering stores
final List<String> storeCategories = [
  'All',
  'Electronics',
  'Fashion',
  'Home',
  'General',
];

/// Get stores by category
List<Map<String, dynamic>> getStoresByCategory(String category) {
  if (category.toLowerCase() == 'all') {
    return storesList;
  }
  return storesList
      .where((store) => store['category'].toString().toLowerCase() == category.toLowerCase())
      .toList();
}

/// Get trending stores
List<Map<String, dynamic>> getTrendingStores() {
  return storesList.where((store) => store['trending'] == true).toList();
}

/// Get featured stores (first 8 for grid display)
List<Map<String, dynamic>> getFeaturedStores() {
  return storesList.take(8).toList();
}

/// Sample product categories
final List<String> productCategories = [
  'Electronics',
  'Fashion',
  'Home & Garden',
  'Sports',
  'Beauty',
  'Books',
  'Toys',
  'Automotive',
];

/// Popular search terms
final List<String> popularSearches = [
  'iPhone 15',
  'Nike Air Max',
  'MacBook Pro',
  'Samsung Galaxy',
  'PlayStation 5',
  'AirPods Pro',
  'iPad',
  'Apple Watch',
];

/// Sample promotional banners
final List<Map<String, dynamic>> promoBanners = [
  {
    'title': 'Summer Sale',
    'description': 'Up to 50% off on fashion items',
    'imageAsset': 'assets/banners/summer_sale.png',
    'buttonText': 'Shop Now',
    'link': 'https://example.com/summer-sale',
  },
  {
    'title': 'Electronics Deal',
    'description': 'Latest gadgets at best prices',
    'imageAsset': 'assets/banners/electronics_deal.png',
    'buttonText': 'Explore',
    'link': 'https://example.com/electronics',
  },
  {
    'title': 'Free Shipping',
    'description': 'On orders over \$100',
    'imageAsset': 'assets/banners/free_shipping.png',
    'buttonText': 'Learn More',
    'link': 'https://example.com/shipping',
  },
];