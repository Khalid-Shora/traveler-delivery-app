// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart'; // Add this import
import 'complete_profile_screen.dart';
import '../buyer/buyer_home_screen.dart';
import '../traveler/traveler_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;
  String error = "";

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleHome(String role) {
    if (role == 'buyer') {
      Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kBuyerHome, (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kTravelerHome, (route) => false);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() { loading = true; error = ''; });

    try {
      final user = await AuthService.signInWithEmail(email, password);
      if (user == null) throw Exception("Login failed");

      // Check Firestore user doc
      final userDoc = await AuthService.getUserDoc(user.uid);
      if (userDoc == null || userDoc['phone'] == null || userDoc['role'] == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              uid: user.uid,
              email: user.email,
              name: user.displayName,
            ),
          ),
        );
        return;
      }
      _navigateToRoleHome(userDoc['role']);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() { loading = true; error = ''; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) throw Exception("Google login cancelled");
      final userDoc = await AuthService.getUserDoc(user.uid);
      if (userDoc == null || userDoc['phone'] == null || userDoc['role'] == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              uid: user.uid,
              email: user.email,
              name: user.displayName,
            ),
          ),
        );
        return;
      }
      _navigateToRoleHome(userDoc['role']);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Welcome Back"),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimens.kScreenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.kPaddingLarge),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.kPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.kPaddingMedium),
                      Text(
                        'Sign in to your account',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingXLarge),

                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    hintText: "Enter your email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleEmailLogin(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // 🔑 ADD THIS - Forgot Password Link
                const SizedBox(height: AppDimens.kPaddingSmall),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingLarge),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppButtonStyles.kPrimary,
                    onPressed: loading ? null : _handleEmailLogin,
                    child: loading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        const Text('Signing In...'),
                      ],
                    )
                        : const Text('Sign In'),
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingMedium),
                      child: Text(
                        "or",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                    style: AppButtonStyles.kOutlined,
                    onPressed: loading ? null : _handleGoogleLogin,
                    label: const Text('Continue with Google'),
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingLarge),

                // Error Display
                if (error.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.kError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                      border: Border.all(
                        color: AppColors.kError.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.kError,
                          size: AppDimens.kIconSize,
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        Expanded(
                          child: Text(
                            error,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.kError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                ],

                // Sign Up Link
                Center(
                  child: TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: AppColors.kPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}