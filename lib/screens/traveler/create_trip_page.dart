// lib/screens/traveler/create_trip_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_constants.dart';

class CreateTripPage extends StatefulWidget {
  final Map<String, dynamic>? existingTrip;

  const CreateTripPage({Key? key, this.existingTrip}) : super(key: key);

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _departureDate;
  DateTime? _arrivalDate;
  bool _saving = false;
  String? _error;

  // Popular destinations for quick selection
  final popularDestinations = [
    'New York, USA',
    'London, UK',
    'Paris, France',
    'Tokyo, Japan',
    'Dubai, UAE',
    'Los Angeles, USA',
    'Sydney, Australia',
    'Singapore',
    'Hong Kong',
    'Toronto, Canada',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      _loadExistingTrip();
    }
  }

  void _loadExistingTrip() {
    final trip = widget.existingTrip!;
    _fromController.text = trip['from'] ?? '';
    _toController.text = trip['to'] ?? '';
    _capacityController.text = trip['availableWeight']?.toString() ?? '';
    _notesController.text = trip['notes'] ?? '';

    if (trip['departDate'] != null) {
      _departureDate = (trip['departDate'] as Timestamp).toDate();
    }
    if (trip['arriveDate'] != null) {
      _arrivalDate = (trip['arriveDate'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final initialDate = isDeparture ? _departureDate : _arrivalDate;
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = pickedDate;
          // If arrival date is before departure date, clear it
          if (_arrivalDate != null && _arrivalDate!.isBefore(pickedDate)) {
            _arrivalDate = null;
          }
        } else {
          _arrivalDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_departureDate == null) {
      setState(() => _error = "Please select a departure date");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to continue");

      final tripData = {
        'from': _fromController.text.trim(),
        'to': _toController.text.trim(),
        'departDate': Timestamp.fromDate(_departureDate!),
        'arriveDate': _arrivalDate != null ? Timestamp.fromDate(_arrivalDate!) : null,
        'availableWeight': double.parse(_capacityController.text.trim()),
        'notes': _notesController.text.trim(),
        'travelerId': user.uid,
        'status': 'active',
        'orders': [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.existingTrip != null) {
        // Update existing trip
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.existingTrip!['tripId'])
            .update(tripData);
      } else {
        // Create new trip
        tripData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance
            .collection('trips')
            .add(tripData);

        // Update with trip ID
        await docRef.update({'tripId': docRef.id});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingTrip != null ? 'Trip updated successfully!' : 'Trip created successfully!'),
            backgroundColor: AppColors.kSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  void _showDestinationPicker(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.kBorderRadiusLarge)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppDimens.kPaddingMedium),
                  Text(
                    'Popular Destinations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.kPaddingLarge),
                itemCount: popularDestinations.length,
                itemBuilder: (context, index) {
                  final destination = popularDestinations[index];
                  return ListTile(
                    onTap: () {
                      controller.text = destination;
                      Navigator.pop(context);
                    },
                    leading: Icon(Icons.location_on, color: AppColors.kAccent),
                    title: Text(destination),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingTrip != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Trip' : 'Create New Trip'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppDimens.kScreenPadding,
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
                            child: Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: AppDimens.kPaddingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Update Your Trip' : 'Plan Your Journey',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kPrimary,
                                  ),
                                ),
                                Text(
                                  'Help others get products from your destination',
                                  style: theme.textTheme.bodyMedium?.copyWith(
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

                    // From Location
                    _buildSectionHeader('From', Icons.flight_takeoff),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    TextFormField(
                      controller: _fromController,
                      decoration: InputDecoration(
                        hintText: 'Enter departure city/country',
                        prefixIcon: Icon(Icons.location_on, color: AppColors.kAccent),
                        suffixIcon: IconButton(
                          onPressed: () => _showDestinationPicker(_fromController),
                          icon: Icon(Icons.list, color: AppColors.kPrimary),
                          tooltip: 'Choose from popular destinations',
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter departure location';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // To Location
                    _buildSectionHeader('To', Icons.flight_land),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    TextFormField(
                      controller: _toController,
                      decoration: InputDecoration(
                        hintText: 'Enter destination city/country',
                        prefixIcon: Icon(Icons.location_on, color: AppColors.kPrimary),
                        suffixIcon: IconButton(
                          onPressed: () => _showDestinationPicker(_toController),
                          icon: Icon(Icons.list, color: AppColors.kPrimary),
                          tooltip: 'Choose from popular destinations',
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter destination location';
                        }
                        if (value.trim().toLowerCase() == _fromController.text.trim().toLowerCase()) {
                          return 'Destination must be different from departure';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Dates Section
                    _buildSectionHeader('Travel Dates', Icons.calendar_today),
                    const SizedBox(height: AppDimens.kPaddingMedium),

                    Row(
                      children: [
                        // Departure Date
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.flight_takeoff, color: AppColors.kAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Departure',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _departureDate != null
                                        ? _formatDate(_departureDate!)
                                        : 'Select date',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _departureDate != null ? null : AppColors.kPlaceholder,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: AppDimens.kPaddingMedium),

                        // Arrival Date
                        Expanded(
                          child: InkWell(
                            onTap: _departureDate != null ? () => _selectDate(context, false) : null,
                            child: Container(
                              padding: const EdgeInsets.all(AppDimens.kPaddingLarge),
                              decoration: BoxDecoration(
                                color: _departureDate != null ? theme.cardColor : theme.disabledColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flight_land,
                                        color: _departureDate != null ? AppColors.kPrimary : AppColors.kDisabled,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Arrival',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: _departureDate != null
                                              ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                                              : AppColors.kDisabled,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _arrivalDate != null
                                        ? _formatDate(_arrivalDate!)
                                        : 'Optional',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _arrivalDate != null
                                          ? null
                                          : (_departureDate != null ? AppColors.kPlaceholder : AppColors.kDisabled),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Capacity
                    _buildSectionHeader('Available Capacity', Icons.luggage),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'How much weight can you carry?',
                        prefixIcon: Icon(Icons.scale, color: AppColors.kAccent),
                        suffixText: 'kg',
                        suffixStyle: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter available capacity';
                        }
                        final weight = double.tryParse(value.trim());
                        if (weight == null || weight <= 0) {
                          return 'Please enter a valid weight';
                        }
                        if (weight > 50) {
                          return 'Maximum capacity is 50kg';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimens.kPaddingSmall),

                    Container(
                      padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.kInfo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.kInfo, size: 16),
                          const SizedBox(width: AppDimens.kPaddingSmall),
                          Expanded(
                            child: Text(
                              'Consider your luggage allowance and personal items when setting capacity',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.kInfo),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.kPaddingLarge),

                    // Notes
                    _buildSectionHeader('Additional Notes', Icons.note),
                    const SizedBox(height: AppDimens.kPaddingMedium),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any special instructions or restrictions? (Optional)',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.note_alt, color: AppColors.kAccent),
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                    ),

                    // Error Display
                    if (_error != null) ...[
                      const SizedBox(height: AppDimens.kPaddingMedium),
                      Container(
                        padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.kError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                          border: Border.all(color: AppColors.kError.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.kError, size: 20),
                            const SizedBox(width: AppDimens.kPaddingSmall),
                            Expanded(
                              child: Text(
                                _error!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.kError),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimens.kPaddingXLarge),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Container(
              padding: AppDimens.kScreenPadding,
              decoration: BoxDecoration(
                color: theme.cardColor,
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
                    onPressed: _saving ? null : _saveTrip,
                    style: AppButtonStyles.kPrimary.copyWith(
                      minimumSize: MaterialStateProperty.all(const Size(double.infinity, 56)),
                    ),
                    child: _saving
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
                        Text(
                          isEditing ? 'Updating Trip...' : 'Creating Trip...',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditing ? Icons.update : Icons.add, size: 20),
                        const SizedBox(width: AppDimens.kPaddingSmall),
                        Text(
                          isEditing ? 'Update Trip' : 'Create Trip',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}