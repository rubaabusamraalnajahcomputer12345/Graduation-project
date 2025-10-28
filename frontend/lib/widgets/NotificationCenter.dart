import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/auth_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/UserProvider.dart';

class NotificationCenter extends StatefulWidget {
  @override
  _NotificationCenterState createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${url}notifications'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            notifications = List<Map<String, dynamic>>.from(
              data['notifications'] ?? [],
            );
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${url}notifications/$notificationId/read'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        setState(() {
          final index = notifications.indexWhere(
            (n) => n['id'] == notificationId,
          );
          if (index != -1) {
            notifications[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${url}notifications/mark-all-read'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var notification in notifications) {
            notification['read'] = true;
          }
        });
      }
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${url}notifications'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications deleted successfully'),
            backgroundColor: AppColors.islamicGreen500,
          ),
        );
      }
    } catch (e) {
      print('Failed to delete all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notifications'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningOrange,
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete All Notifications',
                  style: TextStyle(
                    color: AppColors.islamicGreen800,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
            style: TextStyle(fontSize: 16, color: AppColors.grey700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Delete All', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'question_answered':
        return '💬';
      case 'answer_upvoted':
        return '👍';
      case 'new_question':
        return '🤔';
      case 'welcome':
        return '🎉';
      case 'test':
        return '🔔';
      case 'question_updated':
        return '📝';
      default:
        return '📢';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'question_answered':
        return AppColors.islamicGreen500;
      case 'answer_upvoted':
        return AppColors.islamicGold500;
      case 'new_question':
        return AppColors.islamicGreen600;
      case 'welcome':
        return AppColors.islamicGreen400;
      case 'test':
        return AppColors.islamicGold400;
      case 'question_updated':
        return AppColors.islamicGreen500;
      default:
        return AppColors.islamicGreen500;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.islamicGreen800,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.islamicWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.islamicGreen800),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteConfirmation(),
              tooltip: 'Delete all notifications',
            ),
          if (notifications.any((n) => !n['read']))
            IconButton(
              icon: Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.islamicGreen50,
              AppColors.islamicCream,
              AppColors.islamicGold50,
            ],
          ),
        ),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.islamicGreen500,
                  ),
                )
                : hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.grey500,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.grey600,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.islamicGreen500,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                : notifications.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.grey500,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.grey600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You\'ll see notifications here when you receive them',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.islamicGreen500,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isUnread = !notification['read'];

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: isUnread ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              isUnread
                                  ? BorderSide(
                                    color: _getNotificationColor(
                                      notification['type'],
                                    ),
                                    width: 2,
                                  )
                                  : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (isUnread) {
                              _markAsRead(notification['id']);
                            }
                            // Handle navigation based on notification type
                            _handleNotificationTap(notification);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(
                                      notification['type'],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getNotificationIcon(
                                        notification['type'],
                                      ),
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'] ??
                                                  'Notification',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    isUnread
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                color:
                                                    isUnread
                                                        ? AppColors
                                                            .islamicGreen800
                                                        : AppColors.grey700,
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _getNotificationColor(
                                                  notification['type'],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        notification['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.grey600,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _formatDate(
                                          notification['createdAt'] ?? '',
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'];

    switch (type) {
      case 'question_answered':
        // Navigate to the answered question
        final questionId = data?['questionId'];
        if (questionId != null) {
          // Navigate to question detail page
          print('Navigate to question: $questionId');
        }
        break;
      case 'answer_upvoted':
        // Navigate to the upvoted answer
        final questionId = data?['questionId'];
        final answerId = data?['answerId'];
        if (questionId != null) {
          print('Navigate to upvoted answer: $answerId');
        }
        break;
      case 'new_question':
        // Navigate to the new question
        final questionId = data?['questionId'];
        if (questionId != null) {
          print('Navigate to new question: $questionId');
        }
        break;
      case 'welcome':
        break;
      case 'test':
        break;
      case 'question_updated': // I want to show the updated question with the answer of the volunteer to update his answer
        // No navigation needed
        _handleQuestionUpdated(context, data, notification['message']);
        print(' Notification: $notification');

        break;
      case 'flag_resolved':
        // Handle flag resolved notification
        _handleFlagResolved(context, data, notification['message']);
        //delete the flag
        _deleteThreadFlag(context, data);
        print('Notification: $notification');
        break;

      case 'flag_rejected':
        // Handle flag rejected notification
        _handleFlagRejected(context, data, notification['message']);
        //delete the flag
        _deleteThreadFlag(context, data);
        print(' Notification: $notification');
        break;
      case 'flag_dismissed':
        // Handle flag dismissed notification
        _handleFlagDismissed(context, data, notification['message']);
        print(' Notification: $notification');
        break;
      case 'user_match':
        // Handle user match notification - fetch user details and show popup
        _handleUserMatchNotification(context, data);
        break;
      case 'connection_established':
        // Handle connection established notification - show user details and email
        _handleConnectionEstablishedNotification(context, data);
        break;
      default:
        // Handle other notification types if needed
        print('Unknown notification type: $type');
        break;
    }
  }

  // Function to handle user match notification
  Future<void> _handleUserMatchNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    // Pass the entire notification data to the popup
    showConnectionPopup(context, data);
  }

  // Function to handle connection established notification
  void _handleConnectionEstablishedNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.islamicGreen600),
              SizedBox(width: 10),
              Text(
                'Connection Established!',
                style: TextStyle(
                  color: AppColors.islamicGreen600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are now connected!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected User Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Email: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Open email app with the email
                              final email = data['connectedUserEmail'];
                              if (email != null) {
                                // You can use url_launcher package to open email app
                                // For now, just copy to clipboard
                                Clipboard.setData(ClipboardData(text: email));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Email copied to clipboard: $email',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              data['connectedUserEmail'] ??
                                  'No email available',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.islamicGreen600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                'You can now communicate with each other via email to support one another in your Islamic journey.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show connection popup
  void showConnectionPopup(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.people, color: AppColors.islamicGreen600),
              SizedBox(width: 10),
              Text(
                'Connection Request',
                style: TextStyle(
                  color: AppColors.islamicGreen600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have a connection request!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              Text(
                'Would you like to connect and remind one another of Allah along this journey?',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleConnectionAction(context, data, 'ignore');
              },
              child: Text('Ignore', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleConnectionAction(context, data, 'accept');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.islamicGreen600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Accept Connection',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to handle connection actions
  Future<void> _handleConnectionAction(
    BuildContext context,
    Map<String, dynamic> data,
    String action,
  ) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Authentication required')));
        }
        return;
      }

      final endpoint = action == 'accept' ? acceptConnection : ignoreConnection;

      // Fallback if variables are null
      final finalEndpoint =
          endpoint ??
          (action == 'accept'
              ? '${url}connections/accept'
              : '${url}connections/ignore');

      final uri = Uri.parse(finalEndpoint).replace(
        queryParameters: {
          'userA': data['matchedUserId'], // matchedUserId
          'userB': data['currentUserId'], // current user
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final message =
            action == 'accept'
                ? 'Connection accepted successfully!'
                : 'Connection ignored';
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to $action connection')),
          );
        }
      }
    } catch (e) {
      print('Error handling connection action: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred')));
      }
    }
  }
}

