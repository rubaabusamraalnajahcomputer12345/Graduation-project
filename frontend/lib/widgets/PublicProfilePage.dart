import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:frontend/services/meeting_request_service.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/services/stream_chat_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/UserProvider.dart';

class PublicProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool inDialog;
  final String? volunteerId; // Add optional volunteerId parameter

  const PublicProfilePage({
    Key? key,
    required this.user,
    this.inDialog = false,
    this.volunteerId, // Add this parameter
  }) : super(key: key);

  String _stringOf(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (inDialog) {
      return PublicProfileView(user: user, volunteerId: volunteerId);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.islamicGreen500,
        foregroundColor: Colors.white,
        title: Text(
          _stringOf(user['displayName']).isNotEmpty
              ? _stringOf(user['displayName'])
              : 'User',
        ),
      ),
      body: PublicProfileView(user: user, volunteerId: volunteerId),
    );
  }
}

class PublicProfileView extends StatelessWidget {
  final Map<String, dynamic> user;
  final String? volunteerId; // Add this parameter

  const PublicProfileView({
    Key? key,
    required this.user,
    this.volunteerId, // Add this parameter
  }) : super(key: key);

  String _stringOf(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _stringOf(user['displayName']).isNotEmpty
            ? _stringOf(user['displayName'])
            : 'User';
    final role =
        _stringOf(user['role']).isNotEmpty ? _stringOf(user['role']) : 'user';
    final country = _stringOf(user['country']);
    final language = _stringOf(user['language']);
    final volunteerProfile = user['volunteerProfile'] as Map<String, dynamic>?;
    final bio =
        volunteerProfile != null ? _stringOf(volunteerProfile['bio']) : '';
    final languages =
        volunteerProfile != null
            ? (volunteerProfile['languages'] as List?)
            : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.islamicGreen200,
                child: Icon(Icons.person, color: AppColors.islamicGreen800),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.islamicGreen900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.verified_user, label: role),
                        if (country.isNotEmpty)
                          _InfoChip(icon: Icons.public, label: country),
                        if (language.isNotEmpty)
                          _InfoChip(icon: Icons.language, label: language),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (bio.isNotEmpty) ...[
            Text(
              'Bio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.islamicGreen800,
              ),
            ),
            SizedBox(height: 8),
            Text(bio, style: TextStyle(color: AppColors.islamicGreen700)),
            SizedBox(height: 16),
          ],
          if (languages != null && languages.isNotEmpty) ...[
            Text(
              'Spoken Languages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.islamicGreen800,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  languages
                      .map(
                        (e) => _InfoChip(
                          icon: Icons.record_voice_over,
                          label: e.toString(),
                        ),
                      )
                      .toList(),
            ),
          ],

          // Request Zoom Meeting button (only for volunteers)
          if (role.toLowerCase() == 'certified_volunteer') ...[
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showZoomRequestDialog(context),
                icon: Icon(Icons.video_call, color: Colors.white),
                label: Text(
                  'Request Zoom Meeting',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],

          // Start Chat button (for all users)
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startChatWithUser(context),
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                'Start Chat',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.islamicGreen500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
            ),
          ),

          // Meeting Requests Section
          SizedBox(height: 24),
          _MeetingRequestsSection(
            user: user,
            volunteerId: volunteerId,
            userRole: role,
          ),
        ],
      ),
    );
  }

  void _showZoomRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Request Zoom Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select up to 5 preferred time slots for your meeting with ${_stringOf(user['displayName'])}.',
              ),
              SizedBox(height: 16),
              Text(
                'Each slot is 30 minutes. The volunteer will choose one of your preferred times.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showTimeSlotSelectionDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.islamicGreen600,
                foregroundColor: Colors.white,
              ),
              child: Text('Select Times'),
            ),
          ],
        );
      },
    );
  }

  void _showTimeSlotSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _TimeSlotSelector(
            volunteerUser: user,
            volunteerId: volunteerId,
          ),
        );
      },
    );
  }

  Future<void> _startChatWithUser(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Initialize Stream Chat service
      final chatService = await StreamChatService.initialize(context);

      if (chatService == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize chat')),
        );
        return;
      }

      // Get the target user ID
      final targetUserId = user['id']?.toString() ?? user['userId']?.toString();
      if (targetUserId == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User ID not found')));
        return;
      }

      // Get current user ID
      final currentUserId = context.read<UserProvider>().userId;
      if (currentUserId == targetUserId) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot chat with yourself')),
        );
        return;
      }

      // Ensure the other user exists in Stream Chat before creating channel
      final userExists = await chatService.ensureUserExists(targetUserId);
      if (!userExists) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. User not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create or get the channel with shorter ID
      final channelId = _generateShortChannelId(currentUserId, targetUserId);
      final channel = chatService.client.channel(
        'messaging',
        id: channelId,
        extraData: {
          'members': [currentUserId, targetUserId],
        },
      );

      // Watch the channel
      await channel.watch();

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to chat
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => StreamChat(
                client: chatService.client,
                child: StreamChannel(
                  channel: channel,
                  child: RestorationScope(
                    restorationId: 'public_profile_chat',
                    child: Scaffold(
                      appBar: const StreamChannelHeader(),
                      body: const StreamMessageListView(),
                      bottomNavigationBar: SafeArea(
                        child: StreamMessageInput(
                          // Disable restoration to prevent the assertion error
                          restorationId: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    }
  }

  String _generateShortChannelId(String userId1, String userId2) {
    // Sort user IDs to ensure consistent channel ID regardless of order
    final sortedIds = [userId1, userId2]..sort();

    // Create a hash of the combined user IDs
    final combined = '${sortedIds[0]}_${sortedIds[1]}';
    final hash = combined.hashCode.abs();

    // Return a short channel ID (max 64 chars)
    return 'chat_$hash';
  }
}

class _TimeSlotSelector extends StatefulWidget {
  final Map<String, dynamic> volunteerUser;
  final String? volunteerId; // Add this parameter

  const _TimeSlotSelector({
    Key? key,
    required this.volunteerUser,
    this.volunteerId, // Add this parameter
  }) : super(key: key);

  @override
  State<_TimeSlotSelector> createState() => _TimeSlotSelectorState();
}

class _TimeSlotSelectorState extends State<_TimeSlotSelector> {
  final List<DateTime> _slots = [];
  bool _submitting = false;

  String _formatLocal(DateTime dt) {
    final local = dt.toLocal();
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  ${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _addSlot() async {
    if (_slots.length >= 5) return;

    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(Duration(days: 60)),
      initialDate: now,
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(Duration(minutes: 30))),
    );
    if (pickedTime == null) return;

    final localStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Convert to UTC for backend
    final startUtc = localStart.toUtc();

    if (startUtc.isBefore(DateTime.now().toUtc())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start time must be in the future')),
      );
      return;
    }

    // Prevent duplicates (same start time up to minute)
    final duplicate = _slots.any(
      (s) =>
          s.toUtc().millisecondsSinceEpoch == startUtc.millisecondsSinceEpoch,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This time slot is already added')),
      );
      return;
    }

    // Enforce exact 30-minute slot implicitly via endUtc
    setState(() {
      _slots.add(startUtc);
      _slots.sort();
    });
  }

  Future<void> _submit() async {
    print("submit");
    if (_slots.isEmpty || _submitting) return;

    // Debug: Print what we're receiving
    print("🔍 Debug - volunteerId from parameter: ${widget.volunteerId}");
    print(
      "🔍 Debug - volunteerUser['userId']: ${widget.volunteerUser['userId']}",
    );
    print("🔍 Debug - volunteerUser['id']: ${widget.volunteerUser['id']}");
    print("🔍 Debug - Full volunteerUser object: ${widget.volunteerUser}");

    final volunteerId =
        widget.volunteerId ??
        widget.volunteerUser['userId']?.toString() ??
        widget.volunteerUser['id']?.toString();

    if (volunteerId == null || volunteerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to determine volunteer ID. Please try again or contact support.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    print("✅ Using volunteerId: $volunteerId");

    setState(() {
      _submitting = true;
    });

    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        setState(() => _submitting = false);
        return;
      }

      final preferredSlots =
          _slots
              .map(
                (s) => {
                  'start': s.toIso8601String(),
                  'end': s.add(Duration(minutes: 30)).toIso8601String(),
                },
              )
              .toList();

      final result = await MeetingRequestService.createMeetingRequest(
        volunteerId: volunteerId,
        preferredSlots: preferredSlots,
        token: token,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Meeting request sent')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send request'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select up to 5 time slots (30 min each)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.islamicGreen800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _slots)
                    Chip(
                      label: Text(_formatLocal(s)),
                      onDeleted:
                          _submitting
                              ? null
                              : () {
                                setState(() {
                                  _slots.remove(s);
                                });
                              },
                    ),
                  if (_slots.length < 5)
                    ActionChip(
                      label: Text('Add slot'),
                      avatar: Icon(Icons.add, size: 18),
                      onPressed: _submitting ? null : _addSlot,
                    ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting || _slots.isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.islamicGreen600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _submitting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('Send Request'),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({Key? key, required this.icon, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.askPageCategoryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.askPageCategoryText),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.askPageCategoryText,
            ),
          ),
        ],
      ),
    );
  }
}

