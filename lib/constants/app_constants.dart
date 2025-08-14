import 'package:flutter/material.dart';

class RoutePaths {
  // ========== Auth Routes ==========
  static const String kLanding = '/';
  static const String kLogin = '/login';
  static const String kSignup = '/signup';
  static const String kForgotPassword = '/forgot-password';
  static const String kCompleteProfile = '/complete-profile';
  static const String kWelcome = '/welcome';

  // ========== Buyer Routes ==========
  static const String kBuyerHome = '/buyer-home';
  static const String kBuyerDiscover = '/buyer-discover';
  static const String kCart = '/cart';
  static const String kCheckout = '/checkout';
  static const String kTrack = '/track-order';
  static const String kOrderHistory = '/order-history';

  // ========== Traveler Routes ==========
  static const String kTravelerHome = '/traveler-home';
  static const String kTripsCart = '/my-trips';  // Fixed: was kMyTrips
  static const String kEarnings = '/earnings';
  static const String kCreateTrip = '/create-trip';
  static const String kOrderManagement = '/order-management';
  static const String kTravelerVerification = '/traveler-verification';
  static const String kOrderDiscovery = '/order-discovery';

  // ========== Profile & Account Routes ==========
  static const String kPersonalInfo = '/personal-info';
  static const String kAddresses = '/addresses';
  static const String kPaymentMethods = '/payment-methods';
  static const String kAddCard = '/add-card';
  static const String kNotifications = '/notifications';
  static const String kLanguageSettings = '/language-settings';
  static const String kContactUs = '/contact-us';
  static const String kPrivacySecurity = '/privacy-security';

  // ========== Utility Methods ==========

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const publicRoutes = [
      kLanding,
      kLogin,
      kSignup,
      kForgotPassword,
    ];
    return !publicRoutes.contains(route);
  }

  /// Get home route based on user role
  static String getHomeRoute(String role) {
    switch (role.toLowerCase()) {
      case 'buyer':
        return kBuyerHome;
      case 'traveler':
        return kTravelerHome;
      default:
        return kLanding;
    }
  }

  /// Check if route is buyer-specific
  static bool isBuyerRoute(String route) {
    const buyerRoutes = [
      kBuyerHome,
      kBuyerDiscover,
      kCart,
      kCheckout,
      kTrack,
      kOrderHistory,
    ];
    return buyerRoutes.contains(route);
  }

  /// Check if route is traveler-specific
  static bool isTravelerRoute(String route) {
    const travelerRoutes = [
      kTravelerHome,
      kTripsCart,
      kEarnings,
      kCreateTrip,
      kOrderManagement,
      kTravelerVerification,
      kOrderDiscovery,
    ];
    return travelerRoutes.contains(route);
  }
}

class AppDimens {
  static const double kPaddingSmall = 8.0;
  static const double kPaddingMedium = 16.0;
  static const double kPaddingLarge = 24.0;
  static const double kPaddingXLarge = 32.0;

  static const double kIconSize = 24.0;
  static const double kIconSizeSmall = 16.0;
  static const double kIconSizeLarge = 32.0;

  static const double kBadgeRadius = 12.0;
  static const double kBorderRadius = 12.0;
  static const double kBorderRadiusSmall = 8.0;
  static const double kBorderRadiusLarge = 16.0;

  static const double kElevation = 2.0;
  static const double kElevationLow = 1.0;
  static const double kElevationHigh = 4.0;

  static const EdgeInsets kScreenPadding = EdgeInsets.all(kPaddingMedium);
  static const EdgeInsets kButtonPadding = EdgeInsets.symmetric(horizontal: kPaddingLarge);
  static const EdgeInsets kCardPadding = EdgeInsets.all(kPaddingMedium);
  static const EdgeInsets kAllPadding = kScreenPadding;
}

class AppColors {
  // Light Mode Colors
  static const Color kPrimary = Color(0xFF001C2E);           // Navy blue
  static const Color kSecondary = Color(0xFF02435C);         // Dark teal
  static const Color kAccent = Color(0xFF57B5C3);            // Light teal
  static const Color kBackground = Color(0xFFE0E6E5);        // Light mint
  static const Color kText = Color(0xFF98A7AE);              // Muted blue-gray

  // Surface colors
  static const Color kSurface = Color(0xFFFFFFFF);           // Pure white
  static const Color kSurfaceVariant = Color(0xFFF5F7F6);    // Very light mint

  // Status colors
  static const Color kSuccess = Color(0xFF4CAF50);           // Green
  static const Color kWarning = Color(0xFFFF9800);           // Orange
  static const Color kError = Color(0xFFF44336);             // Red
  static const Color kInfo = Color(0xFF2196F3);              // Blue

