// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'complete_profile_screen.dart';
import '../buyer/buyer_home_screen.dart';
import '../traveler/traveler_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  String role = "buyer";
  bool loading = false;
  String error = "";

  void _navigateToRoleHome(String role) {
    if (role == 'buyer') {
      Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kBuyerHome, (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kTravelerHome, (route) => false);
    }
  }


  Future<void> _handleEmailSignup() async {
    // Validation
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phone = phoneController.text.trim();

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => error = "Enter a valid email address");
      return;
    }
    if (password.length < 6) {
      setState(() => error = "Password must be at least 6 characters");
      return;
    }
    if (phone.length < 7) {
      setState(() => error = "Enter a valid phone number");
      return;
    }
    setState(() { loading = true; error = ''; });

    try {
      final user = await AuthService.signUpWithEmail(email, password);
      if (user == null) throw Exception("Signup failed");
      await AuthService.saveUserToFirestore(
        uid: user.uid,
        email: email,
        phone: phone,
        role: role,
      );
      _navigateToRoleHome(role);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() { loading = true; error = ''; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) throw Exception("Google signup cancelled");
      // check Firestore user doc
      final userDoc = await AuthService.getUserDoc(user.uid);
      if (userDoc == null || userDoc['phone'] == null || userDoc['role'] == null) {
        // يحتاج إكمال بيانات، يظهر صفحة إكمال ملفه
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
    return Scaffold(
      backgroundColor: AppColors.kAppBackground,
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: AppColors.kAppBackground, elevation: 0),
      body: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "buyer", child: Text("Buyer")),
                DropdownMenuItem(value: "traveler", child: Text("Traveler")),
              ],
              onChanged: (v) => setState(() => role = v ?? "buyer"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtonStyles.kPrimary,
                onPressed: loading ? null : _handleEmailSignup,
                child: loading ? const CircularProgressIndicator() : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text("or", style: AppTextStyles.kBodyText),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                style: AppButtonStyles.kOutlined,
                onPressed: loading ? null : _handleGoogleSignup,
                label: const Text('Continue with Google'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text("Already have an account? Log In"),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
