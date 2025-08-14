// lib/services/withdrawal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_model.dart';

class WithdrawalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'withdrawals';

  // Create a new withdrawal request
  static Future<String> createWithdrawal(WithdrawalModel withdrawal) async {
    try {
      final docRef = await _firestore.collection(_collection).add(withdrawal.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating withdrawal: $e');
      rethrow;
    }
  }

  // Get withdrawal by ID
  static Future<WithdrawalModel?> getWithdrawal(String withdrawalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(withdrawalId).get();
      if (doc.exists && doc.data() != null) {
        return WithdrawalModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting withdrawal: $e');
      return null;
    }
  }

  // Get all withdrawals for a traveler
  static Future<List<WithdrawalModel>> getTravelerWithdrawals(String travelerId) async {
    try {
      final query = await _firestore.collection(_collection)
          .where('travelerId', isEqualTo: travelerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) =>
          WithdrawalModel.fromMap(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting traveler withdrawals: $e');
      return [];
    }
  }

  // Update withdrawal status
  static Future<void> updateWithdrawalStatus({
    required String withdrawalId,
    required WithdrawalStatus status,
    String? transactionId,
    ProcessorResponse? processorResponse,
    String? adminNotes,
    String? failureReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (status) {
        case WithdrawalStatus.processing:
          updateData['processedAt'] = FieldValue.serverTimestamp();
          break;
        case WithdrawalStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case WithdrawalStatus.failed:
        case WithdrawalStatus.cancelled:
        // Keep timestamps as they are
          break;
        case WithdrawalStatus.pending:
        // Reset processing timestamps
          updateData['processedAt'] = null;
          updateData['completedAt'] = null;
          break;
      }

      if (transactionId != null) updateData['transactionId'] = transactionId;
      if (processorResponse != null) updateData['processorResponse'] = processorResponse.toMap();
      if (adminNotes != null) updateData['adminNotes'] = adminNotes;
      if (failureReason != null) updateData['failureReason'] = failureReason;

      await _firestore.collection(_collection)
          .doc(withdrawalId)
          .update(updateData);
    } catch (e) {
      print('Error updating withdrawal status: $e');
      rethrow;
    }
  }

  // Cancel withdrawal (if still pending)
  static Future<void> cancelWithdrawal(String withdrawalId) async {
    try {
      await updateWithdrawalStatus(
        withdrawalId: withdrawalId,
        status: WithdrawalStatus.cancelled,
      );
    } catch (e) {
      print('Error cancelling withdrawal: $e');
      rethrow;
    }
  }

  // Get pending withdrawals (for admin)
  static Future<List<WithdrawalModel>> getPendingWithdrawals() async {
    try {
      final query = await _firestore.collection(_collection)
          .where('status', isEqualTo: WithdrawalStatus.pending.name)
          .orderBy('requestedAt', descending: false) // Oldest first
          .get();

      return query.docs.map((doc) =>
          WithdrawalModel.fromMap(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error getting pending withdrawals: $e');
      return [];
    }
  }

  // Calculate available balance for traveler
  static Future<double> getAvailableBalance(String travelerId) async {
    try {
      // Get completed orders earnings
      final ordersQuery = await _firestore.collection('orders')
          .where('travelerId', isEqualTo: travelerId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double totalEarnings = 0.0;
      for (final doc in ordersQuery.docs) {
        final order = doc.data();
        final reward = (order['reward'] as num?)?.toDouble() ?? 0.0;
        final orderTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
        final commission = reward > 0 ? reward : orderTotal * 0.10;
        totalEarnings += commission;
      }

      // Subtract completed withdrawals
      final withdrawalsQuery = await _firestore.collection(_collection)
          .where('travelerId', isEqualTo: travelerId)
          .where('status', isEqualTo: WithdrawalStatus.completed.name)
          .get();

      double totalWithdrawn = 0.0;
      for (final doc in withdrawalsQuery.docs) {
        final withdrawal = doc.data();
        totalWithdrawn += (withdrawal['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Subtract pending withdrawals
      final pendingQuery = await _firestore.collection(_collection)
          .where('travelerId', isEqualTo: travelerId)
          .where('status', whereIn: [WithdrawalStatus.pending.name, WithdrawalStatus.processing.name])
          .get();

      double totalPending = 0.0;
      for (final doc in pendingQuery.docs) {
        final withdrawal = doc.data();
        totalPending += (withdrawal['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return totalEarnings - totalWithdrawn - totalPending;
    } catch (e) {
      print('Error calculating available balance: $e');
      return 0.0;
    }
  }

  // Get withdrawal statistics for traveler
  static Future<Map<String, dynamic>> getTravelerWithdrawalStats(String travelerId) async {
    try {
      final withdrawals = await getTravelerWithdrawals(travelerId);

      double totalWithdrawn = 0.0;
      double totalPending = 0.0;
      int completedCount = 0;
      int pendingCount = 0;

      for (final withdrawal in withdrawals) {
        switch (withdrawal.status) {
          case WithdrawalStatus.completed:
            totalWithdrawn += withdrawal.amount;
            completedCount++;
            break;
          case WithdrawalStatus.pending:
          case WithdrawalStatus.processing:
            totalPending += withdrawal.amount;
            pendingCount++;
            break;
          default:
            break;
        }
      }

      final availableBalance = await getAvailableBalance(travelerId);

      return {
        'totalWithdrawn': totalWithdrawn,
        'totalPending': totalPending,
        'availableBalance': availableBalance,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'totalWithdrawals': withdrawals.length,
      };
    } catch (e) {
      print('Error getting withdrawal stats: $e');
      return {};
    }
  }

  // Get withdrawal statistics (for admin dashboard)
  static Future<Map<String, dynamic>> getWithdrawalStats() async {
    try {
      final query = await _firestore.collection(_collection).get();

      final stats = <String, dynamic>{
        'total': 0,
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'failed': 0,
        'cancelled': 0,
        'totalAmount': 0.0,
        'completedAmount': 0.0,
        'pendingAmount': 0.0,
      };

      for (final doc in query.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        stats['total'] = (stats['total'] as int) + 1;
        stats['totalAmount'] = (stats['totalAmount'] as double) + amount;

        switch (status) {
          case 'completed':
            stats['completed'] = (stats['completed'] as int) + 1;
            stats['completedAmount'] = (stats['completedAmount'] as double) + amount;
            break;
          case 'pending':
            stats['pending'] = (stats['pending'] as int) + 1;
            stats['pendingAmount'] = (stats['pendingAmount'] as double) + amount;
            break;
          case 'processing':
            stats['processing'] = (stats['processing'] as int) + 1;
            stats['pendingAmount'] = (stats['pendingAmount'] as double) + amount;
            break;
          case 'failed':
            stats['failed'] = (stats['failed'] as int) + 1;
            break;
          case 'cancelled':
            stats['cancelled'] = (stats['cancelled'] as int) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting withdrawal stats: $e');
      return {};
    }
  }
}