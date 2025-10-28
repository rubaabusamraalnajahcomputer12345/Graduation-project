import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config.dart';
import 'AddStoryPage.dart';

class Story {
  final String id;
  final String title;
  final String description;
  final String background;
  final String journeyToIslam;
  final String afterIslam;
  final String type; // "image", "video"
  final String? mediaUrl;
  final String quote;
  final String saveCount;
  final String likeCount;
  final String name;
  final String country;
  final List<String> tags;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.background,
    required this.journeyToIslam,
    required this.afterIslam,
    required this.type,
    this.mediaUrl,
    required this.quote,
    required this.saveCount,
    required this.likeCount,
    required this.name,
    required this.country,
    required this.tags,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final dynamic tagsJson = json['tags'] ?? [];
    return Story(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      background: (json['background'] ?? '').toString(),
      journeyToIslam: (json['journeyToIslam'] ?? '').toString(),
      afterIslam: (json['afterIslam'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      quote: (json['quote'] ?? '').toString(),
      saveCount: (json['saveCount'] ?? json['SaveCount'] ?? '0').toString(),
      likeCount: (json['likeCount'] ?? '0').toString(),
      name: (json['name'] ?? 'Anonymous').toString(),
      country: (json['country'] ?? '').toString(),
      tags:
          (tagsJson is List)
              ? tagsJson.map((e) => e.toString()).toList()
              : <String>[],
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class AdminStoriesPage extends StatefulWidget {
  final VoidCallback? onNavigateToAddStory;

  const AdminStoriesPage({Key? key, this.onNavigateToAddStory})
    : super(key: key);

  @override
  State<AdminStoriesPage> createState() => _AdminStoriesPageState();
}

class _AdminStoriesPageState extends State<AdminStoriesPage> {
  String _searchQuery = '';
  String _typeFilter = 'All Types';
  String _statusFilter = 'All Stories';
  Story? _selectedStory;

  // Islamic Color Palette - Exact match from design
  static const Color islamicGreen50 = Color(0xFFF4FBF7);
  static const Color islamicGreen100 = Color(0xFFE6F4ED);
  static const Color islamicGreen200 = Color(0xFFCCE8D8);
  static const Color islamicGreen300 = Color(0xFFB3DCC3);
  static const Color islamicGreen400 = Color(0xFF7AC09A);
  static const Color islamicGreen500 = Color(0xFF2D7A47);
  static const Color islamicGreen600 = Color(0xFF235831);
  static const Color islamicGreen700 = Color(0xFF1A4025);
  static const Color islamicGreen800 = Color(0xFF142E1C);
  static const Color islamicGreen900 = Color(0xFF0C1C12);
  static const Color islamicCream = Color(0xFFFDF8F0);

  // Stories fetched from API
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  // File upload variables
  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAndSetStories(page: 1);
  }

  Future<void> _fetchAndSetStories({int page = 1, bool append = false}) async {
    if (_isFetchingMore) return;
    if (append && (page > _totalPages)) return;
    if (mounted) {
      setState(() {
        if (!append) _isLoading = true;
        _error = null;
        _isFetchingMore = append;
      });
    }
    try {
      final response = await http.get(
        Uri.parse('$storyUrl?page=$page&limit=10'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> storiesJson =
            (data['data']?['stories'] as List<dynamic>? ?? <dynamic>[]);
        final List<Story> newStories =
            storiesJson
                .map((j) => Story.fromJson(j as Map<String, dynamic>))
                .toList();
        final pagination =
            (data['data']?['pagination'] as Map<String, dynamic>?) ?? {};
        if (mounted) {
          setState(() {
            if (append) {
              _stories.addAll(newStories);
            } else {
              _stories = newStories;
            }
            _isLoading = false;
            _isFetchingMore = false;
            _currentPage = (pagination['page'] ?? page) as int;
            _totalPages = (pagination['totalPages'] ?? 1) as int;
          });
        }
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  List<Story> get _filteredStories {
    return _stories.where((story) {
      final matchesSearch =
          story.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          story.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          story.tags.any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      final matchesType =
          _typeFilter == 'All Types' || story.type == _typeFilter.toLowerCase();

      bool matchesStatus = true;
      if (_statusFilter == 'Featured') {
        matchesStatus = int.parse(story.saveCount) > 20;
      } else if (_statusFilter == 'Popular') {
        matchesStatus = int.parse(story.likeCount) > 100;
      }

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: islamicCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revert Stories',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: islamicGreen800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and curate inspiring conversion stories',
                          style: TextStyle(
                            fontSize: 16,
                            color: islamicGreen600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddStoryDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Story'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: islamicGreen600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsCards(),
                const SizedBox(height: 24),

                // Filter Section
                Container(
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
                              'Filter Stories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: islamicGreen800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSearchAndFilters(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stories Table
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Container(
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
                              'Stories (${_filteredStories.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: islamicGreen800,
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredStories.length,
                        itemBuilder: (context, index) {
                          return _buildStoryRow(_filteredStories[index], index);
                        },
                      ),
                      if (_currentPage < _totalPages)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Align(
                            alignment: Alignment.center,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isFetchingMore
                                      ? null
                                      : () => _fetchAndSetStories(
                                        page: _currentPage + 1,
                                        append: true,
                                      ),
                              icon:
                                  _isFetchingMore
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.expand_more),
                              label: const Text('Load more'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalLikes = _stories.fold(
      0,
      (sum, story) => sum + int.parse(story.likeCount),
    );
    final totalSaves = _stories.fold(
      0,
      (sum, story) => sum + int.parse(story.saveCount),
    );

    final stats = [
      {
        'title': 'Total Stories',
        'value': _stories.length.toString(),
        'icon': Icons.brightness_6_outlined,
        'color': islamicGreen600,
      },

      {
        'title': 'Total Likes',
        'value': totalLikes.toString(),
        'icon': Icons.favorite_outline,
        'color': Colors.red,
      },
      {
        'title': 'Total Saves',
        'value': totalSaves.toString(),
        'icon': Icons.bookmark_outline,
        'color': Colors.orange,
      },
    ];

    return Row(
      children:
          stats.asMap().entries.map((entry) {
            final stat = entry.value;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: entry.key < stats.length - 1 ? 16 : 0,
                ),
                child: _buildStatCard(stat),
              ),
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
                    color: islamicGreen800,
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
              hintText: 'Search stories, authors, or tags...',
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
                borderSide: BorderSide(color: islamicGreen600),
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
        // Type Filter
        _buildFilterDropdown('Type', _typeFilter, [
          'All Types',
          'Image',
          'Video',
        ], (value) => setState(() => _typeFilter = value!)),
        const SizedBox(width: 16),
        // Status Filter
        _buildFilterDropdown('Status', _statusFilter, [
          'All Stories',
          'Featured',
          'Popular',
        ], (value) => setState(() => _statusFilter = value!)),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
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
            borderSide: BorderSide(color: islamicGreen600),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items:
            options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildHeaderCell('Story')),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildHeaderCell('Author')),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildHeaderCell('Type')),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildHeaderCell('Status')),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildHeaderCell('Engagement')),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildHeaderCell('Created')),
        const SizedBox(width: 24),
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

  Widget _buildStoryRow(Story story, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: InkWell(
        onTap: () => _showStoryDetails(story),
        child: Row(
          children: [
            // Story Column
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getMediaIcon(story.type),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          story.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children:
                        story.tags
                            .take(3)
                            .map((tag) => _buildBadge(tag, outlined: true))
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Author Column
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: islamicGreen100,
                    child: Text(
                      story.name.isNotEmpty
                          ? story.name
                              .split(' ')
                              .where((n) => n.isNotEmpty)
                              .map((n) => n[0])
                              .join('')
                          : '?',
                      style: TextStyle(
                        color: islamicGreen600,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          story.country,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Type Column
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildBadge(story.type, outlined: true),
              ),
            ),
            const SizedBox(width: 12),

            // Status Column
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(story),
              ),
            ),
            const SizedBox(width: 12),

            // Engagement Column
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  _buildEngagementStat(Icons.favorite_outline, story.likeCount),
                  const SizedBox(width: 12),
                  _buildEngagementStat(
                    Icons.brightness_6_outlined,
                    story.saveCount,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Created Column
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(story.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(width: 24),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleStoryAction(value, story),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Story'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Story'),
                    ),

                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Story'),
                    ),
                  ],
              child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getMediaIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'video':
        iconData = Icons.play_circle_outline;
        break;
      case 'image':
        iconData = Icons.image;
        break;
      default:
        iconData = Icons.brightness_6_outlined;
    }
    return Icon(iconData, size: 16, color: const Color(0xFF6B7280));
  }

  Widget _buildBadge(String text, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : const Color(0xFFF3F4F6),
        border: outlined ? Border.all(color: const Color(0xFFD1D5DB)) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: outlined ? const Color(0xFF6B7280) : const Color(0xFF374151),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Story story) {
    final saveCount = int.parse(story.saveCount);
    final likeCount = int.parse(story.likeCount);

    String status;
    Color color;

    if (saveCount > 20) {
      status = 'Featured';
      color = Colors.yellow.shade700;
    } else if (likeCount > 100) {
      status = 'Popular';
      color = Colors.green;
    } else {
      status = 'Standard';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    );
  }

  void _handleStoryAction(String action, Story story) {
    switch (action) {
      case 'view':
        _showStoryDetails(story);
        break;
      case 'edit':
        _showEditStoryDialog(story);
        break;
      case 'delete':
        _showDeleteConfirmation(story);
        break;
    }
  }

  void _showStoryDetails(Story story) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
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
                            'Story Details',
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
                          // Header Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      story.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      story.description,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: islamicGreen100,
                                          child: Text(
                                            story.name
                                                .split(' ')
                                                .map((n) => n[0])
                                                .join(''),
                                            style: TextStyle(
                                              color: islamicGreen600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              story.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              story.country,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  _buildEngagementStat(
                                    Icons.favorite_outline,
                                    story.likeCount,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEngagementStat(
                                    Icons.brightness_6_outlined,
                                    story.saveCount,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tags
                          Wrap(
                            spacing: 8,
                            children:
                                story.tags
                                    .map(
                                      (tag) => _buildBadge(tag, outlined: true),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 20),

                          // Story Sections
                          _buildStorySection(
                            'Background',
                            story.background,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildStorySection(
                            'Journey to Islam',
                            story.journeyToIslam,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildStorySection(
                            'After Islam',
                            story.afterIslam,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),

                          // Quote
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.yellow.shade400,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Text(
                              '"${story.quote}"',
                              style: TextStyle(
                                color: Colors.yellow.shade800,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Media URL Section
                          if (story.mediaUrl != null &&
                              story.mediaUrl!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        story.type == 'video'
                                            ? Icons.play_circle_outline
                                            : Icons.image,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Media ${story.type.toUpperCase()}',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      // Copy URL to clipboard
                                      Clipboard.setData(
                                        ClipboardData(text: story.mediaUrl!),
                                      );
                                      _showSnackbar(
                                        'Media URL copied to clipboard',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              story.mediaUrl!,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.copy,
                                            color: Colors.blue.shade600,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (story.mediaUrl != null &&
                              story.mediaUrl!.isNotEmpty)
                            const SizedBox(height: 16),

                          // Created Date
                          Text(
                            'Created: ${_formatDate(story.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
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
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditStoryDialog(story);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: islamicGreen600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Edit Story'),
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

  Widget _buildStorySection(String title, String content, MaterialColor color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: color.shade700, height: 1.5)),
        ],
      ),
    );
  }

  void _showAddStoryDialog() {
    if (widget.onNavigateToAddStory != null) {
      widget.onNavigateToAddStory!();
    } else {
      // Fallback to navigation if no callback provided
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AddStoryPage(onBackToStories: () => Navigator.pop(context)),
        ),
      );
    }
  }

  void _showEditStoryDialog(Story story) {
    // Reset file upload state
    _selectedFile = null;
    _uploadedFileUrl = null;
    _isUploading = false;

    // Local state for the dialog
    PlatformFile? selectedFile;
    String? uploadedFileUrl;
    bool isUploading = false;

    final titleController = TextEditingController(text: story.title);
    final descriptionController = TextEditingController(
      text: story.description,
    );
    final backgroundController = TextEditingController(text: story.background);
    final journeyController = TextEditingController(text: story.journeyToIslam);
    final afterIslamController = TextEditingController(text: story.afterIslam);
    final quoteController = TextEditingController(text: story.quote);
    final nameController = TextEditingController(text: story.name);
    final countryController = TextEditingController(text: story.country);
    final tagsController = TextEditingController(text: story.tags.join(', '));

    String selectedType = story.type;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
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
                            'Edit Story',
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

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Type Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildFormField(
                                    'Story Title',
                                    titleController,
                                    'Enter story title',
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Media Type',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      StatefulBuilder(
                                        builder:
                                            (
                                              context,
                                              setState,
                                            ) => DropdownButtonFormField<
                                              String
                                            >(
                                              value: selectedType,
                                              onChanged: (value) {
                                                setState(
                                                  () => selectedType = value!,
                                                );
                                              },
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              items:
                                                  ['image', 'video']
                                                      .map(
                                                        (
                                                          type,
                                                        ) => DropdownMenuItem(
                                                          value: type,
                                                          child: Text(
                                                            type.toUpperCase(),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildFormField(
                              'Description',
                              descriptionController,
                              'Brief description of the story...',
                              maxLines: 2,
                              required: true,
                            ),
                            const SizedBox(height: 16),

                            // Author Information Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    'Author Name',
                                    nameController,
                                    'Enter author name',
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    'Country',
                                    countryController,
                                    'Enter author country',
                                    required: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Background
                            _buildFormField(
                              'Background',
                              backgroundController,
                              'Author\'s background before Islam...',
                              maxLines: 3,
                              required: true,
                            ),
                            const SizedBox(height: 16),

                            // Journey to Islam
                            _buildFormField(
                              'Journey to Islam',
                              journeyController,
                              'How they discovered and embraced Islam...',
                              maxLines: 3,
                              required: true,
                            ),
                            const SizedBox(height: 16),

                            // After Islam
                            _buildFormField(
                              'After Islam',
                              afterIslamController,
                              'Life after accepting Islam...',
                              maxLines: 3,
                              required: true,
                            ),
                            const SizedBox(height: 16),

                            // Quote and Tags Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildFormField(
                                    'Inspirational Quote',
                                    quoteController,
                                    'A meaningful quote from the story',
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    'Tags',
                                    tagsController,
                                    'e.g. conversion, faith, journey',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Media Upload Section (if not text)
                            StatefulBuilder(
                              builder:
                                  (context, setState) =>
                                      selectedType != 'text'
                                          ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Upload Media',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                constraints:
                                                    const BoxConstraints(
                                                      minHeight: 120,
                                                      maxHeight: 200,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFD1D5DB,
                                                    ),
                                                    style: BorderStyle.solid,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: InkWell(
                                                  onTap: () async {
                                                    final result =
                                                        await FilePicker
                                                            .platform
                                                            .pickFiles();
                                                    if (result != null) {
                                                      selectedFile =
                                                          result.files.single;
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: SingleChildScrollView(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (isUploading)
                                                          const CircularProgressIndicator()
                                                        else
                                                          Icon(
                                                            Icons
                                                                .cloud_upload_outlined,
                                                            size: 48,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade400,
                                                          ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        if (selectedFile !=
                                                            null) ...[
                                                          Text(
                                                            'Selected: ${selectedFile!.name}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  islamicGreen600,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          ElevatedButton(
                                                            onPressed:
                                                                isUploading
                                                                    ? null
                                                                    : () async {
                                                                      setState(() {
                                                                        isUploading =
                                                                            true;
                                                                      });
                                                                      final url =
                                                                          await uploadFile(
                                                                            selectedFile!,
                                                                          );
                                                                      setState(() {
                                                                        isUploading =
                                                                            false;
                                                                        if (url
                                                                            .isNotEmpty) {
                                                                          uploadedFileUrl =
                                                                              url;
                                                                          _showSnackbar(
                                                                            'File uploaded successfully!',
                                                                          );
                                                                        } else {
                                                                          _showSnackbar(
                                                                            'Failed to upload file',
                                                                          );
                                                                        }
                                                                      });
                                                                    },
                                                            child: Text(
                                                              isUploading
                                                                  ? 'Uploading...'
                                                                  : 'Upload File',
                                                            ),
                                                          ),
                                                        ] else ...[
                                                          Text(
                                                            'Click to upload or drag and drop your ${selectedType} file',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ],
                                                        if (story.mediaUrl !=
                                                                null &&
                                                            uploadedFileUrl ==
                                                                null) ...[
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Current file: ${story.mediaUrl!.split('/').last}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  islamicGreen600,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                        if (uploadedFileUrl !=
                                                            null) ...[
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'New file uploaded successfully!',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          )
                                          : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer Actions
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
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                // Show loading state
                                setState(() {
                                  // You could add a loading state here if needed
                                });

                                final response = await http.patch(
                                  Uri.parse('$updateStoryUrl/${story.id}'),

                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'title': titleController.text,
                                    'description': descriptionController.text,
                                    'background': backgroundController.text,
                                    'journeyToIslam': journeyController.text,
                                    'afterIslam': afterIslamController.text,
                                    'type': selectedType,
                                    'mediaUrl':
                                        uploadedFileUrl ?? story.mediaUrl,
                                    'quote': quoteController.text,
                                    'name': nameController.text,
                                    'country': countryController.text,
                                    'tags':
                                        tagsController.text
                                            .split(',')
                                            .map((e) => e.trim())
                                            .where((e) => e.isNotEmpty)
                                            .toList(),
                                  }),
                                );
                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  _showSnackbar(
                                    'Story "${titleController.text}" updated successfully',
                                  );
                                  // Refresh the stories list
                                  _fetchAndSetStories(page: 1);
                                } else {
                                  final errorData = json.decode(response.body);
                                  print("errorData: $errorData");
                                  _showSnackbar(
                                    'Failed to update story: ${errorData['message'] ?? 'Unknown error'}',
                                  );
                                }
                              } catch (e) {
                                _showSnackbar(
                                  'Error updating story: ${e.toString()}',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: islamicGreen600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Update Story',
                            style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            children:
                required
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: BorderSide(color: islamicGreen600),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator:
              required
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Story story) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Delete Story'),
            content: Text(
              'Are you sure you want to delete "${story.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final url = Uri.parse("$deleteStoryUrl/${story.id}");
                    final response = await http.delete(url);
                    if (response.statusCode == 200) {
                      _showSnackbar('Story deleted successfully');

                      _fetchAndSetStories(page: 1);
                    } else {
                      _showSnackbar('Story deletion faild ');
                    }
                  } catch (e) {
                    _showSnackbar('Story deletion faild $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: islamicGreen600),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // File upload methods
  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = result.files.single;

      setState(() {
        _selectedFile = file;
        _uploadedFileUrl = null; // Reset URL on new selection
      });
    }
  }

  Future<String> uploadFile(PlatformFile file) async {
    print("uploadFil entered");
    Uint8List? fileBytes;
    final fileName = file.name;
    // Platform-safe file bytes access
    print("file: $file");
    if (file.bytes != null) {
      fileBytes = file.bytes;
      print("if fileBytes: $fileBytes");
    } else if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
      print("else if fileBytes: $fileBytes");
    }

    if (fileBytes == null) {
      print('❌ Unable to read file bytes');
      return '';
    }
    try {
      final response = await Supabase.instance.client.storage
          .from('story') // ✅ use same bucket
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isNotEmpty) {
        print('Upload successful');

        final publicUrl = Supabase.instance.client.storage
            .from('story') // ✅ use same bucket
            .getPublicUrl(fileName);

        print('🌍 Public URL: $publicUrl');
        return publicUrl;
      } else {
        print(' Error uploading: $response');
      }
    } catch (e) {
      print(' Exception during upload: $e');
    }

    return '';
  }
}
