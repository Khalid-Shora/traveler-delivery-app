import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Privacy & Security')),
        body: const Center(child: Text('Privacy & security screen')),
      );
}