import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/cashflow_service.dart';

class JobCard extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> data;

  JobCard({required this.jobId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showJobDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data['category'] ?? '',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Text(
                data['title'] ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              SizedBox(height: 8),
              
              Text(
                data['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              
              SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${_formatCurrency(data['budget'])}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showJobDetail(context),
                    child: Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetail(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  data['title'] ?? '',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                
                SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Budget:', style: TextStyle(fontSize: 16)),
                      Text(
                        'Rp ${_formatCurrency(data['budget'])}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(data['description'] ?? ''),
                
                SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _submitProposal(context, authService),
                    child: Text('Submit Proposal', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitProposal(BuildContext context, AuthService authService) async {
    // Simple proposal submission
    await FirebaseFirestore.instance.collection('proposals').add({
      'jobId': jobId,
      'freelancerId': authService.currentUser!.uid,
      'proposedBudget': data['budget'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ⭐ Create project immediately (simplified - no approval needed for demo)
    var projectRef = await FirebaseFirestore.instance.collection('projects').add({
      'jobId': jobId,
      'clientId': data['clientId'],
      'freelancerId': authService.currentUser!.uid,
      'budget': data['budget'],
      'status': 'in_progress',
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ⭐ Simulate project completion & payment (for demo cashflow)
    await Future.delayed(Duration(seconds: 1));
    
    CashflowService cashflowService = CashflowService();
    await cashflowService.approveProjectAndPay(
      projectId: projectRef.id,
      clientId: data['clientId'],
      freelancerId: authService.currentUser!.uid,
      budget: (data['budget'] as num).toDouble(),
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project completed! Payment received!'),
        backgroundColor: Colors.green,
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