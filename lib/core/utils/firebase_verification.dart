// lib/core/utils/firebase_verification.dart
// Use this to test Firebase connection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseVerification {
  static Future<Map<String, bool>> verifyFirebaseSetup() async {
    final results = <String, bool>{};

    try {
      // 1. Test Firestore Connection
      await FirebaseFirestore.instance
          .collection('test')
          .doc('test')
          .set({'timestamp': FieldValue.serverTimestamp()});
      results['firestore'] = true;
      print('✅ Firestore: Connected');
    } catch (e) {
      results['firestore'] = false;
      print('❌ Firestore: Failed - $e');
    }

    try {
      // 2. Test Authentication
      final authMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail('test@example.com');
      results['auth'] = true;
      print('✅ Authentication: Working');
    } catch (e) {
      results['auth'] = false;
      print('❌ Authentication: Failed - $e');
    }

    try {
      // 3. Test Collections Access
      final users = await FirebaseFirestore.instance.collection('users').limit(1).get();
      results['collections'] = true;
      print('✅ Collections: Accessible');
    } catch (e) {
      results['collections'] = false;
      print('❌ Collections: Failed - $e');
    }

    return results;
  }

  static Widget buildVerificationScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Verification')),
      body: FutureBuilder<Map<String, bool>>(
        future: verifyFirebaseSetup(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _VerificationTile(
                  title: 'Firestore Database',
                  isWorking: results['firestore'] ?? false,
                  description: 'Database connection and write permissions',
                ),
                _VerificationTile(
                  title: 'Authentication',
                  isWorking: results['auth'] ?? false,
                  description: 'Email/Password and Google sign-in',
                ),
                _VerificationTile(
                  title: 'Collections Access',
                  isWorking: results['collections'] ?? false,
                  description: 'Reading from Firestore collections',
                ),
                const SizedBox(height: 32),
                if (results.values.every((v) => v))
                  const Card(
                    color: Colors.green,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '🎉 All Firebase services are working!',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                else
                  const Card(
                    color: Colors.red,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '⚠️ Some Firebase services need attention',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final String title;
  final bool isWorking;
  final String description;

  const _VerificationTile({
    required this.title,
    required this.isWorking,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          isWorking ? Icons.check_circle : Icons.error,
          color: isWorking ? Colors.green : Colors.red,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Text(
          isWorking ? 'Working' : 'Failed',
          style: TextStyle(
            color: isWorking ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}