import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../buyer/buyer_home_screen.dart';
import '../traveler/traveler_home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String? email;
  final String? name; // 👈 هنا استقبل الاسم

  const CompleteProfileScreen({
    Key? key,
    required this.uid,
    this.email,
    this.name,
  }) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  String role = "buyer";
  bool loading = false;
  String error = "";

  @override
  void initState() {
    super.initState();
    nameController.text = widget.name ?? ""; // 👈 عين القيمة الافتراضية لو موجودة
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = ''; });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'email': widget.email,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': role,
        'completedProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Navigate based on role
      if (role == 'buyer') {
        Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kBuyerHome, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, RoutePaths.kTravelerHome, (route) => false);
      }
    } catch (e) {
      setState(() {
        error = "Failed to save: $e";
      });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        backgroundColor: AppColors.kAppBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: AppDimens.kScreenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                "Please provide the missing details to continue",
                style: AppTextStyles.kBodyText.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 28),
              // اسم المستخدم
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 20),
              // رقم الهاتف
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Phone is required";
                  if (v.trim().length < 7) return "Enter a valid phone number";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // الدور
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
              if (error.isNotEmpty)
                Text(error, style: TextStyle(color: Colors.red)),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: AppButtonStyles.kPrimary,
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? CircularProgressIndicator()
                      : Text("Complete Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
