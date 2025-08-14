import 'package:flutter/material.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Language Settings')),
        body: const Center(child: Text('Language settings screen')),
      );
}