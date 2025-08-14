// lib/screens/addresses_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../services/user_service.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({Key? key}) : super(key: key);

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Please log in to manage addresses");
      }

      final user = await UserService.getUser(currentUser.uid);
      if (user == null) {
        throw Exception("User profile not found");
      }

      setState(() {
        _user = user;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addAddress() async {
    final newAddress = await _showAddressDialog();
    if (newAddress != null && _user != null) {
      try {
        await UserService.addAddress(_user!.uid, newAddress);
        await _loadUser(); // Refresh
        _showSuccessSnackBar('Address added successfully!');
      } catch (e) {
        _showErrorSnackBar('Error adding address: $e');
      }
    }
  }

  Future<void> _editAddress(int index, Address address) async {
    final updatedAddress = await _showAddressDialog(address: address);
    if (updatedAddress != null && _user != null) {
      try {
        await UserService.updateAddress(_user!.uid, index, updatedAddress);
        await _loadUser(); // Refresh
        _showSuccessSnackBar('Address updated successfully!');
      } catch (e) {
        _showErrorSnackBar('Error updating address: $e');
      }
    }
  }

  Future<void> _deleteAddress(int index, String label) async {
    final confirmed = await _showDeleteConfirmation(label);
    if (confirmed && _user != null) {
      try {
        await UserService.deleteAddress(_user!.uid, index);
        await _loadUser(); // Refresh
        _showSuccessSnackBar('Address deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Error deleting address: $e');
      }
    }
  }

  Future<Address?> _showAddressDialog({Address? address}) async {
    final labelController = TextEditingController(text: address?.label ?? '');
    final countryController = TextEditingController(text: address?.country ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final detailsController = TextEditingController(text: address?.details ?? '');
    final formKey = GlobalKey<FormState>();

    return await showDialog<Address>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        ),
        title: Text(address == null ? 'Add Address' : 'Edit Address'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Home, Work, etc.',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Label is required' : null,
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                TextFormField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Country is required' : null,
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'City is required' : null,
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                TextFormField(
                  controller: streetController,
                  decoration: const InputDecoration(
                    labelText: 'Street',
                    prefixIcon: Icon(Icons.route),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Street is required' : null,
                ),
                const SizedBox(height: AppDimens.kPaddingMedium),
                TextFormField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details (Optional)',
                    hintText: 'Apartment, building, etc.',
                    prefixIcon: Icon(Icons.home),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newAddress = Address(
                  label: labelController.text.trim(),
                  country: countryController.text.trim(),
                  city: cityController.text.trim(),
                  street: streetController.text.trim(),
                  details: detailsController.text.trim(),
                );
                Navigator.pop(context, newAddress);
              }
            },
            style: AppButtonStyles.kPrimary,
            child: Text(address == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String label) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kError),
            child: const Text('Delete'),
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
        title: const Text('My Addresses'),
        centerTitle: true,
      ),
      body: _loading ? _buildLoading() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.kPrimary),
          const SizedBox(height: AppDimens.kPaddingMedium),
          const Text('Loading your addresses...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) return _buildError();
    if (_user?.addresses == null || _user!.addresses!.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadUser,
      color: AppColors.kPrimary,
      child: ListView.separated(
        padding: AppDimens.kScreenPadding,
        itemCount: _user!.addresses!.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.kPaddingMedium),
        itemBuilder: (context, index) {
          final address = _user!.addresses![index];
          return _buildAddressCard(address, index);
        },
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
              'Unable to load addresses',
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

  Widget _buildEmptyState() {
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
                Icons.location_on_outlined,
                size: 60,
                color: AppColors.kAccent,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            Text(
              'No Addresses Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.kPaddingSmall),
            const Text(
              'Add your delivery addresses to make checkout faster',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.kPaddingLarge),
            ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_location),
              label: const Text('Add Your First Address'),
              style: AppButtonStyles.kPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
        boxShadow: AppShadows.kCardShadow,
      ),
      child: Padding(
        padding: AppDimens.kCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on, color: AppColors.kPrimary, size: 20),
                ),
                const SizedBox(width: AppDimens.kPaddingMedium),
                Expanded(
                  child: Text(
                    address.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAddress(index, address);
                        break;
                      case 'delete':
                        _deleteAddress(index, address.label);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.kPaddingMedium),
            Text(
              address.fullAddress,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}