// lib/screens/traveler/traveler_verification_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_constants.dart';

class TravelerVerificationPage extends StatefulWidget {
  const TravelerVerificationPage({Key? key}) : super(key: key);

  @override
  State<TravelerVerificationPage> createState() => _TravelerVerificationPageState();
}

class _TravelerVerificationPageState extends State<TravelerVerificationPage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Document Upload
  final Map<String, File?> _uploadedDocuments = {
    'identity_front': null,
    'identity_back': null,
    'selfie': null,
    'address_proof': null,
  };

  final Map<String, String?> _documentUrls = {
    'identity_front': null,
    'identity_back': null,
    'selfie': null,
    'address_proof': null,
  };

  // State
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _verificationData;
  String _verificationStatus = 'not_started'; // not_started, pending, approved, rejected
  String _selectedDocumentType = 'passport'; // passport, national_id, driver_license

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVerificationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationData() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to continue");

      final doc = await FirebaseFirestore.instance
          .collection('user_verifications')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _verificationData = doc.data();
        _verificationStatus = _verificationData!['status'] ?? 'not_started';

        // Populate form fields if data exists
        if (_verificationData!['personalInfo'] != null) {
          final info = _verificationData!['personalInfo'] as Map<String, dynamic>;
          _firstNameController.text = info['firstName'] ?? '';
          _lastNameController.text = info['lastName'] ?? '';
          _dateOfBirthController.text = info['dateOfBirth'] ?? '';
          _nationalityController.text = info['nationality'] ?? '';
          _addressController.text = info['address'] ?? '';
          _phoneController.text = info['phone'] ?? '';
          _selectedDocumentType = info['documentType'] ?? 'passport';
        }

        // Load document URLs if they exist
        if (_verificationData!['documents'] != null) {
          final docs = _verificationData!['documents'] as Map<String, dynamic>;
          _documentUrls.forEach((key, value) {
            _documentUrls[key] = docs[key];
          });
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _uploadedDocuments[documentType] = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromGallery(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _uploadedDocuments[documentType] = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _showImageSourceDialog(String documentType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.kBorderRadiusLarge)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Upload Document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: AppColors.kPrimary),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture document'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(documentType);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: AppColors.kAccent),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(documentType);
              },
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadDocument(String documentType, File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${user.uid}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_verifications')
          .child(user.uid)
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to personal info tab
      return;
    }

    // Check if required documents are uploaded
    final requiredDocs = ['identity_front', 'selfie'];
    for (final docType in requiredDocs) {
      if (_uploadedDocuments[docType] == null && _documentUrls[docType] == null) {
        _showErrorSnackBar('Please upload ${_getDocumentDisplayName(docType)}');
        _tabController.animateTo(1); // Go to documents tab
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Upload new documents
      for (final entry in _uploadedDocuments.entries) {
        if (entry.value != null) {
          final url = await _uploadDocument(entry.key, entry.value!);
          if (url != null) {
            _documentUrls[entry.key] = url;
          }
        }
      }

      // Prepare verification data
      final verificationData = {
        'userId': user.uid,
        'status': 'pending',
        'personalInfo': {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'nationality': _nationalityController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'documentType': _selectedDocumentType,
        },
        'documents': Map<String, String>.from(_documentUrls)
          ..removeWhere((key, value) => value == null),
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user_verifications')
          .doc(user.uid)
          .set(verificationData, SetOptions(merge: true));

      // Update user verification status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'verificationStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _verificationStatus = 'pending';
        _submitting = false;
      });

      _showSuccessSnackBar('Verification submitted successfully! We\'ll review your documents within 2-3 business days.');

    } catch (e) {
      setState(() => _submitting = false);
      _showErrorSnackBar('Error submitting verification: $e');
    }
  }

  String _getDocumentDisplayName(String docType) {
    switch (docType) {
      case 'identity_front':
        return '${_selectedDocumentType == 'passport' ? 'Passport' : 'ID'} (Front)';
      case 'identity_back':
        return 'ID (Back)';
      case 'selfie':
        return 'Selfie Photo';
      case 'address_proof':
        return 'Address Proof';
      default:
        return docType;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Traveler Verification'),
        centerTitle: true,
        elevation: 0,
        bottom: _verificationStatus == 'not_started' || _verificationStatus == 'rejected'
            ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal Info'),
            Tab(text: 'Documents'),
            Tab(text: 'Review'),
          ],
          labelColor: AppColors.kPrimary,
          unselectedLabelColor: AppColors.kText,
          indicatorColor: AppColors.kPrimary,
        )
            : null,
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
          const Text('Loading verification status...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) return _buildError();

    switch (_verificationStatus) {
      case 'pending':
        return _buildPendingStatus();
      case 'approved':
        return _buildApprovedStatus();
      case 'rejected':
        return _buildRejectedStatus();
      default:
        return _buildVerificationForm();
    }
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
              'Unable to load verification data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton(
              onPressed: _loadVerificationData,
              style: AppButtonStyles.kPrimary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingStatus() {
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
                color: AppColors.kWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.hourglass_top,
                size: 60,
                color: AppColors.kWarning,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Verification Pending',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kWarning,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Your documents are being reviewed by our team. This process typically takes 2-3 business days.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                boxShadow: AppShadows.kCardShadow,
              ),
              child: Column(
                children: [
                  Text(
                    'What happens next?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  _buildStepItem('1', 'Document Review', 'Our team verifies your submitted documents'),
                  _buildStepItem('2', 'Identity Verification', 'We confirm your identity matches the documents'),
                  _buildStepItem('3', 'Approval', 'You\'ll receive a notification once approved'),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Submitted on: ${_formatDate(_verificationData?['submittedAt'])}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedStatus() {
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
                color: AppColors.kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.verified_user,
                size: 60,
                color: AppColors.kSuccess,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Verification Approved!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kSuccess,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              'Congratulations! You are now a verified traveler. You can accept delivery requests and start earning.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),

            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.kSuccess),
                      const SizedBox(width: AppDimens.kPaddingSmall),
                      Expanded(
                        child: Text(
                          'Verified Traveler Benefits',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.kSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  _buildBenefitItem('✓', 'Higher earning potential'),
                  _buildBenefitItem('✓', 'Priority order matching'),
                  _buildBenefitItem('✓', 'Verified badge on profile'),
                  _buildBenefitItem('✓', 'Access to premium features'),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.explore),
                label: const Text('Start Discovering Orders'),
                style: AppButtonStyles.kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedStatus() {
    final rejectionReason = _verificationData?['rejectionReason'] ?? 'Documents did not meet our verification requirements.';

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
                color: AppColors.kError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.cancel,
                size: 60,
                color: AppColors.kError,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Verification Rejected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kError,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),

            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              decoration: BoxDecoration(
                color: AppColors.kError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                border: Border.all(color: AppColors.kError.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason for Rejection:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kError,
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingSmall),
                  Text(
                    rejectionReason,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'Don\'t worry! You can resubmit your verification with updated documents.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimens.kPaddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _verificationStatus = 'not_started';
                    // Clear uploaded documents to force re-upload
                    _uploadedDocuments.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Resubmit Verification'),
                style: AppButtonStyles.kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalInfoTab(),
              _buildDocumentsTab(),
              _buildReviewTab(),
            ],
          ),
        ),

        // Bottom Submit Button
        Container(
          padding: AppDimens.kScreenPadding,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitVerification,
                style: AppButtonStyles.kPrimary.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
                ),
                child: _submitting
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
                    const Text(
                      'Submitting...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
                    : const Text(
                  'Submit for Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
        padding: AppDimens.kScreenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary,
                        borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppDimens.kPaddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.kPrimary,
                            ),
                          ),
                          Text(
                            'Please provide accurate information matching your ID',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Form Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'Enter your first name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Enter your last name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'DD/MM/YYYY',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                    firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
                    lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago (minimum age)
                  );
                  if (date != null) {
                    _dateOfBirthController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  hintText: 'Enter your nationality',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nationality is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
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

              const SizedBox(height: AppDimens.kPaddingMedium),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter your full address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Document Type Selection
              Text(
                'Identity Document Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimens.kPaddingMedium),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Passport'),
                      subtitle: const Text('International travel document'),
                      value: 'passport',
                      groupValue: _selectedDocumentType,
                      onChanged: (value) => setState(() => _selectedDocumentType = value!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('National ID Card'),
                      subtitle: const Text('Government-issued ID card'),
                      value: 'national_id',
                      groupValue: _selectedDocumentType,
                      onChanged: (value) => setState(() => _selectedDocumentType = value!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Driver\'s License'),
                      subtitle: const Text('Valid driving license'),
                      value: 'driver_license',
                      groupValue: _selectedDocumentType,
                      onChanged: (value) => setState(() => _selectedDocumentType = value!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),
            ],
          ),
        ),);
    }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: AppDimens.kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.kAccent,
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Icon(Icons.upload_file, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Upload',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kAccent,
                        ),
                      ),
                      Text(
                        'Upload clear, high-quality photos of your documents',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.kAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingLarge),

          // Document Upload Cards
          _buildDocumentUploadCard(
            'identity_front',
            _getDocumentDisplayName('identity_front'),
            'Clear photo of the front side',
            Icons.badge,
            isRequired: true,
          ),

          if (_selectedDocumentType != 'passport') ...[
            const SizedBox(height: AppDimens.kPaddingMedium),
            _buildDocumentUploadCard(
              'identity_back',
              _getDocumentDisplayName('identity_back'),
              'Clear photo of the back side',
              Icons.badge,
              isRequired: false,
            ),
          ],

          const SizedBox(height: AppDimens.kPaddingMedium),
          _buildDocumentUploadCard(
            'selfie',
            'Selfie Photo',
            'Clear selfie holding your ID document',
            Icons.face,
            isRequired: true,
          ),

          const SizedBox(height: AppDimens.kPaddingMedium),
          _buildDocumentUploadCard(
            'address_proof',
            'Address Proof (Optional)',
            'Utility bill, bank statement, or lease agreement',
            Icons.home,
            isRequired: false,
          ),

          const SizedBox(height: AppDimens.kPaddingLarge),

          // Tips Container
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.kInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              border: Border.all(color: AppColors.kInfo.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.kInfo),
                    const SizedBox(width: AppDimens.kPaddingSmall),
                    Text(
                      'Photo Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kInfo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                _buildTipItem('✓', 'Ensure good lighting and avoid shadows'),
                _buildTipItem('✓', 'Keep documents flat and fully visible'),
                _buildTipItem('✓', 'Avoid blurry or tilted photos'),
                _buildTipItem('✓', 'Make sure all text is clearly readable'),
                _buildTipItem('✓', 'For selfies, hold your ID next to your face'),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingXLarge),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(String docType, String title, String description, IconData icon, {required bool isRequired}) {
    final hasFile = _uploadedDocuments[docType] != null;
    final hasUrl = _documentUrls[docType] != null;
    final isUploaded = hasFile || hasUrl;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        border: Border.all(
          color: isUploaded
              ? AppColors.kSuccess
              : (isRequired ? AppColors.kWarning.withValues(alpha: 0.5) : Theme.of(context).dividerColor),
          width: isUploaded ? 2 : 1,
        ),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppColors.kSuccess.withValues(alpha: 0.1)
                        : AppColors.kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle : icon,
                    color: isUploaded ? AppColors.kSuccess : AppColors.kAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(color: AppColors.kError, fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.kPaddingMedium),

            if (isUploaded) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.kSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.kSuccess, size: 16),
                    const SizedBox(width: AppDimens.kPaddingSmall),
                    Text(
                      'Document uploaded successfully',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showImageSourceDialog(docType),
                      child: const Text('Replace'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourceDialog(docType),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Upload Document'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingLarge),
                    side: BorderSide(
                      color: isRequired ? AppColors.kWarning : AppColors.kPrimary,
                      width: 1.5,
                    ),
                    foregroundColor: isRequired ? AppColors.kWarning : AppColors.kPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: AppDimens.kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.kPaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess,
                    borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  ),
                  child: Icon(Icons.preview, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & Submit',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.kSuccess,
                        ),
                      ),
                      Text(
                        'Please review your information before submitting',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.kSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingLarge),

          // Personal Information Review
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              boxShadow: AppShadows.kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                _buildReviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'),
                _buildReviewItem('Date of Birth', _dateOfBirthController.text),
                _buildReviewItem('Nationality', _nationalityController.text),
                _buildReviewItem('Phone', _phoneController.text),
                _buildReviewItem('Address', _addressController.text),
                _buildReviewItem('Document Type', _selectedDocumentType.replaceAll('_', ' ').toUpperCase()),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingMedium),

          // Documents Review
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              boxShadow: AppShadows.kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploaded Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),

                ..._uploadedDocuments.entries.where((entry) => entry.value != null || _documentUrls[entry.key] != null).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.kSuccess, size: 16),
                        const SizedBox(width: AppDimens.kPaddingSmall),
                        Text(_getDocumentDisplayName(entry.key)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingLarge),

          // Terms and Conditions
          Container(
            padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.kInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
              border: Border.all(color: AppColors.kInfo.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.kInfo,
                  ),
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                Text(
                  'By submitting this verification, you agree to:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimens.kPaddingSmall),
                _buildTermItem('• Provide accurate and truthful information'),
                _buildTermItem('• Allow us to verify your identity through third-party services'),
                _buildTermItem('• Comply with our traveler terms and conditions'),
                _buildTermItem('• Maintain the security of your account'),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.kPaddingXLarge),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.kPaddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.kPaddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
      child: Row(
        children: [
          Text(
            bullet,
            style: TextStyle(
              color: AppColors.kSuccess,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppDimens.kPaddingSmall),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildTipItem(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bullet,
            style: TextStyle(
              color: AppColors.kInfo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppDimens.kPaddingSmall),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.kPaddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown';
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}