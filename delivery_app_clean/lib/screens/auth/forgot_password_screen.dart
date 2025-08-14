// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _emailSent = true;
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        switch (e.code) {
          case 'user-not-found':
            _error = 'No account found with this email address.';
            break;
          case 'invalid-email':
            _error = 'Please enter a valid email address.';
            break;
          case 'too-many-requests':
            _error = 'Too many requests. Please try again later.';
            break;
          default:
            _error = 'An error occurred. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _emailSent = false;
      _error = null;
    });
    await _sendPasswordReset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
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

                // Header Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: AppColors.kPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.kPaddingLarge),

                // Title and Description
                Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Password?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.kPaddingMedium),

                Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimens.kPaddingXLarge),

                if (!_emailSent) ...[
                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendPasswordReset(),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
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

                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Send Reset Email Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendPasswordReset,
                      style: AppButtonStyles.kPrimary,
                      child: _loading
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
                          const Text('Sending...'),
                        ],
                      )
                          : const Text('Send Reset Link'),
                    ),
                  ),
                ] else ...[
                  // Success State
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                      border: Border.all(
                        color: AppColors.kSuccess.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read,
                          size: 48,
                          color: AppColors.kSuccess,
                        ),
                        const SizedBox(height: AppDimens.kPaddingMedium),
                        Text(
                          'Email Sent Successfully!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.kSuccess,
                          ),
                        ),
                        const SizedBox(height: AppDimens.kPaddingSmall),
                        Text(
                          'Check your inbox and click the reset link to create a new password.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.kSuccess,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.kPaddingLarge),

                  // Resend Email Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _resendEmail,
                      style: AppButtonStyles.kOutlined,
                      child: const Text('Resend Email'),
                    ),
                  ),

                  const SizedBox(height: AppDimens.kPaddingMedium),

                  // Back to Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: AppButtonStyles.kPrimary,
                      child: const Text('Back to Login'),
                    ),
                  ),
                ],

                // Error Display
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.kPaddingLarge),
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
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.kError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppDimens.kPaddingXLarge),

                // Help Text
                if (!_emailSent)
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Remember your password? Back to Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.kPrimary,
                          decoration: TextDecoration.underline,
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