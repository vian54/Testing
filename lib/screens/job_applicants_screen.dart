import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicantsScreen extends StatelessWidget {
  final String jobId;

  JobApplicantsScreen({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Applicants'),
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
          stream: FirebaseFirestore.instance
              .collection('job_applications')
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: 'pending')
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
                    Text('Error loading applicants'),
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
                    Icon(Icons.people_outline,
                        size: 80, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      'No Applicants Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Wait for freelancers to apply',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var applicationDoc = snapshot.data!.docs[index];
                var appData = applicationDoc.data() as Map<String, dynamic>;
                String freelancerId = appData['freelancerId'] ?? '';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(freelancerId)
                      .get(),
                  builder: (context, freelancerSnapshot) {
                    if (!freelancerSnapshot.hasData) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text('Loading...'),
                        ),
                      );
                    }

                    var freelancerData = freelancerSnapshot.data!.data()
                        as Map<String, dynamic>?;

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Freelancer Info
                            Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        freelancerData?['name'] ??
                                            'Unknown Freelancer',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
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
                                          SizedBox(width: 8),
                                          Text(
                                            '(${freelancerData?['totalReviews'] ?? 0} reviews)',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${freelancerData?['completedProjects'] ?? 0} completed projects',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 12),

                            // Application Message
                            Text(
                              'Application Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appData['message'] ?? 'No message',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),

                            SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _rejectApplicant(
                                        context,
                                        applicationDoc.id,
                                      );
                                    },
                                    icon: Icon(Icons.close),
                                    label: Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _approveApplicant(
                                        context,
                                        applicationDoc.id,
                                        freelancerId,
                                        freelancerData?['name'] ?? 'Freelancer',
                                      );
                                    },
                                    icon: Icon(Icons.check),
                                    label: Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _approveApplicant(BuildContext context, String applicationId,
      String freelancerId, String freelancerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Applicant'),
        content: Text(
            'Assign this job to $freelancerName? This will reject all other applicants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update job with assigned freelancer
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(jobId)
                    .update({
                  'status': 'in_progress',
                  'freelancerId': freelancerId,
                });

                // Approve this application
                await FirebaseFirestore.instance
                    .collection('job_applications')
                    .doc(applicationId)
                    .update({
                  'status': 'approved',
                });

                // Reject all other applications for this job
                var otherApplications = await FirebaseFirestore.instance
                    .collection('job_applications')
                    .where('jobId', isEqualTo: jobId)
                    .where('status', isEqualTo: 'pending')
                    .get();

                for (var doc in otherApplications.docs) {
                  if (doc.id != applicationId) {
                    await doc.reference.update({'status': 'rejected'});
                  }
                }

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to job detail
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Freelancer assigned successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Yes, Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectApplicant(BuildContext context, String applicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Applicant'),
        content: Text('Are you sure you want to reject this applicant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('job_applications')
                    .doc(applicationId)
                    .update({
                  'status': 'rejected',
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Applicant rejected')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Reject'),
          ),
        ],
      ),
    );
  }
}