// lib/screens/personal_info_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _hasChanges = false;
  String? _originalName;
  String? _originalPhone;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Please log in to edit your profile");
      }

      final user = await UserService.getUser(currentUser.uid);
      if (user == null) {
        throw Exception("User profile not found");
      }

      setState(() {
        _user = user;
        _nameController.text = user.name ?? '';
        _emailController.text = user.email;
        _phoneController.text = user.phone;

        // Store original values for change detection
        _originalName = user.name ?? '';
        _originalPhone = user.phone;

        _loading = false;
        _error = null;
      });

      // Listen for changes
      _nameController.addListener(_checkForChanges);
      _phoneController.addListener(_checkForChanges);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text.trim() != _originalName ||
        _phoneController.text.trim() != _originalPhone;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() => _saving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Please log in to save changes");

      // Update user data
      await UserService.updateUserFields(currentUser.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update original values
      setState(() {
        _originalName = _nameController.text.trim();
        _originalPhone = _phoneController.text.trim();
        _hasChanges = false;
        _saving = false;
      });

      _showSuccessSnackBar('Profile updated successfully!');

      // Go back to previous page
      Navigator.pop(context, true); // Return true to indicate changes were made
    } catch (e) {
      setState(() => _saving = false);
      _showErrorSnackBar('Error saving changes: $e');
    }
  }

  Future<void> _changePassword() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser.email!);
      _showSuccessSnackBar('Password reset email sent to ${currentUser.email}');
    } catch (e) {
      _showErrorSnackBar('Error sending password reset email: $e');
    }
  }

  Future<void> _verifyPhoneNumber() async {
    // TODO: Implement phone verification
    _showInfoSnackBar('Phone verification coming soon!');
  }

  Future<void> _changeEmail() async {
    // TODO: Implement email change flow
    _showInfoSnackBar('Email change feature coming soon!');
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kInfo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personal Information'),
        centerTitle: true,
        actions: [
          if (_hasChanges && !_loading)
            TextButton(
              onPressed: _saving ? null : _saveChanges,
              child: _saving
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.kPrimary,
                  ),
                ),
              )
                  : Text(
                'Save',
                style: TextStyle(
                  color: AppColors.kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.kPrimary),
          const SizedBox(height: AppDimens.kPaddingMedium),
          const Text('Loading your profile...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) return _buildError();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppDimens.kScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                boxShadow: AppShadows.kCardShadow,
              ),
              child: Row(
                children: [
                  // Profile Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppColors.kPrimary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: _user?.name?.isNotEmpty == true
                        ? Center(
                      child: Text(
                        _getInitials(_user!.name!),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.kPrimary,
                    ),
                  ),

                  const SizedBox(width: AppDimens.kPaddingLarge),

                  // Profile Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.name?.isNotEmpty == true ? _user!.name! : 'No Name Set',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'No Email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.kAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _user?.roles.join(' & ').toUpperCase() ?? 'USER',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.kAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Picture Button
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Implement profile picture upload
                          _showInfoSnackBar('Profile picture upload coming soon!');
                        },
                        icon: Icon(
                          Icons.camera_alt,
                          color: AppColors.kPrimary,
                        ),
                        tooltip: 'Change Picture',
                      ),
                      Text(
                        'Change',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Basic Information Section
            _buildSectionHeader('Basic Information', Icons.person),
            const SizedBox(height: AppDimens.kPaddingMedium),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: IconButton(
                  onPressed: _verifyPhoneNumber,
                  icon: Icon(
                    Icons.verified,
                    color: AppColors.kSuccess,
                  ),
                  tooltip: 'Verify Phone',
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 7) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // Account Security Section
            _buildSectionHeader('Account Security', Icons.security),
            const SizedBox(height: AppDimens.kPaddingMedium),

            // Email Field (Read-only)
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                suffixIcon: TextButton(
                  onPressed: _changeEmail,
                  child: const Text('Change'),
                ),
                filled: true,
                fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            // Change Password Card
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.kWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_outline, color: AppColors.kWarning, size: 20),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Last changed: Unknown',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _changePassword,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kWarning,
                      side: BorderSide(color: AppColors.kWarning),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),

            // App Preferences Section
            _buildSectionHeader('Preferences', Icons.settings),
            const SizedBox(height: AppDimens.kPaddingMedium),

            // Language Setting
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.language, color: AppColors.kAccent, size: 20),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'English (Default)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RoutePaths.kLanguageSettings);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingXLarge),

            // Save Changes Button (if there are changes)
            if (_hasChanges)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.kSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                  border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'You have unsaved changes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reset form
                              _nameController.text = _originalName ?? '';
                              _phoneController.text = _originalPhone ?? '';
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kError,
                              side: BorderSide(color: AppColors.kError),
                            ),
                            child: const Text('Discard'),
                          ),
                        ),
                        const SizedBox(width: AppDimens.kPaddingMedium),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveChanges,
                            style: AppButtonStyles.kPrimary,
                            child: _saving
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Saving...'),
                              ],
                            )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppDimens.kPaddingXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppDimens.kScreenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.kError),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadUser,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.kPrimary, size: 18),
        ),
        const SizedBox(width: AppDimens.kPaddingMedium),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimary,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}