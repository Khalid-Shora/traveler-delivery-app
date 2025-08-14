// lib/main.dart

import 'package:delivery_app/screens/add_card_page.dart';
import 'package:delivery_app/screens/addresses_page.dart';
import 'package:delivery_app/screens/buyer/checkout_page.dart';
import 'package:delivery_app/screens/auth/complete_profile_screen.dart';
import 'package:delivery_app/screens/auth/forgot_password_screen.dart';
import 'package:delivery_app/screens/buyer/order_tracking_page.dart';
import 'package:delivery_app/screens/traveler/create_trip_page.dart';
import 'package:delivery_app/screens/traveler/order_management_page.dart';
import 'package:delivery_app/screens/traveler/traveler_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// Screens
import 'screens/auth/landing_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/payment_methods_page.dart';

// Buyer Screens
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/buyer/buyer_discover_page.dart';
import 'screens/buyer/cart_page.dart';

// Traveler Screens
import 'screens/traveler/traveler_home_screen.dart';
import 'screens/traveler/my_trips_page.dart';
import 'screens/traveler/earnings_page.dart';

// Profile Subpages
import 'screens/personal_info_page.dart';
import 'screens/notifications_page.dart';
import 'screens/privacy_security_page.dart';
import 'screens/language_settings_page.dart';
import 'screens/contact_us_page.dart';

// Constants
import 'constants/app_constants.dart';

void main() async {
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

  await Firebase.initializeApp();
  Stripe.publishableKey = "pk_test_51RoirAPe1XfYSH2gV6PRvyc9S52HewsI6ewCIod1XhVPRZZ1Lau6ZxQGrxOPGwGmqiWSDNvPVNRpANr03Aw2sj0p00D6aLEUXQ";

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
      themeMode: ThemeMode.system, // Automatically switches based on system preference

      // Localization (ready for multi-language support)
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('ar', 'AE'), // Arabic
      ],

      // Navigation
      initialRoute: isLoggedIn ? RoutePaths.kWelcome : RoutePaths.kLanding,
      routes: _buildRoutes(),
      onGenerateRoute: _generateRoute,
    );
  }

  // Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
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

      // Scaffold
      scaffoldBackgroundColor: AppColors.kBackground,

      // App Bar Theme
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

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.kSurface,
        elevation: AppDimens.kElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.kSurface,
        selectedItemColor: AppColors.kPrimary,
        unselectedItemColor: AppColors.kText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Input Decoration Theme
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

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.kPrimary),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.kOutlined),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(style: AppButtonStyles.kText),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        elevation: AppDimens.kElevationHigh,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.kDivider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
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

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kPrimaryDark,
        brightness: Brightness.dark,
        primary: AppColors.kPrimaryDark,          // #2696A6 - Accent/CTA
        secondary: AppColors.kSecondaryDark,       // #466A74 - Secondary
        tertiary: AppColors.kAccentDark,          // #57B5C3 - Light teal
        surface: AppColors.kSurfaceDark,          // #1C3640 - Card
        background: AppColors.kBackgroundDark,     // #001C2E - Navy background
        error: AppColors.kError,
        onPrimary: AppColors.kBackgroundDark,     // Dark text on primary
        onSecondary: AppColors.kTextDark,         // Light text on secondary
        onSurface: AppColors.kTextDark,           // #E0E6E5 - Primary text
        onBackground: AppColors.kTextDark,        // #E0E6E5 - Primary text
        outline: AppColors.kDividerDark,          // #466A74 - Borders
        surfaceVariant: AppColors.kSurfaceDark,
        onSurfaceVariant: AppColors.kTextSecondaryDark, // #98A7AE - Secondary text
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.kBackgroundDark,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurfaceDark,     // #1C3640
        foregroundColor: AppColors.kTextDark,        // #E0E6E5
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.kTextDark,                // #E0E6E5
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.kTextDark,                // #E0E6E5
          size: AppDimens.kIconSize,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.kSurfaceDark,               // #1C3640
        elevation: AppDimens.kElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.kSurfaceDark,     // #1C3640
        selectedItemColor: AppColors.kPrimaryDark,   // #2696A6
        unselectedItemColor: AppColors.kTextSecondaryDark, // #98A7AE
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurfaceDark,           // #1C3640
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDividerDark), // #466A74
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kDividerDark), // #466A74
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kPrimaryDark, width: 2), // #2696A6
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          borderSide: BorderSide(color: AppColors.kError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.kPaddingMedium,
          vertical: AppDimens.kPaddingMedium,
        ),
        labelStyle: AppTextStyles.kLabelMedium.copyWith(color: AppColors.kTextSecondaryDark), // #98A7AE
        hintStyle: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextTertiaryDark),    // #466A74
      ),

      // Elevated Button Theme (for dark mode)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimaryDark,   // #2696A6
          foregroundColor: AppColors.kBackgroundDark, // #001C2E (dark text on accent)
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
        ),
      ),

      // Outlined Button Theme (for dark mode)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimaryDark,   // #2696A6
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: AppColors.kPrimaryDark, width: 1.5), // #2696A6
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme (for dark mode)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.kPrimaryDark,   // #2696A6
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimaryDark,     // #2696A6
        foregroundColor: AppColors.kBackgroundDark,  // #001C2E
        elevation: AppDimens.kElevationHigh,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.kDividerDark,               // #466A74
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.kTextDark,                  // #E0E6E5
        size: AppDimens.kIconSize,
      ),

      // Text Theme (Dark)
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
        bodyLarge: AppTextStyles.kBodyLarge.copyWith(color: AppColors.kTextDark),           // #E0E6E5
        bodyMedium: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondaryDark), // #98A7AE
        bodySmall: AppTextStyles.kBodySmall.copyWith(color: AppColors.kTextTertiaryDark),   // #466A74
        labelLarge: AppTextStyles.kLabelLarge.copyWith(color: AppColors.kTextDark),
        labelMedium: AppTextStyles.kLabelMedium.copyWith(color: AppColors.kTextSecondaryDark),
        labelSmall: AppTextStyles.kLabelSmall.copyWith(color: AppColors.kTextTertiaryDark),
      ),
    );
  }

  // Routes
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
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

  // Dynamic route generation
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.kCompleteProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            uid: args['uid'],
            email: args['email'],
            name: args['name'],
          ),
        );


      // default:
      //   return null;
    }
  }
}

// Missing screen classes for compilation (create these next)
class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications coming soon')),
    );
  }
}

class PrivacySecurityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: const Center(child: Text('Privacy & Security settings coming soon')),
    );
  }
}

class LanguageSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Settings')),
      body: const Center(child: Text('Language settings coming soon')),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: const Center(child: Text('Contact us page coming soon')),
    );
  }
}