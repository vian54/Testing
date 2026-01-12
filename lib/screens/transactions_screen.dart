import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/cashflow_service.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cashflowService = CashflowService();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Transaction History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: cashflowService.getTransactions(authService.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    TransactionModel transaction = TransactionModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );

                    return _buildTransactionCard(transaction);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    Color color;
    IconData icon;
    String title;

    switch (transaction.type) {
      case 'payment':
        color = Colors.green;
        icon = Icons.arrow_downward;
        title = 'Payment Received';
        break;
      case 'withdrawal':
        color = Colors.orange;
        icon = Icons.arrow_upward;
        title = 'Withdrawal';
        break;
      default:
        color = Colors.blue;
        icon = Icons.sync;
        title = 'Transaction';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt)),
            if (transaction.platformFee > 0) ...[
              SizedBox(height: 4),
              Text(
                'Fee: Rp ${_formatCurrency(transaction.platformFee)}',
                style: TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.type == 'withdrawal' ? '-' : '+'}${transaction.formattedAmount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.type == 'withdrawal' ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
            if (transaction.netAmount != transaction.amount)
              Text(
                'Net: Rp ${_formatCurrency(transaction.netAmount)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}