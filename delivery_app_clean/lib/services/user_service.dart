// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      print('Error getting user: $e');
      throw Exception('Failed to load user data: $e');
    }
  }

  // Get current authenticated user
  static Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      return await getUser(currentUser.uid);
    } catch (e) {
      print('Error getting current user: $e');
      throw Exception('Failed to load current user: $e');
    }
  }

  // Update user fields
  static Future<void> updateUserFields(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Update user profile
  static Future<void> updateUser(String uid, UserModel user) async {
    try {
      await _firestore.collection('users').doc(uid).update(user.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Create or update user (for initial setup)
  static Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? name,
    String? phone,
    List<String>? roles,
  }) async {
    try {
      final userData = {
        'email': email,
        'name': name ?? '',
        'phone': phone ?? '',
        'roles': roles ?? ['buyer'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'verified': false,
        'completedProfile': true,
      };

      await _firestore.collection('users').doc(uid).set(
        userData,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error creating/updating user: $e');
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Address management
  static Future<void> addAddress(String uid, Address address) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);

      await userRef.update({
        'addresses': FieldValue.arrayUnion([address.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('Failed to add address: $e');
    }
  }

  static Future<void> updateAddress(String uid, int index, Address address) async {
    try {
      // Get current user
      final user = await getUser(uid);
      if (user?.addresses == null) {
        throw Exception('No addresses found');
      }

      // Update the address at the specified index
      final addresses = List<Address>.from(user!.addresses!);
      if (index >= addresses.length) {
        throw Exception('Address index out of range');
      }

      addresses[index] = address;

      // Update the entire addresses array
      await _firestore.collection('users').doc(uid).update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('Failed to update address: $e');
    }
  }

  static Future<void> deleteAddress(String uid, int index) async {
    try {
      // Get current user
      final user = await getUser(uid);
      if (user?.addresses == null) {
        throw Exception('No addresses found');
      }

      // Remove the address at the specified index
      final addresses = List<Address>.from(user!.addresses!);
      if (index >= addresses.length) {
        throw Exception('Address index out of range');
      }

      addresses.removeAt(index);

      // Update the addresses array
      await _firestore.collection('users').doc(uid).update({
        'addresses': addresses.map((addr) => addr.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('Failed to delete address: $e');
    }
  }

  // Check if user exists
  static Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Get user statistics (for profile pages)
  static Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      // Get orders as buyer
      final buyerOrdersSnapshot = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .get();

      // Get orders as traveler
      final travelerOrdersSnapshot = await _firestore
          .collection('orders')
          .where('travelerId', isEqualTo: uid)
          .get();

      // Get trips
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('travelerId', isEqualTo: uid)
          .get();

      return {
        'totalOrdersAsBuyer': buyerOrdersSnapshot.docs.length,
        'totalOrdersAsTraveler': travelerOrdersSnapshot.docs.length,
        'totalTrips': tripsSnapshot.docs.length,
        'activeTrips': tripsSnapshot.docs.where((doc) =>
        doc.data()['status'] == 'active').length,
        'completedTrips': tripsSnapshot.docs.where((doc) =>
        doc.data()['status'] == 'completed').length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount(String uid) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(uid).delete();

      // Delete user verification
      await _firestore.collection('user_verifications').doc(uid).delete();

      // Delete user's payment methods
      final paymentMethods = await _firestore
          .collection('users')
          .doc(uid)
          .collection('payment_methods')
          .get();

      for (final doc in paymentMethods.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user account: $e');
      throw Exception('Failed to delete user account: $e');
    }
  }
}