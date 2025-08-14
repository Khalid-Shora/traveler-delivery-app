import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Notifications screen')),
      );
}