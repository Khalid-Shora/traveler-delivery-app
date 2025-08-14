// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase & Stripe
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'env/firebase_env.dart';

// Screens
import 'package:delivery_app/screens/auth/landing_page.dart';
import 'package:delivery_app/screens/auth/login_screen.dart';
import 'package:delivery_app/screens/auth/complete_profile_screen.dart';
import 'package:delivery_app/screens/auth/forgot_password_screen.dart';

import 'package:delivery_app/screens/buyer/buyer_home_screen.dart';
import 'package:delivery_app/screens/buyer/buyer_discover_page.dart';
import 'package:delivery_app/screens/buyer/cart_page.dart';
import 'package:delivery_app/screens/buyer/checkout_page.dart';
import 'package:delivery_app/screens/buyer/order_tracking_page.dart';

import 'package:delivery_app/screens/traveler/traveler_home_screen.dart';
import 'package:delivery_app/screens/traveler/my_trips_page.dart';
import 'package:delivery_app/screens/traveler/earnings_page.dart';
import 'package:delivery_app/screens/traveler/create_trip_page.dart';
import 'package:delivery_app/screens/traveler/order_management_page.dart';
import 'package:delivery_app/screens/traveler/traveler_verification_page.dart';

import 'package:delivery_app/screens/payment_methods_page.dart';
import 'package:delivery_app/screens/add_card_page.dart';
import 'package:delivery_app/screens/addresses_page.dart';
import 'package:delivery_app/screens/personal_info_page.dart';
import 'package:delivery_app/screens/notifications_page.dart';
import 'package:delivery_app/screens/privacy_security_page.dart';
import 'package:delivery_app/screens/language_settings_page.dart';
import 'package:delivery_app/screens/contact_us_page.dart';

