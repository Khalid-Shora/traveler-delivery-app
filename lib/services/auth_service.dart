// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Create initial user document in Firestore
        await UserService.createOrUpdateUser(
          uid: user.uid,
          email: email,
          name: user.displayName,
          roles: ['buyer'], // Default to buyer
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  // Sign in with email and password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Check if user document exists, create if it doesn't
        final userExists = await UserService.userExists(user.uid);
        if (!userExists) {
          await UserService.createOrUpdateUser(
            uid: user.uid,
            email: email,
            name: user.displayName,
            roles: ['buyer'],
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in: $e');
    }
  }

  // Sign in with Google
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if this is a new user or existing user
        final userExists = await UserService.userExists(user.uid);
        if (!userExists) {
          // Create user document for new Google sign-in
          await UserService.createOrUpdateUser(
            uid: user.uid,
            email: user.email!,
            name: user.displayName,
            roles: ['buyer'], // Default to buyer
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during Google sign in: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error sending password reset email: $e');
    }
  }

  // Update user profile
  static Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await UserService.deleteUserAccount(user.uid);

        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  // Check if user document exists in Firestore
  static Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  // Save user to Firestore (for complete profile screen)
  static Future<void> saveUserToFirestore({
    required String uid,
    required String email,
    String? name,
    String? phone,
    String? role,
  }) async {
    try {
      await UserService.createOrUpdateUser(
        uid: uid,
        email: email,
        name: name,
        phone: phone,
        roles: role != null ? [role] : ['buyer'],
      );
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Check if user needs to complete profile
  static Future<bool> needsToCompleteProfile(String uid) async {
    try {
      final userDoc = await getUserDoc(uid);
      if (userDoc == null) return true;

      final completedProfile = userDoc['completedProfile'] as bool?;
      final phone = userDoc['phone'] as String?;
      final role = userDoc['role'] as String?;

      return completedProfile != true ||
          phone == null ||
          phone.isEmpty ||
          role == null ||
          role.isEmpty;
    } catch (e) {
      print('Error checking profile completion: $e');
      return true;
    }
  }

  // Reauthenticate user (needed for sensitive operations)
  static Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reauthenticateWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Reauthentication failed: $e');
    }
  }

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Error sending email verification: $e');
    }
  }

  // Reload user (to check for email verification)
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Error reloading user: $e');
    }
  }
}