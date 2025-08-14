// lib/widgets/common/link_input_field.dart

import 'package:flutter/material.dart';

/// Input field for pasting product links with Continue button.
class LinkInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onContinue;

  const LinkInputField({
    Key? key,
    required this.controller,
    this.hintText = 'Paste product link here',
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.grey.shade200,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onContinue,
            child: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
