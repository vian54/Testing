import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/cashflow_service.dart';

class BalanceScreen extends StatefulWidget {
  @override
  _BalanceScreenState createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final CashflowService _cashflowService = CashflowService();
  Map<String, double>? _balanceData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  void _loadBalance() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final balance = await _cashflowService.getBalance(authService.currentUser!.uid);
    setState(() {
      _balanceData = balance;
      _isLoading = false;
    });
  }

  void _showWithdrawalDialog() {
    final _amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: Rp ${_formatCurrency(_balanceData?['balance'] ?? 0)}'),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(_amountController.text) ?? 0;
              if (amount <= 0 || amount > (_balanceData?['balance'] ?? 0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid amount')),
                );
                return;
              }

              final authService = Provider.of<AuthService>(context, listen: false);
              await _cashflowService.requestWithdrawal(
                userId: authService.currentUser!.uid,
                amount: amount,
              );

              Navigator.pop(context);
              _loadBalance();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Withdrawal successful!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    double balance = _balanceData?['balance'] ?? 0;
    double totalEarnings = _balanceData?['totalEarnings'] ?? 0;
    double totalWithdrawn = _balanceData?['totalWithdrawn'] ?? 0;
    double pendingBalance = totalEarnings - balance - totalWithdrawn;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp ${_formatCurrency(balance)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceInfo(
                          'Pending',
                          'Rp ${_formatCurrency(pendingBalance)}',
                        ),
                      ),
                      Expanded(
                        child: _buildBalanceInfo(
                          'Withdrawn',
                          'Rp ${_formatCurrency(totalWithdrawn)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Withdraw Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: balance > 0 ? _showWithdrawalDialog : null,
                icon: Icon(Icons.account_balance),
                label: Text('Withdraw to Bank'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    'Rp ${_formatCurrency(totalEarnings)}',
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Platform Fee (7%)',
                    'Rp ${_formatCurrency(totalEarnings * 0.07)}',
                    Colors.orange,
                    Icons.percent,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Chart Section
            Text(
              'Cashflow Chart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Container(
              height: 200,
              child: _buildCashflowChart(balance, pendingBalance, totalWithdrawn),
            ),

            SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Platform fee 7% dipotong otomatis dari setiap pembayaran yang Anda terima.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashflowChart(double balance, double pending, double withdrawn) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: balance,
            title: 'Available',
            color: Colors.green,
            radius: 60,
            titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: pending > 0 ? pending : 0.1,
            title: 'Pending',
            color: Colors.orange,
            radius: 60,
            titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: withdrawn > 0 ? withdrawn : 0.1,
            title: 'Withdrawn',
            color: Colors.blue,
            radius: 60,
            titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
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