// Meeting Requests Section Widget
class _MeetingRequestsSection extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? volunteerId;
  final String userRole;

  const _MeetingRequestsSection({
    Key? key,
    required this.user,
    this.volunteerId,
    required this.userRole,
  }) : super(key: key);

  @override
  State<_MeetingRequestsSection> createState() =>
      _MeetingRequestsSectionState();
}

class _MeetingRequestsSectionState extends State<_MeetingRequestsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _volunteerRequests = [];
  List<Map<String, dynamic>> _userRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeetingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetingRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      // Load volunteer requests if user is a certified volunteer
      if (widget.userRole.toLowerCase() == 'certified_volunteer') {
        final volunteerResult =
            await MeetingRequestService.getVolunteerMeetingRequests(
              token: token,
            );
        if (volunteerResult['success']) {
          _volunteerRequests = List<Map<String, dynamic>>.from(
            volunteerResult['data'] ?? [],
          );
        }
      }

      // Load user requests (requests created by the current user)
      final userResult = await MeetingRequestService.getUserMeetingRequests(
        token: token,
      );
      if (userResult['success']) {
        _userRequests = List<Map<String, dynamic>>.from(
          userResult['data'] ?? [],
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meeting requests: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.islamicGreen800,
          ),
        ),
        SizedBox(height: 16),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.islamicGreen100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.islamicGreen800,
            unselectedLabelColor: AppColors.islamicGreen600,
            indicator: BoxDecoration(
              color: AppColors.islamicGreen200,
              borderRadius: BorderRadius.circular(12),
            ),
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'My Requests'),
              if (widget.userRole.toLowerCase() == 'certified_volunteer')
                Tab(
                  icon: Icon(Icons.volunteer_activism),
                  text: 'Volunteer Requests',
                ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Tab Content
        Container(
          height: 400, // Fixed height for the content area
          child: TabBarView(
            controller: _tabController,
            children: [
              // My Requests Tab
              _buildRequestsList(_userRequests, isUserRequests: true),

              // Volunteer Requests Tab (only for certified volunteers)
              if (widget.userRole.toLowerCase() == 'certified_volunteer')
                _buildRequestsList(_volunteerRequests, isUserRequests: false)
              else
                Center(
                  child: Text(
                    'Only certified volunteers can see volunteer requests',
                    style: TextStyle(color: AppColors.islamicGreen600),
                  ),
                ),
            ],
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],

        // Refresh button
        SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadMeetingRequests,
            icon:
                _isLoading
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(Icons.refresh),
            label: Text(_isLoading ? 'Loading...' : 'Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.islamicGreen500,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(
    List<Map<String, dynamic>> requests, {
    required bool isUserRequests,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.islamicGreen600),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: AppColors.islamicGreen300,
            ),
            SizedBox(height: 16),
            Text(
              isUserRequests
                  ? 'No meeting requests yet'
                  : 'No volunteer requests yet',
              style: TextStyle(fontSize: 18, color: AppColors.islamicGreen600),
            ),
            SizedBox(height: 8),
            Text(
              isUserRequests
                  ? 'Create a meeting request to get started'
                  : 'Users will appear here when they request meetings',
              style: TextStyle(color: AppColors.islamicGreen500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _MeetingRequestCard(
          request: request,
          isUserRequest: isUserRequests,
          onRefresh: _loadMeetingRequests,
        );
      },
    );
  }
}

