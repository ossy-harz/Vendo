import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class ReportScreen extends StatefulWidget {
  final String? productId;
  final String? serviceId;
  final String? userId;
  final String title;

  const ReportScreen({
    super.key,
    this.productId,
    this.serviceId,
    this.userId,
    required this.title,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportReason _selectedReason = ReportReason.inappropriate;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await reportService.createReport(
        reporterId: authService.currentUser!.uid,
        productId: widget.productId,
        serviceId: widget.serviceId,
        userId: widget.userId,
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.fraud:
        return 'Fraud or Scam';
      case ReportReason.spam:
        return 'Spam or Misleading';
      case ReportReason.prohibited:
        return 'Prohibited Item';
      case ReportReason.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item being reported
            Text(
              'Reporting: ${widget.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Reason
            Text(
              'Reason for Report',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      title: Text(_getReasonText(reason)),
                      value: reason,
                      groupValue: _selectedReason,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedReason = value;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Please provide details about the issue...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            
            // Submit button
            CustomButton(
              text: 'Submit Report',
              isLoading: _isLoading,
              onPressed: _submitReport,
            ),
          ],
        ),
      ),
    );
  }
}

