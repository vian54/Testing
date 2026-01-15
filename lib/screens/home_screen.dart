import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'jobs_screen.dart';
import 'post_job_screen.dart';
import 'my_work_screen.dart';
import 'freelancer_profile_screen.dart';
import 'client_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = await authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _userData?['role'] ?? 'freelancer';

    // Get screens based on role
    List<Widget> screens = role == 'client'
        ? [
            _buildDashboard(), // Dashboard
            JobsScreen(), // My Jobs
            role == 'client'
                ? ClientProfileScreen()
                : FreelancerProfileScreen(), // Profile
          ]
        : [
            _buildDashboard(), // Dashboard
            JobsScreen(), // Find Jobs
            MyWorkScreen(), // My Work
            FreelancerProfileScreen(), // Profile
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Freelance Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: role == 'client'
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'My Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Find Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  label: 'My Work',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
      floatingActionButton: role == 'client'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostJobScreen()),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Post Job'),
              backgroundColor: Colors.blue.shade700,
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    final role = _userData?['role'] ?? 'freelancer';
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser!.uid;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_userData?['name'] ?? 'User'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Role: ${_userData?['role']?.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Conditional Dashboard based on role
            if (role == 'freelancer')
              _buildFreelancerDashboard(userId)
            else
              _buildClientDashboard(userId),
          ],
        ),
      ),
    );
  }

  // ==================== FREELANCER DASHBOARD ====================
  Widget _buildFreelancerDashboard(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance & Rating
        _buildSectionTitle('Quick Stats'),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Balance',
                'Rp ${_formatCurrency(_userData?['balance'] ?? 0)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rating',
                '${_userData?['rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Active Jobs Summary
        _buildSectionTitle('Active Jobs'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('freelancerId', isEqualTo: userId)
              .where('status', isEqualTo: 'in_progress')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            int activeCount = snapshot.data!.docs.length;
            double totalEarning = 0;

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              totalEarning += (data['budget'] ?? 0).toDouble();
            }

            if (activeCount == 0) {
              return _buildEmptyState('No active jobs', Icons.work_off);
            }

            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Active Projects',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        'Rp ${_formatCurrency(totalEarning)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Potential Earning',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        SizedBox(height: 24),

        // Recent Reviews
        _buildSectionTitle('Recent Review'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('freelancerId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No reviews yet', Icons.rate_review);
            }

            var reviewData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            double rating = (reviewData['rating'] ?? 0).toDouble();
            String comment = reviewData['comment'] ?? '';

            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '"$comment"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        SizedBox(height: 24),

        // Quick Actions
        _buildSectionTitle('Quick Actions'),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Find Jobs',
                Icons.search,
                Colors.blue,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'My Work',
                Icons.work,
                Colors.orange,
                () => setState(() => _currentIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== CLIENT DASHBOARD ====================
  Widget _buildClientDashboard(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance Overview
        _buildSectionTitle('Balance Overview'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('clientId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            double totalDeposited = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                totalDeposited += (data['budget'] ?? 0).toDouble();
              }
            }

            double currentBalance = (_userData?['balance'] ?? 0).toDouble();

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Current Balance',
                    'Rp ${_formatCurrency(currentBalance)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    'Rp ${_formatCurrency(totalDeposited)}',
                    Icons.payments,
                    Colors.blue,
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: 24),

        // Job Statistics
        _buildSectionTitle('Job Statistics'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('clientId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            int totalJobs = snapshot.hasData ? snapshot.data!.docs.length : 0;
            int activeProjects = 0;
            int completedJobs = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var status = (doc.data() as Map)['status'];
                // Count both 'open' and 'in_progress' as active
                if (status == 'open' || status == 'in_progress') activeProjects++;
                if (status == 'completed') completedJobs++;
              }
            }

            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('$totalJobs', 'Total Jobs', Colors.purple),
                  _buildDivider(),
                  _buildStatColumn(
                      '$activeProjects', 'Active', Colors.orange),
                  _buildDivider(),
                  _buildStatColumn(
                      '$completedJobs', 'Completed', Colors.green),
                ],
              ),
            );
          },
        ),

        SizedBox(height: 24),

        // Active Projects
        _buildSectionTitle('Active Projects'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('clientId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            // Filter jobs with status 'open' or 'in_progress'
            var activeJobs = snapshot.data!.docs.where((doc) {
              var status = (doc.data() as Map)['status'];
              return status == 'open' || status == 'in_progress';
            }).toList();

            if (activeJobs.isEmpty) {
              return _buildEmptyState('No active projects', Icons.work_off);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: activeJobs.length > 3 ? 3 : activeJobs.length,
              itemBuilder: (context, index) {
                var jobData =
                    activeJobs[index].data() as Map<String, dynamic>;
                String status = jobData['status'] ?? 'open';

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: status == 'in_progress'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        Icons.work,
                        color: status == 'in_progress'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                    title: Text(jobData['title'] ?? 'Untitled Job'),
                    subtitle: Text(
                      status == 'open'
                          ? 'Waiting for freelancer'
                          : 'Budget: Rp ${_formatCurrency(jobData['budget'] ?? 0)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        status == 'open' ? 'Open' : 'In Progress',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: status == 'in_progress'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                    ),
                  ),
                );
              },
            );
          },
        ),

        SizedBox(height: 24),

        // Recent Transactions
        _buildSectionTitle('Recent Activity'),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No transactions yet', Icons.receipt);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var txData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Icon(Icons.arrow_upward, color: Colors.red),
                    ),
                    title: Text(txData['description'] ?? 'Transaction'),
                    subtitle: Text(_formatDate(txData['createdAt'])),
                    trailing: Text(
                      'Rp ${_formatCurrency(txData['amount'] ?? 0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        SizedBox(height: 24),

        // Quick Actions
        _buildSectionTitle('Quick Actions'),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Post Job',
                Icons.add_circle,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostJobScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'My Jobs',
                Icons.work,
                Colors.purple,
                () => setState(() => _currentIndex = 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}