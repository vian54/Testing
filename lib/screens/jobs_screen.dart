import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
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
    final userId = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'client' ? 'My Posted Jobs' : 'Find Jobs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: role == 'client'
              ? FirebaseFirestore.instance
                    .collection('jobs')
                    .where('clientId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots()
              : FirebaseFirestore.instance
                    .collection('jobs')
                    .where('status', isEqualTo: 'open')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading jobs',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      role == 'client' ? Icons.work_off : Icons.search_off,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      role == 'client'
                          ? 'No jobs posted yet'
                          : 'No jobs available',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      role == 'client'
                          ? 'Post your first job to get started!'
                          : 'Check back later for new opportunities!',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
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
                var data = doc.data() as Map<String, dynamic>;
                String status = data['status'] ?? 'open';

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobId: doc.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Untitled Job',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusChip(status),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Description
                          Text(
                            data['description'] ?? 'No description',
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 8),

                          // Budget and Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.attach_money,
                                      size: 20, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Rp ${_formatCurrency(data['budget'] ?? 0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 18, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDate(data['createdAt']),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Show applicant count for client
                          if (role == 'client' && status == 'open') ...[
                            SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('job_applications')
                                  .where('jobId', isEqualTo: doc.id)
                                  .where('status', isEqualTo: 'pending')
                                  .snapshots(),
                              builder: (context, appSnapshot) {
                                int count = appSnapshot.hasData
                                    ? appSnapshot.data!.docs.length
                                    : 0;

                                if (count > 0) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people,
                                            color: Colors.orange, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          '$count applicant${count > 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.blue;
        label = 'Open';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'In Progress';
        break;
      case 'awaiting_review':
        color = Colors.purple;
        label = 'Review';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    double amount = (value ?? 0).toDouble();
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
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