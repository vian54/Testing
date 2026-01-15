import 'package:cloud_firestore/cloud_firestore.dart';

class CashflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double PLATFORM_FEE_PERCENTAGE = 0.07; // 7%

  // ⭐ CREATE TRANSACTION
  Future<void> createTransaction({
    required String projectId,
    required String fromUserId,
    required String toUserId,
    required String type,
    required double amount,
  }) async {
    // Hitung platform fee
    double platformFee = type == 'payment'
        ? amount * PLATFORM_FEE_PERCENTAGE
        : 0;
    double netAmount = amount - platformFee;

    await _firestore.collection('transactions').add({
      'projectId': projectId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'type': type,
      'amount': amount,
      'platformFee': platformFee,
      'netAmount': netAmount,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ⭐ APPROVE PROJECT & RELEASE PAYMENT
  Future<void> approveProjectAndPay({
    required String projectId,
    required String clientId,
    required String freelancerId,
    required double budget,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1. Hitung fee
      double platformFee = budget * PLATFORM_FEE_PERCENTAGE;
      double freelancerAmount = budget - platformFee;

      // 2. Create transaction
      await createTransaction(
        projectId: projectId,
        fromUserId: clientId,
        toUserId: freelancerId,
        type: 'payment',
        amount: budget,
      );

      // 3. Update freelancer balance
      DocumentReference freelancerRef = _firestore
          .collection('users')
          .doc(freelancerId);
      batch.update(freelancerRef, {
        'balance': FieldValue.increment(freelancerAmount),
        'totalEarnings': FieldValue.increment(freelancerAmount),
        'completedProjects': FieldValue.increment(1),
      });

      // 4. Update project status
      DocumentReference projectRef = _firestore
          .collection('projects')
          .doc(projectId);
      batch.update(projectRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print('Error approving project: $e');
      rethrow;
    }
  }

  // ⭐ WITHDRAWAL (Simulasi)
  Future<void> requestWithdrawal({
    required String userId,
    required double amount,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1. Create withdrawal transaction
      await _firestore.collection('transactions').add({
        'projectId': 'withdrawal',
        'fromUserId': userId,
        'toUserId': 'bank',
        'type': 'withdrawal',
        'amount': amount,
        'platformFee': 0,
        'netAmount': amount,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update user balance
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'balance': FieldValue.increment(-amount),
        'totalWithdrawn': FieldValue.increment(amount),
      });

      await batch.commit();
    } catch (e) {
      print('Error withdrawal: $e');
      rethrow;
    }
  }

  // ⭐ GET TRANSACTIONS HISTORY
  Stream<QuerySnapshot> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // ⭐ GET BALANCE
  Future<Map<String, double>> getBalance(String userId) async {
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return {
      'balance': (data['balance'] ?? 0).toDouble(),
      'totalEarnings': (data['totalEarnings'] ?? 0).toDouble(),
      'totalWithdrawn': (data['totalWithdrawn'] ?? 0).toDouble(),
    };
  }
}
