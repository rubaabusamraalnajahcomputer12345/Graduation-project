import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class FlagData {
  final String? notificationSentAt;
  final String? notificationSentAtDismissed;
  final String id;
  final String flagId;
  final String itemType;
  final String itemId;
  final String reportedBy;
  final String reason;
  String status;
  final DateTime createdAt;
  final int v;
  final bool sleepmode;
  final Reporter reporter;
  final ItemDetails itemDetails;

  FlagData({
    required this.notificationSentAt,
    required this.notificationSentAtDismissed,
    required this.id,
    required this.flagId,
    required this.itemType,
    required this.itemId,
    required this.reportedBy,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.v,
    required this.sleepmode,
    required this.reporter,
    required this.itemDetails,
  });

  factory FlagData.fromJson(Map<String, dynamic> json) {
    return FlagData(
      notificationSentAt: json['notificationSentAt'],
      notificationSentAtDismissed: json['notificationSentAtDismissed'],
      id: json['_id'] ?? '',
      flagId: json['flagId'] ?? '',
      itemType: json['itemType'] ?? '',
      itemId: json['itemId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      v: json['__v'] ?? 0,
      sleepmode: json['sleepmode'] ?? false,
      reporter: Reporter.fromJson(json['reporter'] ?? {}),
      itemDetails: ItemDetails.fromJson(json['itemDetails'] ?? {}),
    );
  }
}

class Reporter {
  final String displayName;
  final String email;
  final String id;
  final String gender;
  final String role;
  final String country;

  Reporter({
    required this.displayName,
    required this.email,
    required this.id,
    required this.gender,
    required this.role,
    required this.country,
  });

  factory Reporter.fromJson(Map<String, dynamic> json) {
    return Reporter(
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      id: json['id'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class ItemDetails {
  final String id;
  final String answerId;
  final String questionId;
  final String text;
  final AnsweredBy answeredBy;
  final AskedBy askedBy;
  final DateTime createdAt;
  final String language;
  final int upvotesCount;
  final int v;
  final bool isFlagged;
  final bool isHidden;
  final bool hiddenTemporary;

  ItemDetails({
    required this.id,
    required this.answerId,
    required this.questionId,
    required this.text,
    required this.answeredBy,
    required this.askedBy,
    required this.createdAt,
    required this.language,
    required this.upvotesCount,
    required this.v,
    required this.isFlagged,
    required this.isHidden,
    required this.hiddenTemporary,
  });

  factory ItemDetails.fromJson(Map<String, dynamic> json) {
    return ItemDetails(
      id: json['_id'] ?? '',
      answerId: json['answerId'] ?? '',
      questionId: json['questionId'] ?? '',
      text: json['text'] ?? '',
      answeredBy: AnsweredBy.fromJson(json['answeredBy'] ?? {}),
      askedBy: AskedBy.fromJson(json['askedBy'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      language: json['language'] ?? '',
      upvotesCount: json['upvotesCount'] ?? 0,
      v: json['__v'] ?? 0,
      isFlagged: json['isFlagged'] ?? false,
      isHidden: json['isHidden'] ?? false,
      hiddenTemporary: json['hiddenTemporary'] ?? false,
    );
  }
}

class AnsweredBy {
  final String displayName;
  final String email;
  final String id;
  final String gender;
  final String role;
  final String country;

  AnsweredBy({
    required this.displayName,
    required this.email,
    required this.id,
    required this.gender,
    required this.role,
    required this.country,
  });

  factory AnsweredBy.fromJson(Map<String, dynamic> json) {
    return AnsweredBy(
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      id: json['id'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class AskedBy {
  final String displayName;
  final String email;
  final String id;
  final String gender;
  final String role;
  final String country;

  AskedBy({
    required this.displayName,
    required this.email,
    required this.id,
    required this.gender,
    required this.role,
    required this.country,
  });

  factory AskedBy.fromJson(Map<String, dynamic> json) {
    return AskedBy(
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      id: json['id'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class FlagsAdminPage extends StatefulWidget {
  const FlagsAdminPage({Key? key}) : super(key: key);

  @override
  State<FlagsAdminPage> createState() => _FlagsAdminPageState();
}

class _FlagsAdminPageState extends State<FlagsAdminPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  FlagData? _selectedFlag;

  Future<void> _fetchFlags() async {
    try {
      final response = await http.get(Uri.parse(adminFlags));
      print("🧕🧕🧕Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _flags = data.map((flag) => FlagData.fromJson(flag)).toList();
        });
        print("Fetched flags: ${_flags}");
      }
    } catch (e) {
      // Handle error, optionally show a snackbar or log
    }
  }

  // Use centralized AppColors instead of local constants

  List<FlagData> _flags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFlags();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FlagData> get _filteredFlags {
    final currentType = _tabController.index == 0 ? "question" : "answer";
    return _flags.where((flag) {
      final matchesType = flag.itemType == currentType;
      final matchesSearch =
          flag.flagId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          flag.itemId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          flag.reportedBy.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          flag.reason.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'All Status' ||
          flag.status == _selectedStatus.toLowerCase();
      return matchesType && matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.islamicCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flags / Reports',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.adminGreen800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and moderate user-reported content',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.adminGreen600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tab Navigation
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      'Questions (${_flags.where((f) => f.itemType == "question").length})',
                      0,
                    ),
                    _buildTabButton(
                      'Answers (${_flags.where((f) => f.itemType == "answer").length})',
                      1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsCards(),
              const SizedBox(height: 24),

              // Content Card
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Section Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _tabController.index == 0
                                ? 'Question Flags'
                                : 'Answer Flags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adminGreen800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search and Filters
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchAndFilters(),
                    ),

                    // Results Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing 1 to ${_filteredFlags.length} of ${_filteredFlags.length} results',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: _buildTableHeader(),
                    ),

                    // Table Content
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredFlags.length,
                        itemBuilder: (context, index) {
                          return _buildFlagRow(_filteredFlags[index], index);
                        },
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
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.adminGreen600 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'Total Flags',
        'value': _flags.length.toString(),
        'icon': Icons.shield_outlined,
        'color': Colors.red,
      },
    ];

    return Row(
      children:
          stats.asMap().entries.map((entry) {
            final stat = entry.value;
            return Container(
              width: 250,
              margin: EdgeInsets.only(
                right: entry.key < stats.length - 1 ? 16 : 0,
              ),
              child: _buildStatCard(stat),
            );
          }).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(stat['icon'], size: 32, color: stat['color']),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['value'],
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminGreen800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText:
                  _tabController.index == 0
                      ? 'Search questions flags...'
                      : 'Search answers flags...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.adminGreen600),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Status Filter
        _buildStatusFilter(),
      ],
    );
  }

  Widget _buildStatusFilterButton(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final List<String> statuses = [
      'All Status',
      'pending',
      'dismissed',
      'resolved',
      'rejected',
    ];

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedStatus = value;
        });
      },
      itemBuilder:
          (BuildContext context) =>
              statuses.map((String status) {
                return PopupMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      if (_selectedStatus == status)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.islamicGreen600,
                        ),
                      if (_selectedStatus != status) const SizedBox(width: 16),
                      Text(status[0].toUpperCase() + status.substring(1)),
                    ],
                  ),
                );
              }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              _selectedStatus[0].toUpperCase() + _selectedStatus.substring(1),
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildHeaderCell('Reported By')),
        Expanded(flex: 4, child: _buildHeaderCell('Reason')),
        Expanded(flex: 1, child: _buildHeaderCell('Status')),
        Expanded(flex: 1, child: _buildHeaderCell('Created At')),
        const SizedBox(width: 20), // Actions column
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFlagRow(FlagData flag, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: InkWell(
        onTap: () => _showFlagDetails(flag),
        child: Row(
          children: [
            /*  // Flag ID Column
            Expanded(
              flex: 2,
              child: Text(
                flag.flagId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Item ID Column
            Expanded(
              flex: 2,
              child: Text(
                flag.itemId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            },
 */
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.islamicGreen100,
                    child: Text(
                      // For Question Row
                      flag.reportedBy
                          .split(' ')
                          .where((n) => n.isNotEmpty)
                          .take(2)
                          .map((n) => n[0])
                          .join('')
                          .toUpperCase(),
                      style: TextStyle(
                        color: AppColors.adminGreen600,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flag.reporter.displayName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Reason Column
            Expanded(
              flex: 4,
              child: Text(
                flag.reason,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status Column
            Expanded(flex: 1, child: _buildStatusBadge(flag.status)),
            const SizedBox(width: 10),
            // Created At Column
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(flag.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleFlagAction(value, flag),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'resolve',
                      child: Text('Approve Resolution'),
                    ),
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Text('Dismiss Flag'),
                    ),
                  ],
              child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;
    //"pending", "dismissed", "resolved", "rejected"
    switch (status) {
      case 'pending':
        color = Colors.orange;
        displayText = 'pending';
        break;
      case 'resolved':
        color = Colors.green;
        displayText = 'resolved';
        break;
      case 'dismissed':
        color = Colors.blue;
        displayText = 'dismissed';
        break;
      case 'rejected':
        color = Colors.red;
        displayText = 'rejected';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleFlagAction(String action, FlagData flag) async {
    switch (action) {
      case 'view':
        _showFlagDetails(flag);
        break;
      case 'resolve':
        await http.put(Uri.parse('${adminResolveFlagUrl}${flag.flagId}'));
        setState(() {
          final idx = _flags.indexWhere((f) => f.flagId == flag.flagId);
          if (idx != -1) {
            _flags[idx].status = 'resolved';
          }
        });
        _showSnackbar('Flag ${flag.flagId} has been marked as resolved.');
        break;
      case 'dismiss':
        await http.put(Uri.parse('${adminDismissFlagUrl}${flag.flagId}'));
        setState(() {
          final idx = _flags.indexWhere((f) => f.flagId == flag.flagId);
          if (idx != -1) {
            _flags[idx].status = 'dismissed';
          }
        });
        _showSnackbar('Flag ${flag.flagId} has been dismissed.');
        break;
    }
  }

  void _showFlagDetails(FlagData flag) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 800,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Flag Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Flag Information
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flag Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.adminGreen800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                            'Flag ID:',
                                            flag.flagId,
                                          ),
                                          _buildDetailRow(
                                            'Item ID:',
                                            flag.itemId,
                                          ),
                                          _buildDetailRow(
                                            'Item Type:',
                                            flag.itemType,
                                          ),
                                          _buildDetailRow(
                                            'Status:',
                                            flag.status,
                                          ),
                                          _buildDetailRow(
                                            'Reported By:',
                                            flag.reporter.displayName,
                                          ),
                                          _buildDetailRow(
                                            'Reporter Email:',
                                            flag.reporter.email,
                                          ),
                                          _buildDetailRow(
                                            'Created:',
                                            _formatDateTime(flag.createdAt),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flagged Content',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.adminGreen800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                            'Author:',
                                            flag.itemType == 'question'
                                                ? flag
                                                    .itemDetails
                                                    .askedBy
                                                    .displayName
                                                : flag
                                                    .itemDetails
                                                    .answeredBy
                                                    .displayName,
                                          ),
                                          _buildDetailRow(
                                            'Author Email:',
                                            flag.itemType == 'question'
                                                ? flag.itemDetails.askedBy.email
                                                : flag
                                                    .itemDetails
                                                    .answeredBy
                                                    .email,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Content:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFE5E7EB),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              flag.itemDetails.text ??
                                                  'No content available',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Report Reason
                          Text(
                            'Report Reason',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adminGreen800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              flag.reason,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await http.put(
                                    Uri.parse(
                                      '${adminDismissFlagUrl}${flag.flagId}',
                                    ),
                                  );
                                  setState(() {
                                    final idx = _flags.indexWhere(
                                      (f) => f.flagId == flag.flagId,
                                    );
                                    if (idx != -1) {
                                      _flags[idx].status = 'dismissed';
                                    }
                                  });
                                  Navigator.pop(context);
                                  _showSnackbar(
                                    'Flag ${flag.flagId} has been dismissed for an hour.',
                                  );
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Dismiss Flag'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  //delete the flagged content
                                  await http.put(
                                    Uri.parse(
                                      '${adminResolveFlagUrl}${flag.flagId}',
                                    ),
                                  );
                                  setState(() {
                                    final idx = _flags.indexWhere(
                                      (f) => f.flagId == flag.flagId,
                                    );
                                    if (idx != -1) {
                                      _flags[idx].status = 'resolved';
                                    }
                                  });
                                  Navigator.pop(context);
                                  _showSnackbar('Flagged content is removed.');
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Resolve'),
                                style: ElevatedButton.styleFrom(
                                  iconColor: Colors.red,
                                  foregroundColor: Colors.red,
                                  overlayColor: Colors.red.withOpacity(0.1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                label: const Text('Reject'),

                                onPressed: () async {
                                  //ignore the flag and keep the content
                                  await http.put(
                                    Uri.parse(
                                      '${adminRejectFlagUrl}${flag.flagId}',
                                    ),
                                  );
                                  setState(() {
                                    final idx = _flags.indexWhere(
                                      (f) => f.flagId == flag.flagId,
                                    );
                                    if (idx != -1) {
                                      _flags[idx].status = 'rejected';
                                    }
                                  });
                                  Navigator.pop(context);
                                  _showSnackbar(
                                    'Flag is ignored and content is kept.',
                                  );
                                },
                                icon: const Icon(Icons.check, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.adminGreen600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
