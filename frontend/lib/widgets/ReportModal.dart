import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import '../utils/auth_utils.dart';
import '../config.dart';
import 'dart:convert';

class ReportModal extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String itemType;
  final BuildContext scaffoldContext; // هذا جديد
  final VoidCallback? onReportSuccess;
  final VoidCallback? onReportAnswerSuccess;

  const ReportModal({
    Key? key,
    required this.questionId,
    required this.questionText,
    required this.itemType,
    required this.scaffoldContext,
    this.onReportSuccess,
    this.onReportAnswerSuccess,
  }) : super(key: key);

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedReportType;
  bool _submitting = false;

  final List<ReportType> _reportTypes = [
    ReportType('inappropriate', 'Inappropriate content'),
    ReportType('spam', 'Spam or advertisement'),
    ReportType('harassment', 'Harassment or bullying'),
    ReportType('misinformation', 'Misinformation'),
    ReportType('hate-speech', 'Hate speech'),
    ReportType('other', 'Other'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReportType == null) {
      _showSnackBar('Please select a report type', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await AuthUtils.getValidToken(context);
      debugPrint(
        'Report submitted: {id: ${widget.questionId}, type: $_selectedReportType, description: ${_controller.text}}',
      );

      final response = await http.post(
        Uri.parse(reportQuestion),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'questionId': widget.questionId,
          'reportType': _selectedReportType,
          'description': _controller.text,
          'itemType': widget.itemType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Report submitted successfully. Thank you!');

        if (widget.onReportSuccess != null) {
          // Close the dialog
          if (mounted) {
            Navigator.of(context).pop();
          }
          // Then call the success callback
          //Adding a small delay to ensure the dialog is closed before the parent state is updated.
          await Future.delayed(const Duration(milliseconds: 100));
          widget.onReportSuccess?.call();
          widget.onReportAnswerSuccess?.call();
        }
      } else {
        debugPrint('Response: ${response.body}');
        _showSnackBar('Failed to submit report. Try again.', isError: true);
      }
    } catch (e) {
      debugPrint('Error: $e');
      _showSnackBar('Failed to submit report. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.islamicGreen600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Report Question',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Reporting:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select a reason:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ..._reportTypes.map(
                (type) => RadioListTile<String>(
                  title: Text(type.label),
                  value: type.value,
                  groupValue: _selectedReportType,
                  onChanged: (val) {
                    setState(() {
                      _selectedReportType = val;
                    });
                  },
                  dense: true,
                  activeColor: Colors.red,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Additional details (optional):',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue clearly...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _submitting
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportType {
  final String value;
  final String label;

  ReportType(this.value, this.label);
}
