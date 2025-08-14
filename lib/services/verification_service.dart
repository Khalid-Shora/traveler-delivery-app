// lib/services/verification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_model.dart';

class VerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_verifications';

  // Get verification status for a user
  static Future<VerificationModel?> getVerification(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return VerificationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting verification: $e');
      return null;
    }
  }

  // Create new verification record
  static Future<void> createVerification(VerificationModel verification) async {
    try {
      await _firestore.collection(_collection)
          .doc(verification.userId)
          .set(verification.toMap());
    } catch (e) {
      print('Error creating verification: $e');
      rethrow;
    }
  }

  // Update verification status
  static Future<void> updateVerificationStatus({
    required String userId,
    required VerificationStatusEnum status,
    String? reviewNotes,
    String? rejectionReason,
    int? verificationScore,
    String? reviewedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == VerificationStatusEnum.approved) {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['expiresAt'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)), // 1 year expiry
        );
      }

      if (status == VerificationStatusEnum.pending) {
        updateData['submittedAt'] = FieldValue.serverTimestamp();
      }

      if (reviewNotes != null) updateData['reviewNotes'] = reviewNotes;
      if (rejectionReason != null) updateData['rejectionReason'] = rejectionReason;
      if (verificationScore != null) updateData['verificationScore'] = verificationScore;
      if (reviewedBy != null) updateData['reviewedBy'] = reviewedBy;

      await _firestore.collection(_collection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('Error updating verification status: $e');
      rethrow;
    }
  }

  // Submit documents for verification
  static Future<void> submitDocuments({
    required String userId,
    required VerificationDocuments documents,
    ExtractedInfo? extractedInfo,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'documents': documents.toMap(),
        'status': VerificationStatusEnum.pending.name,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (extractedInfo != null) {
        updateData['extractedInfo'] = extractedInfo.toMap();
      }

      await _firestore.collection(_collection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('Error submitting documents: $e');
      rethrow;
    }
  }

  // Get all pending verifications (for admin)
  static Future<List<VerificationModel>> getPendingVerifications() async {
    try {
      final query = await _firestore.collection(_collection)
          .where('status', isEqualTo: VerificationStatusEnum.pending.name)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs.map((doc) =>
          VerificationModel.fromMap(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting pending verifications: $e');
      return [];
    }
  }

  // Check if user needs reverification (expired)
  static Future<bool> needsReverification(String userId) async {
    try {
      final verification = await getVerification(userId);
      if (verification == null) return true;

      return verification.status != VerificationStatusEnum.approved ||
          verification.isExpired;
    } catch (e) {
      print('Error checking reverification: $e');
      return true;
    }
  }

  // Get verification statistics (for admin dashboard)
  static Future<Map<String, int>> getVerificationStats() async {
    try {
      final query = await _firestore.collection(_collection).get();
      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
      };

      for (final doc in query.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'not_started';
        stats['total'] = (stats['total'] ?? 0) + 1;

        if (stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting verification stats: $e');
      return {};
    }
  }
}