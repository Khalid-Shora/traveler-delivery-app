// lib/widgets/buyer_discover/link_intro_card.dart

import 'package:flutter/material.dart';
import '../common/link_input_field.dart';

class LinkIntroCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onContinue;

  const LinkIntroCard({
    Key? key,
    required this.controller,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = const TextStyle(fontWeight: FontWeight.bold);
    TextStyle descStyle = TextStyle(color: Colors.grey.shade600, fontSize: 13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Title
          const SizedBox(height: 16),
          const Text(
            "Shop from any international store through our app. Just share the product link!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Features List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _featureItem(Icons.shopping_bag, "Shop Anywhere", "Share product links from any international store, and we'll handle the purchase for you", titleStyle, descStyle),
            ],
          ),

          const SizedBox(height: 24),

          // Link Input
          LinkInputField(
            controller: controller,
            onContinue: onContinue,
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String desc, TextStyle titleStyle, TextStyle descStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 4),
                Text(desc, style: descStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