  // Neutral colors
  static const Color kDivider = Color(0xFFE0E0E0);
  static const Color kDisabled = Color(0xFFBDBDBD);
  static const Color kPlaceholder = Color(0xFF9E9E9E);

  // Dark Mode Colors
  static const Color kPrimaryDark = Color(0xFF2696A6);       // Accent/CTA color
  static const Color kSecondaryDark = Color(0xFF466A74);     // Divider/Border color
  static const Color kAccentDark = Color(0xFF57B5C3);        // Light teal accent
  static const Color kBackgroundDark = Color(0xFF001C2E);    // Navy background
  static const Color kSurfaceDark = Color(0xFF1C3640);       // Card color
  static const Color kTextDark = Color(0xFFE0E6E5);          // Primary text
  static const Color kTextSecondaryDark = Color(0xFF98A7AE); // Secondary text
  static const Color kTextTertiaryDark = Color(0xFF466A74);  // Tertiary text/borders
  static const Color kDividerDark = Color(0xFF466A74);       // Divider/Border

  // Legacy colors (for backward compatibility - gradually remove these)
  @Deprecated('Use kBackground instead')
  static const Color kAppBackground = kBackground;
  @Deprecated('Use kText instead')
  static const Color kAppText = kText;
  @Deprecated('Use kAccent instead')
  static const Color kBadgeBackground = kAccent;
  @Deprecated('Use kPrimary instead')
  static const Color kBadgeText = kPrimary;
  @Deprecated('Use kSurfaceVariant instead')
  static const Color kIconBackground = kSurfaceVariant;
  @Deprecated('Use kSurface instead')
  static const Color kButtonBackground = kSurface;
  @Deprecated('Use kPrimary instead')
  static const Color kButtonText = kPrimary;
}

class AppTextStyles {
  // Headings
  static const TextStyle kHeadline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.kPrimary,
    height: 1.2,
  );

  static const TextStyle kHeadline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.kPrimary,
    height: 1.3,
  );

  static const TextStyle kHeadline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.kPrimary,
    height: 1.3,
  );

  static const TextStyle kHeadline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.kPrimary,
    height: 1.4,
  );

  static const TextStyle kHeadline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.kPrimary,
    height: 1.4,
  );

  static const TextStyle kHeadline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.kPrimary,
    height: 1.4,
  );

  // Body text
  static const TextStyle kBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.kText,
    height: 1.5,
  );

  static const TextStyle kBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.kText,
    height: 1.5,
  );

  static const TextStyle kBodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.kText,
    height: 1.4,
  );

  // Labels
  static const TextStyle kLabelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.kPrimary,
    height: 1.4,
  );

  static const TextStyle kLabelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.kText,
    height: 1.3,
  );

  static const TextStyle kLabelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.kText,
    height: 1.3,
  );

  // Legacy styles (for backward compatibility - gradually remove these)
  @Deprecated('Use kHeadline3 instead')
  static const TextStyle kHeadline5Bold = kHeadline3;
  @Deprecated('Use kHeadline4 instead')
  static const TextStyle kHeadline6Bold = kHeadline4;
  @Deprecated('Use kBodyLarge instead')
  static const TextStyle kBodyText = kBodyLarge;
  // @Deprecated('Use kBodySmall instead')
  // static const TextStyle kBodySmall = TextStyle(fontSize: 14, color: Colors.grey);
}

class AppButtonStyles {
  // Primary button
  static final ButtonStyle kPrimary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.kPrimary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
    ),
    elevation: AppDimens.kElevation,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Secondary button
  static final ButtonStyle kSecondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.kAccent,
    foregroundColor: AppColors.kPrimary,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
    ),
    elevation: AppDimens.kElevation,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Outlined button
  static final ButtonStyle kOutlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.kPrimary,
    minimumSize: const Size(double.infinity, 50),
    side: const BorderSide(color: AppColors.kPrimary, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Text button
  static final ButtonStyle kText = TextButton.styleFrom(
    foregroundColor: AppColors.kPrimary,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Small button variants
  static final ButtonStyle kPrimarySmall = ElevatedButton.styleFrom(
    backgroundColor: AppColors.kPrimary,
    foregroundColor: Colors.white,
    minimumSize: const Size(120, 40),
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingMedium),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
    ),
    elevation: AppDimens.kElevation,
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

class AppShadows {
  static const BoxShadow kSoft = BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  static const BoxShadow kMedium = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  );

  static const BoxShadow kHard = BoxShadow(
    color: Color(0x26000000),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );

  static const List<BoxShadow> kCardShadow = [kSoft];
  static const List<BoxShadow> kDialogShadow = [kMedium];
  static const List<BoxShadow> kFloatingActionButtonShadow = [kHard];
}
