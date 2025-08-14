// lib/screens/add_card_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class AddCardPage extends StatefulWidget {
  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _saving = false;
  String? _cardBrand;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_detectCardBrand);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _detectCardBrand() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    String? brand;

    if (cardNumber.startsWith('4')) {
      brand = 'Visa';
    } else if (cardNumber.startsWith(RegExp(r'^5[1-5]')) ||
        cardNumber.startsWith(RegExp(r'^2[2-7]'))) {
      brand = 'Mastercard';
    } else if (cardNumber.startsWith(RegExp(r'^3[47]'))) {
      brand = 'American Express';
    } else if (cardNumber.startsWith('6011') ||
        cardNumber.startsWith(RegExp(r'^65'))) {
      brand = 'Discover';
    }

    if (brand != _cardBrand) {
      setState(() {
        _cardBrand = brand;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to add a payment method");

      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiry = _expiryController.text.split('/');

      // In a real app, you would tokenize the card with Stripe or another payment processor
      // For now, we'll just store basic card info (NEVER store actual card numbers in production!)
      final cardData = {
        'brand': _cardBrand?.toLowerCase() ?? 'unknown',
        'last4': cardNumber.substring(cardNumber.length - 4),
        'expMonth': expiry[0].padLeft(2, '0'),
        'expYear': '20${expiry[1]}',
        'cardholderName': _nameController.text.trim(),
        'isDefault': _isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // If this is the first card, make it default
      final existingCardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .get();

      if (existingCardsSnapshot.docs.isEmpty) {
        cardData['isDefault'] = true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .add(cardData);

      // If setting as default, update other cards
      if (_isDefault && existingCardsSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in existingCardsSnapshot.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment method added successfully!'),
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
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment method: $e'),
            backgroundColor: AppColors.kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppDimens.kScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Preview
              _buildCardPreview(),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Security Info
              Container(
                padding: const EdgeInsets.all(AppDimens.kPaddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.kInfo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadiusSmall),
                  border: Border.all(color: AppColors.kInfo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppColors.kInfo, size: 20),
                    const SizedBox(width: AppDimens.kPaddingSmall),
                    Expanded(
                      child: Text(
                        'Your payment information is encrypted and secure',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.kInfo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Card Number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _cardBrand != null
                      ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getBrandColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _cardBrand!.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getBrandColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                      : null,
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Card number is required';
                  }
                  final cleanNumber = value.replaceAll(' ', '');
                  if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                    return 'Enter a valid card number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // Expiry and CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ExpiryDateFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Expiry date is required';
                        }
                        if (value.length != 5) {
                          return 'Enter MM/YY format';
                        }
                        final parts = value.split('/');
                        final month = int.tryParse(parts[0]);
                        final year = int.tryParse('20${parts[1]}');

                        if (month == null || month < 1 || month > 12) {
                          return 'Invalid month';
                        }

                        if (year == null || year < DateTime.now().year) {
                          return 'Card has expired';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimens.kPaddingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CVV is required';
                        }
                        if (value.length < 3) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // Cardholder Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cardholder name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.kPaddingLarge),

              // Set as Default
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.kBorderRadius),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  title: const Text('Set as default payment method'),
                  subtitle: const Text('Use this card for future purchases'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.kPrimary,
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingXLarge),

              // Add Card Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveCard,
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
                      const Text(
                        'Adding Card...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                      : const Text(
                    'Add Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.kPaddingMedium),

              // Disclaimer
              Text(
                'By adding this payment method, you agree to our Terms of Service and Privacy Policy.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    final theme = Theme.of(context);
    final cardNumber = _cardNumberController.text.isNotEmpty
        ? _cardNumberController.text
        : '•••• •••• •••• ••••';
    final expiry = _expiryController.text.isNotEmpty
        ? _expiryController.text
        : '••/••';
    final name = _nameController.text.isNotEmpty
        ? _nameController.text.toUpperCase()
        : 'CARDHOLDER NAME';

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: AppDimens.kPaddingMedium),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getBrandColor().withValues(alpha: 0.8),
                _getBrandColor(),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card brand and chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  if (_cardBrand != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _cardBrand!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Name and expiry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARDHOLDER NAME',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'EXPIRES',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        expiry,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBrandColor() {
    switch (_cardBrand?.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'american express':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6000);
      default:
        return AppColors.kPrimary;
    }
  }
}

// Custom formatters for card input
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2 ? text.substring(2, text.length > 4 ? 4 : text.length) : '';
      final formattedText = year.isNotEmpty ? '$month/$year' : month;

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}