// Individual Meeting Request Card
class _MeetingRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isUserRequest;
  final VoidCallback onRefresh;

  const _MeetingRequestCard({
    Key? key,
    required this.request,
    required this.isUserRequest,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<_MeetingRequestCard> createState() => _MeetingRequestCardState();
}

class _MeetingRequestCardState extends State<_MeetingRequestCard> {
  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'accepted':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'completed':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status']?.toString() ?? 'pending';
    final createdAt = _formatDate(widget.request['createdAt']);
    final selectedSlot = widget.request['selectedSlot'];
    final zoomLink = widget.request['zoomLink'];
    final rejectReason = widget.request['rejectReason'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        _getStatusColor(status).replaceAll('#', '0xFF'),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'Created: $createdAt',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.islamicGreen600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Meeting details
            if (selectedSlot != null) ...[
              Text(
                'Selected Time:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${_formatDate(selectedSlot['start'])} - ${_formatDate(selectedSlot['end'])}',
                style: TextStyle(color: AppColors.islamicGreen700),
              ),
              SizedBox(height: 12),
            ],

            // Zoom link
            if (zoomLink != null && zoomLink.isNotEmpty) ...[
              Text(
                'Zoom Meeting:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                ),
              ),
              SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // Open zoom link
                  // You can use url_launcher package here
                },
                child: Text(
                  zoomLink,
                  style: TextStyle(
                    color: AppColors.islamicGreen600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],

            // Reject reason
            if (rejectReason != null && rejectReason.isNotEmpty) ...[
              Text(
                'Rejection Reason:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                ),
              ),
              SizedBox(height: 4),
              Text(rejectReason, style: TextStyle(color: Colors.red.shade700)),
              SizedBox(height: 12),
            ],

            // Action buttons for volunteers
            if (!widget.isUserRequest && status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTimeSlotSelection(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.islamicGreen600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Select Time'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade600),
                      ),
                      child: Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTimeSlotSelection(BuildContext context) {
    // Get the meeting request data
    final meetingId = widget.request['meetingId'];
    final preferredSlots = widget.request['preferredSlots'] as List<dynamic>?;

    if (preferredSlots == null || preferredSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No preferred time slots available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _TimeSlotSelectionDialog(
            meetingId: meetingId,
            preferredSlots: preferredSlots,
            onTimeSelected: (selectedIndex) async {
              Navigator.of(context).pop();
              await _selectTimeSlot(meetingId, selectedIndex);
            },
          ),
    );
  }

  Future<void> _selectTimeSlot(String meetingId, int selectedSlotIndex) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final result = await MeetingRequestService.selectTimeSlot(
        meetingId: meetingId,
        selectedSlotIndex: selectedSlotIndex,
        token: token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Time slot selected successfully! Zoom meeting created.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the meeting requests
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to select time slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(BuildContext context) {
    final meetingId = widget.request['meetingId'];
    final rejectController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reject Meeting Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please provide a reason for rejecting this meeting request:',
                ),
                SizedBox(height: 16),
                TextField(
                  controller: rejectController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter rejection reason...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reason = rejectController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please provide a rejection reason'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  await _rejectMeetingRequest(meetingId, reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectMeetingRequest(
    String meetingId,
    String rejectReason,
  ) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final result = await MeetingRequestService.rejectMeetingRequest(
        meetingId: meetingId,
        rejectReason: rejectReason,
        token: token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting request rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        // Refresh the meeting requests
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to reject meeting request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Time Slot Selection Dialog for PublicProfilePage
class _TimeSlotSelectionDialog extends StatefulWidget {
  final String meetingId;
  final List<dynamic> preferredSlots;
  final Function(int) onTimeSelected;

  const _TimeSlotSelectionDialog({
    Key? key,
    required this.meetingId,
    required this.preferredSlots,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<_TimeSlotSelectionDialog> createState() =>
      _TimeSlotSelectionDialogState();
}

class _TimeSlotSelectionDialogState extends State<_TimeSlotSelectionDialog> {
  int? _selectedSlotIndex;

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Time Slot'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose one of the preferred time slots:',
              style: TextStyle(color: AppColors.islamicGreen700),
            ),
            SizedBox(height: 16),
            ...widget.preferredSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              final isSelected = _selectedSlotIndex == index;

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                color: isSelected ? AppColors.islamicGreen100 : Colors.white,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSlotIndex = index;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _selectedSlotIndex,
                          onChanged: (value) {
                            setState(() {
                              _selectedSlotIndex = value;
                            });
                          },
                          activeColor: AppColors.islamicGreen600,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slot ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.islamicGreen800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatDate(slot['start'])} - ${_formatDate(slot['end'])}',
                                style: TextStyle(
                                  color: AppColors.islamicGreen700,
                                  fontSize: 12,
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
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedSlotIndex != null
                  ? () => widget.onTimeSelected(_selectedSlotIndex!)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.islamicGreen600,
            foregroundColor: Colors.white,
          ),
          child: Text('Select Time'),
        ),
      ],
    );
  }
}
