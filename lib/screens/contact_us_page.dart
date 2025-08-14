import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Contact Us')),
        body: const Center(child: Text('Contact us screen')),
      );
}