import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'jobs_screen.dart';
import 'post_job_screen.dart';
import 'balance_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = await authService.getUserData();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _userData?['role'] ?? 'freelancer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Freelance Hub'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboard() : 
            _currentIndex == 1 ? JobsScreen() :
            _currentIndex == 2 ? BalanceScreen() :
            TransactionsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Balance'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Transactions'),
        ],
      ),
      floatingActionButton: role == 'client'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PostJobScreen()));
              },
              icon: Icon(Icons.add),
              label: Text('Post Job'),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_userData?['name'] ?? 'User'}!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Role: ${_userData?['role']?.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          
          SizedBox(height: 24),
          
          // ⭐ CASHFLOW STATS
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Balance',
                'Rp ${_formatCurrency(_userData?['balance'] ?? 0)}',
                Icons.account_balance_wallet,
                Colors.green,
              )),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Total Earnings',
                'Rp ${_formatCurrency(_userData?['totalEarnings'] ?? 0)}',
                Icons.trending_up,
                Colors.blue,
              )),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Rating',
                '${_userData?['rating']?.toStringAsFixed(1) ?? '0.0'}',
                Icons.star,
                Colors.amber,
              )),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Projects',
                '${_userData?['completedProjects'] ?? 0}',
                Icons.work,
                Colors.purple,
              )),
            ],
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('toUserId', isEqualTo: authService.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No recent activity'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.arrow_downward, color: Colors.white),
              ),
              title: Text('Payment Received'),
              subtitle: Text('Rp ${_formatCurrency(data['netAmount'] ?? 0)}'),
              trailing: Text(_formatDate(data['createdAt'])),
            );
          },
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    double amount = (value ?? 0).toDouble();
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}';
  }
}