import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String projectId;
  final String fromUserId;
  final String toUserId;
  final String type; // deposit, payment, withdrawal
  final double amount;
  final double platformFee;  // ⭐ CASHFLOW: 7%
  final double netAmount;  // ⭐ CASHFLOW: amount - fee
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.projectId,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      projectId: map['projectId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // ⭐ CASHFLOW: Format Rupiah
  String get formattedAmount {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}