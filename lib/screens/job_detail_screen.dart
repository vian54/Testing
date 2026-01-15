import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'job_applicants_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  JobDetailScreen({required this.jobId});

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
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

    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    final role = _userData?['role'] ?? 'freelancer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Job not found'),
                ],
              ),
            );
          }

          var jobData = snapshot.data!.data() as Map<String, dynamic>;
          String status = jobData['status'] ?? 'open';
          String clientId = jobData['clientId'] ?? '';
          String? assignedFreelancerId = jobData['freelancerId'];
          bool isMyJob = role == 'client' && clientId == userId;
          bool isAssignedToMe = role == 'freelancer' && assignedFreelancerId == userId;

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
                  // Status Badge
                  _buildStatusBadge(status),
                  SizedBox(height: 16),

                  // Job Title
                  Text(
                    jobData['title'] ?? 'Untitled Job',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Budget
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Rp ${_formatCurrency(jobData['budget'] ?? 0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Description
                  _buildSectionTitle('Description'),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jobData['description'] ?? 'No description provided',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Requirements (if exists)
                  if (jobData['requirements'] != null) ...[
                    _buildSectionTitle('Requirements'),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        jobData['requirements'],
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Client Info
                  _buildSectionTitle('Client Information'),
                  SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(clientId)
                        .get(),
                    builder: (context, clientSnapshot) {
                      if (!clientSnapshot.hasData) {
                        return CircularProgressIndicator();
                      }

                      var clientData =
                          clientSnapshot.data!.data() as Map<String, dynamic>?;

                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.purple.shade100,
                              child: Icon(Icons.business,
                                  color: Colors.purple, size: 30),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientData?['name'] ?? 'Unknown Client',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    clientData?['email'] ?? '',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),

                  // Assigned Freelancer Info (for in_progress jobs)
                  if (status == 'in_progress' &&
                      assignedFreelancerId != null) ...[
                    _buildSectionTitle('Assigned Freelancer'),
                    SizedBox(height: 8),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(assignedFreelancerId)
                          .get(),
                      builder: (context, freelancerSnapshot) {
                        if (!freelancerSnapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        var freelancerData = freelancerSnapshot.data!.data()
                            as Map<String, dynamic>?;

                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person,
                                    color: Colors.blue, size: 30),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      freelancerData?['name'] ??
                                          'Unknown Freelancer',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '${freelancerData?['rating']?.toStringAsFixed(1) ?? '0.0'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                  ],

                  // Application Count (for client)
                  if (isMyJob && status == 'open') ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('job_applications')
                          .where('jobId', isEqualTo: widget.jobId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, appSnapshot) {
                        int applicantCount =
                            appSnapshot.hasData ? appSnapshot.data!.docs.length : 0;

                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$applicantCount freelancer(s) applied',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (applicantCount > 0)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JobApplicantsScreen(
                                          jobId: widget.jobId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Review'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                  ],

                  // Action Buttons
                  _buildActionButtons(
                    context,
                    status,
                    isMyJob,
                    isAssignedToMe,
                    userId,
                    jobData,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'open':
        color = Colors.blue;
        label = 'OPEN';
        icon = Icons.public;
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'IN PROGRESS';
        icon = Icons.pending;
        break;
      case 'awaiting_review':
        color = Colors.purple;
        label = 'AWAITING REVIEW';
        icon = Icons.rate_review;
        break;
      case 'completed':
        color = Colors.green;
        label = 'COMPLETED';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
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
    );
  }

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

  Widget _buildActionButtons(
    BuildContext context,
    String status,
    bool isMyJob,
    bool isAssignedToMe,
    String userId,
    Map<String, dynamic> jobData,
  ) {
    // CLIENT BUTTONS
    if (isMyJob) {
      if (status == 'awaiting_review') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteJobDialog(context, jobData),
            icon: Icon(Icons.check_circle),
            label: Text('Approve & Complete Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      return SizedBox.shrink();
    }

    // FREELANCER BUTTONS
    if (status == 'open') {
      // Check if already applied
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('jobId', isEqualTo: widget.jobId)
            .where('freelancerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          bool hasApplied =
              snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          if (hasApplied) {
            var appData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            String appStatus = appData['status'] ?? 'pending';

            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    appStatus == 'pending'
                        ? 'Application Pending'
                        : 'Application ${appStatus.toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showApplyDialog(context, userId),
              icon: Icon(Icons.send),
              label: Text('Apply for this Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    }

    if (status == 'in_progress' && isAssignedToMe) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _markAsDone(context),
          icon: Icon(Icons.done_all),
          label: Text('Mark as Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (status == 'awaiting_review' && isAssignedToMe) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Waiting for client approval',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  void _showApplyDialog(BuildContext context, String userId) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply for Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Write a message to the client:'),
            SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Why are you the best fit for this job?',
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
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please write a message')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('job_applications')
                    .add({
                  'jobId': widget.jobId,
                  'freelancerId': userId,
                  'freelancerName': _userData?['name'] ?? 'Unknown',
                  'message': messageController.text.trim(),
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Application submitted!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  void _markAsDone(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Done'),
        content: Text('Are you sure you have completed this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(widget.jobId)
                    .update({
                  'status': 'awaiting_review',
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Job marked as done! Awaiting client approval')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Yes, Mark as Done'),
          ),
        ],
      ),
    );
  }

  void _showCompleteJobDialog(
      BuildContext context, Map<String, dynamic> jobData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Job'),
        content: Text(
            'Confirm that the freelancer has completed the job satisfactorily?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String? freelancerId = jobData['freelancerId'];
                double budget = (jobData['budget'] ?? 0).toDouble();

                // Update job status to completed
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(widget.jobId)
                    .update({
                  'status': 'completed',
                  'completedAt': FieldValue.serverTimestamp(),
                });

                // Update freelancer balance
                if (freelancerId != null) {
                  var freelancerDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(freelancerId)
                      .get();
                  double currentBalance =
                      (freelancerDoc.data()?['balance'] ?? 0).toDouble();

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(freelancerId)
                      .update({
                    'balance': currentBalance + budget,
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Job completed successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Complete Job'),
          ),
        ],
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
}