void _showAnswerDialogToPreviewAndEdit(
  BuildContext context,
  String questionText,
  String initialAnswer,
  void Function(String updatedAnswer) onSave,
) {
  TextEditingController _answerController = TextEditingController(
    text: initialAnswer,
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Review and Update Your Answer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(questionText, style: TextStyle(color: Colors.black87)),
            SizedBox(height: 16),
            Text('Your Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            TextField(
              controller: _answerController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Edit your answer here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String updatedAnswer = _answerController.text.trim();
              onSave(updatedAnswer); // Call the save callback
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

void _handleQuestionUpdated(
  BuildContext context,
  Map<String, dynamic> data,
  String? message,
) {
  final questionId = data['questionId'];
  final answerId = data['answerId'];

  if (questionId != null && answerId != null) {
    print('✴️ Navigate to updated question: $questionId');

    // Save the outer context BEFORE showing the dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Updated Question"),
          content: Text(message ?? "The question was updated."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showAnswerDialogToPreviewAndEdit(
                  context, // <-- Use outer context here
                  data['questionText'],
                  data['answerText'],
                  (updatedAnswer) async {
                    final response = await http.put(
                      Uri.parse('${adminReviewAndUpdateAnswerUrl}$answerId'),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({"answerText": updatedAnswer}),
                    );

                    if (response.statusCode == 200) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Answer updated successfully'),
                          backgroundColor: AppColors.islamicGreen500,
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update answer'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  },
                );
              },
              child: Text("Review Answer"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

void _handleFlagResolved(
  BuildContext context,
  Map<String, dynamic> data,
  String? message,
) {
  final flagId = data['flagId'];
  //  final questionId = data['questionId'];
  final itemType = data['itemType'];
  final reason = data['reason'];
  final status = data['status'];
  final reportedBy = data['reporterName'] ?? 'Unknown Reporter';
  final createdAt =
      data['createdAt'] != null
          ? DateTime.parse(data['createdAt']).toLocal().toString()
          : 'Unknown';

  final flaggedContent = data['flaggedContent'];

  if (flagId != null) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Flag Dismissed"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message != null) Text(message),
                SizedBox(height: 8),
                Text("Flag ID: $flagId"),
                Text("Item Type: $itemType"),
                Text("Reason: $reason"),
                Text("Status: $status"),
                Text("Reported By: $reportedBy"),
                Text("Created At: $createdAt"),
                SizedBox(height: 10),
                Text(
                  "Flagged Content:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(flaggedContent ?? "No content available"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

void _handleFlagRejected(
  BuildContext context,
  Map<String, dynamic> data,
  String? message,
) {
  final flagId = data['flagId'];
  //  final questionId = data['questionId'];
  final itemType = data['itemType'];
  final reason = data['reason'];
  final status = data['status'];
  final reportedBy = data['reporterName'] ?? 'Unknown Reporter';
  final createdAt =
      data['createdAt'] != null
          ? DateTime.parse(data['createdAt']).toLocal().toString()
          : 'Unknown';

  final flaggedContent = data['flaggedContent'];

  if (flagId != null) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Flag Rejected"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message != null) Text(message),
                SizedBox(height: 8),
                Text("Flag ID: $flagId"),
                Text("Item Type: $itemType"),
                Text("Reason: $reason"),
                Text("Status: $status"),
                Text("Reported By: $reportedBy"),
                Text("Created At: $createdAt"),
                SizedBox(height: 10),
                Text(
                  "Flagged Content:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(flaggedContent ?? "No content available"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

void _handleFlagDismissed(
  BuildContext context,
  Map<String, dynamic> data,
  String? message,
) {
  final flagId = data['flagId'];
  //  final questionId = data['questionId'];
  final itemType = data['itemType'];
  final reason = data['reason'];
  final status = data['status'];
  final reportedBy = data['reporterName'] ?? 'Unknown Reporter';
  final createdAt =
      data['createdAt'] != null
          ? DateTime.parse(data['createdAt']).toLocal().toString()
          : 'Unknown';

  final flaggedContent = data['flaggedContent'];

  if (flagId != null) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Flag Dismissed"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message != null) Text(message),
                SizedBox(height: 8),
                Text("Flag ID: $flagId"),
                Text("Item Type: $itemType"),
                Text("Reason: $reason"),
                Text("Status: $status"),
                Text("Reported By: $reportedBy"),
                Text("Created At: $createdAt"),
                SizedBox(height: 10),
                Text(
                  "Flagged Content:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(flaggedContent ?? "No content available"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Close"),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () async {
                // Resolve action
                await http.put(Uri.parse('${adminResolveFlagUrl}${flagId}'));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Flagged content is removed.'),
                    backgroundColor: AppColors.islamicGreen500,
                  ),
                );
              },
              icon: Icon(Icons.check),
              label: Text("Resolve"),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                // Reject action
                await http.put(Uri.parse('${adminRejectFlagUrl}${flagId}'));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Flag is ignored and content is kept.'),
                    backgroundColor: AppColors.islamicGreen500,
                  ),
                );
              },
              icon: Icon(Icons.close),
              label: Text("Reject"),
            ),
          ],
        );
      },
    );
  }
}

void _deleteThreadFlag(BuildContext context, Map<String, dynamic> data) {
  final flagId = data['flagId'];
  //  final questionId = data['questionId'];

  if (flagId != null) {
    print('✴️ Deleting flag: $flagId');

    // Call the API to delete the flag
    http
        .delete(
          Uri.parse('${adminDeleteFlagUrl}$flagId'),
          headers: {"Content-Type": "application/json"},
        )
        .then((response) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Flag deleted successfully'),
                backgroundColor: AppColors.islamicGreen500,
              ),
            );
          }
        })
        .catchError((error) {
          print('Error deleting flag: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting flag'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        });
  }
}