// Constants
import 'constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 1) Load environment variables
  await dotenv.load(fileName: '.env');

  // 2) Initialize Firebase with env-backed options
  await Firebase.initializeApp(
    options: FirebaseEnv.currentPlatform,
  );

  // 3) Initialize Stripe publishable key from env (no hardcoded keys)
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (stripeKey == null || stripeKey.isEmpty) {
    // Fail fast with a clear message during development
    throw Exception(
      'Missing STRIPE_PUBLISHABLE_KEY in .env. '
          'Add STRIPE_PUBLISHABLE_KEY=pk_test_xxx to your .env file.',
    );
  }
  Stripe.publishableKey = stripeKey;

  runApp(const MyApp(isLoggedIn: false));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Traveler Delivery',

      // Theme Configuration
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,

      // Localization (ready for multi-language support)
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'AE'),
      ],

      // Navigation
      initialRoute: isLoggedIn ? RoutePaths.kWelcome : RoutePaths.kLanding,
      routes: _buildRoutes(),
      onGenerateRoute: _generateRoute,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _UnknownRouteScreen(routeName: settings.name ?? 'unknown'),
      ),
    );
  }

  // Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kPrimary,
        brightness: Brightness.light,
        primary: AppColors.kPrimary,
        secondary: AppColors.kSecondary,
        tertiary: AppColors.kAccent,
        surface: AppColors.kSurface,
        background: AppColors.kBackground,
        error: AppColors.kError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.kText,
        onBackground: AppColors.kText,
      ),
      scaffoldBackgroundColor: AppColors.kBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurface,
        foregroundColor: AppColors.kPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.kPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.kPrimary,
          size: AppDimens.kIconSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.kSurface,
        elevation: AppDimens.kElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.kSurface,
        selectedItemColor: AppColors.kPrimary,
        unselectedItemColor: AppColors.kText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.kPaddingMedium,
          vertical: AppDimens.kPaddingMedium,
        ),
        labelStyle: AppTextStyles.kLabelMedium,
        hintStyle: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kPlaceholder),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.kPrimary),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.kOutlined),
      textButtonTheme: TextButtonThemeData(style: AppButtonStyles.kText),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        elevation: AppDimens.kElevationHigh,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.kDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.kHeadline1,
        displayMedium: AppTextStyles.kHeadline2,
        displaySmall: AppTextStyles.kHeadline3,
        headlineLarge: AppTextStyles.kHeadline3,
        headlineMedium: AppTextStyles.kHeadline4,
        headlineSmall: AppTextStyles.kHeadline5,
        titleLarge: AppTextStyles.kHeadline4,
        titleMedium: AppTextStyles.kHeadline5,
        titleSmall: AppTextStyles.kHeadline6,
        bodyLarge: AppTextStyles.kBodyLarge,
        bodyMedium: AppTextStyles.kBodyMedium,
        bodySmall: AppTextStyles.kBodySmall,
        labelLarge: AppTextStyles.kLabelLarge,
        labelMedium: AppTextStyles.kLabelMedium,
        labelSmall: AppTextStyles.kLabelSmall,
      ),
    );
  }

  // Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kPrimaryDark,
        brightness: Brightness.dark,
        primary: AppColors.kPrimaryDark,
        secondary: AppColors.kSecondaryDark,
        tertiary: AppColors.kAccentDark,
        surface: AppColors.kSurfaceDark,
        background: AppColors.kBackgroundDark,
        error: AppColors.kError,
        onPrimary: AppColors.kBackgroundDark,
        onSecondary: AppColors.kTextDark,
        onSurface: AppColors.kTextDark,
        onBackground: AppColors.kTextDark,
        outline: AppColors.kDividerDark,
        surfaceVariant: AppColors.kSurfaceDark,
        onSurfaceVariant: AppColors.kTextSecondaryDark,
      ),
      scaffoldBackgroundColor: AppColors.kBackgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurfaceDark,
        foregroundColor: AppColors.kTextDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.kTextDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.kTextDark,
          size: AppDimens.kIconSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.kSurfaceDark,
        elevation: AppDimens.kElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.kSurfaceDark,
        selectedItemColor: AppColors.kPrimaryDark,
        unselectedItemColor: AppColors.kTextSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kPrimaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.kPaddingMedium,
          vertical: AppDimens.kPaddingMedium,
        ),
        labelStyle: AppTextStyles.kLabelMedium.copyWith(color: AppColors.kTextSecondaryDark),
        hintStyle: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextTertiaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimaryDark,
          foregroundColor: AppColors.kBackgroundDark,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          ),
          elevation: AppDimens.kElevation,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimaryDark,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: AppColors.kPrimaryDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.kPrimaryDark,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimaryDark,
        foregroundColor: AppColors.kBackgroundDark,
        elevation: AppDimens.kElevationHigh,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.kDividerDark,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.kTextDark,
        size: AppDimens.kIconSize,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.kHeadline1.copyWith(color: AppColors.kTextDark),
        displayMedium: AppTextStyles.kHeadline2.copyWith(color: AppColors.kTextDark),
        displaySmall: AppTextStyles.kHeadline3.copyWith(color: AppColors.kTextDark),
        headlineLarge: AppTextStyles.kHeadline3.copyWith(color: AppColors.kTextDark),
        headlineMedium: AppTextStyles.kHeadline4.copyWith(color: AppColors.kTextDark),
        headlineSmall: AppTextStyles.kHeadline5.copyWith(color: AppColors.kTextDark),
        titleLarge: AppTextStyles.kHeadline4.copyWith(color: AppColors.kTextDark),
        titleMedium: AppTextStyles.kHeadline5.copyWith(color: AppColors.kTextDark),
        titleSmall: AppTextStyles.kHeadline6.copyWith(color: AppColors.kTextDark),
        bodyLarge: AppTextStyles.kBodyLarge.copyWith(color: AppColors.kTextDark),
        bodyMedium: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondaryDark),
        bodySmall: AppTextStyles.kBodySmall.copyWith(color: AppColors.kTextTertiaryDark),
        labelLarge: AppTextStyles.kLabelLarge.copyWith(color: AppColors.kTextDark),
        labelMedium: AppTextStyles.kLabelMedium.copyWith(color: AppColors.kTextSecondaryDark),
        labelSmall: AppTextStyles.kLabelSmall.copyWith(color: AppColors.kTextTertiaryDark),
      ),
    );
  }

  // Routes
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Auth
      RoutePaths.kLanding: (_) => LandingPage(),
      RoutePaths.kLogin: (_) => const LoginScreen(),
      RoutePaths.kForgotPassword: (_) => const ForgotPasswordScreen(),

      // Buyer
      RoutePaths.kBuyerHome: (_) => const BuyerHomeScreen(),
      RoutePaths.kBuyerDiscover: (_) => const BuyerDiscoverPage(),
      RoutePaths.kCart: (_) => const CartPage(),
      RoutePaths.kCheckout: (_) => const CheckoutPage(),
      RoutePaths.kTrack: (_) => const OrderTrackingPage(),

      // Traveler
      RoutePaths.kTravelerHome: (_) => TravelerHomeScreen(),
      RoutePaths.kTripsCart: (_) => const MyTripsPage(),
      RoutePaths.kEarnings: (_) => const EarningsPage(),
      RoutePaths.kCreateTrip: (_) => const CreateTripPage(),
      RoutePaths.kOrderManagement: (_) => const OrderManagementPage(),

      // Profile Subpages
      RoutePaths.kPersonalInfo: (_) => const PersonalInfoPage(),
      RoutePaths.kPaymentMethods: (_) => PaymentMethodsPage(),
      RoutePaths.kAddCard: (_) => AddCardPage(),
      RoutePaths.kNotifications: (_) => NotificationsPage(),
      RoutePaths.kAddresses: (_) => const AddressesPage(),
      RoutePaths.kLanguageSettings: (_) => LanguageSettingsPage(),
      RoutePaths.kContactUs: (_) => ContactUsPage(),
      RoutePaths.kTravelerVerification: (_) => const TravelerVerificationPage(),
    };
  }

  // Dynamic route generation (kept minimal & safe)
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.kCompleteProfile:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            uid: args['uid'] ?? '',
            email: args['email'] ?? '',
            name: args['name'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => _UnknownRouteScreen(routeName: settings.name ?? 'unknown'),
        );
    }
  }
}

// Fallback page for unknown routes (prevents blank screens)
class _UnknownRouteScreen extends StatelessWidget {
  final String routeName;
  const _UnknownRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route not found')),
      body: Center(
        child: Text('No route registered for: $routeName'),
      ),
    );
  }
}
