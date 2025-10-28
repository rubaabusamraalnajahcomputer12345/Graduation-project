// lib/pages/admin/admin_lessons_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../LessonsPlayer.dart';

class AdminLessonsPage extends StatefulWidget {
  @override
  _AdminLessonsPageState createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage> {
  final _searchController = TextEditingController();
  String _categoryFilter = 'all';
  String _statusFilter = 'all';
  bool _isLessonPlayerOpen = false;
  Lesson? _selectedLesson;
  LessonData? _selectedLessonData;

  final _formData = {
    'title': '',
    'description': '',
    'category': '',
    'level': '',
    'icon': '',
    'estimatedTime': '',
  };

  final List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(getalllesson));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == true && decoded['lesson'] is List) {
          final List items = decoded['lesson'] as List;
          final List<Lesson> mapped =
              items.map<Lesson>((raw) {
                final Map<String, dynamic> m = raw as Map<String, dynamic>;
                final dynamic id = m['lessonId'] ?? UniqueKey().toString();
                final String title = (m['title'] ?? '').toString();
                final String description = (m['description'] ?? '').toString();
                final String category = (m['category'] ?? '').toString();
                final int estimatedTime =
                    (m['estimatedTime'] is int)
                        ? m['estimatedTime'] as int
                        : int.tryParse(
                              (m['estimatedTime'] ?? '0').toString(),
                            ) ??
                            0;
                final String duration =
                    estimatedTime > 0 ? '${estimatedTime} min' : '—';
                // Defaults for fields not provided by API
                return Lesson(
                  id: id.toString(),
                  title: title,
                  description: description,
                  category: category.isEmpty ? 'General' : category,
                  rating: double.tryParse((m['rating'] ?? 0).toString()) ?? 0,
                  ratingCount:
                      int.tryParse((m['ratingCount'] ?? 0).toString()) ?? 0,
                  createdAt: (m['createdAt'] ?? '').toString(),
                  updatedAt: (m['updatedAt'] ?? '').toString(),
                  author: (m['author'] ?? 'Unknown').toString(),
                  duration: duration,
                  enrollments:
                      int.tryParse((m['enrollments'] ?? 0).toString()) ?? 0,
                  mediaType: (m['mediaType'] ?? 'text').toString(),
                  mediaUrl:
                      (m['mediaUrl'] ?? '').toString().isEmpty
                          ? null
                          : (m['mediaUrl'] ?? '').toString(),
                  status: (m['status'] ?? 'published').toString(),
                  language: (m['language'] ?? 'English').toString(),
                  level:
                      (m['level'] ?? '').toString().isEmpty
                          ? null
                          : (m['level'] ?? '').toString(),
                  icon:
                      (m['icon'] ?? '').toString().isEmpty
                          ? null
                          : (m['icon'] ?? '').toString(),
                  estimatedTime:
                      m['estimatedTime'] is int
                          ? m['estimatedTime'] as int
                          : int.tryParse(
                            (m['estimatedTime'] ?? '0').toString(),
                          ),
                );
              }).toList();
          setState(() {
            _lessons
              ..clear()
              ..addAll(mapped);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response structure';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load lessons (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lessons';
        _isLoading = false;
      });
    }
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((lesson) {
      final matchesSearch =
          lesson.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          lesson.author.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesCategory =
          _categoryFilter == 'all' || lesson.category == _categoryFilter;
      final matchesStatus =
          _statusFilter == 'all' || lesson.status == _statusFilter;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Widget _getStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'beginner':
        backgroundColor = AppColors.islamicGreen100;
        textColor = AppColors.islamicGreen800;
        break;
      case 'intermediate':
        backgroundColor = AppColors.islamicGold100;
        textColor = AppColors.islamicGold800;
        break;
      case 'advanced':
        backgroundColor = AppColors.grey100;
        textColor = AppColors.grey800;
        break;
      default:
        backgroundColor = AppColors.grey100;
        textColor = AppColors.grey800;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getMediaIcon(String mediaType) {
    switch (mediaType) {
      case 'video':
        return Icons.play_arrow;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      case 'text':
      default:
        return Icons.book;
    }
  }

  Future<void> _handleViewLesson(Lesson lesson) async {
    try {
      print(getlessonbyid + lesson.id);
      final response = await http.get(Uri.parse(getlessonbyid + lesson.id));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        if (decoded['status'] == true &&
            decoded['lesson'] is Map<String, dynamic>) {
          final Map<String, dynamic> l =
              decoded['lesson'] as Map<String, dynamic>;
          final String title = (l['title'] ?? lesson.title).toString();
          final List steps =
              (l['steps'] is List) ? (l['steps'] as List) : <dynamic>[];

          // Sort by stepNumber ascending if available
          steps.sort((a, b) {
            final int sa =
                int.tryParse(((a as Map)['stepNumber'] ?? 0).toString()) ?? 0;
            final int sb =
                int.tryParse(((b as Map)['stepNumber'] ?? 0).toString()) ?? 0;
            return sa.compareTo(sb);
          });

          final parsedSteps =
              steps.map<LessonStep>((s) {
                final Map<String, dynamic> m = s as Map<String, dynamic>;
                final String mediaType = (m['mediaType'] ?? '').toString();
                final String mediaUrl = (m['mediaUrl'] ?? '').toString();
                return LessonStep(
                  title: (m['title'] ?? '').toString(),
                  description: (m['description'] ?? '').toString(),
                  mediaType: mediaType,
                  mediaUrl: mediaUrl,
                );
              }).toList();

          setState(() {
            _selectedLessonData = LessonData(
              lessonTitle: title,
              steps: parsedSteps,
            );
            _isLessonPlayerOpen = true;
          });
          return;
        }
      }

      // Fallback if API call fails
      setState(() {
        _selectedLessonData = LessonData(
          lessonTitle: lesson.title,
          steps: [
            LessonStep(
              title: 'Unable to load',
              description: 'Could not fetch lesson details. Please try again.',
              mediaType: 'image',
              mediaUrl:
                  'https://via.placeholder.com/800x450/cccccc/000000?text=Error',
            ),
          ],
        );
        _isLessonPlayerOpen = true;
      });
    } catch (e) {
      // Error fallback
      setState(() {
        _selectedLessonData = LessonData(
          lessonTitle: lesson.title,
          steps: [
            LessonStep(
              title: 'Unable to load',
              description: 'Could not fetch lesson details. Please try again.',
              mediaType: 'image',
              mediaUrl:
                  'https://via.placeholder.com/800x450/cccccc/000000?text=Error',
            ),
          ],
        );
        _isLessonPlayerOpen = true;
      });
    }
  }

  void _handleEditLesson(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
      _formData['title'] = lesson.title;
      _formData['description'] = lesson.description;
      _formData['category'] = lesson.category;
      _formData['level'] = lesson.level ?? 'beginner';
      _formData['icon'] = lesson.icon ?? '📚';
      _formData['estimatedTime'] = lesson.estimatedTime?.toString() ?? '30';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildEditDialog();
      },
    );
  }

  Future<void> _handleDeleteLesson(Lesson lesson) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Lesson'),
          content: Text(
            'Are you sure you want to delete "${lesson.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$deleteLessonUrl${lesson.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Remove lesson from local list
        setState(() {
          _lessons.removeWhere((l) => l.id == lesson.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson "${lesson.title}" has been deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete lesson');
      }
    } catch (error) {
      print('Delete lesson error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete lesson. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddLesson() {
    Navigator.pushNamed(context, '/admin/lessons/add');
  }

  Future<void> _handleUpdateLesson() async {
    if (_selectedLesson == null) return;

    try {
      final estimatedTime =
          int.tryParse(_formData['estimatedTime'] ?? '30') ?? 30;
      final updateData = {
        'title': _formData['title'],
        'description': _formData['description'],
        'category': _formData['category'],
        'level': _formData['level'],
        'icon': _formData['icon'],
        'estimatedTime': estimatedTime,
      };

      final response = await http.put(
        Uri.parse('$updateLessonUrl${_selectedLesson!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        // Update lesson in local list
        final updatedLesson = Lesson(
          id: _selectedLesson!.id,
          title: _formData['title']!,
          description: _formData['description']!,
          category: _formData['category']!,
          rating: _selectedLesson!.rating,
          ratingCount: _selectedLesson!.ratingCount,
          createdAt: _selectedLesson!.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          author: _selectedLesson!.author,
          duration: '${updateData['estimatedTime']} min',
          enrollments: _selectedLesson!.enrollments,
          mediaType: _selectedLesson!.mediaType,
          mediaUrl: _selectedLesson!.mediaUrl,
          status: _selectedLesson!.status,
          language: _selectedLesson!.language,
          level: _formData['level'],
          icon: _formData['icon'],
          estimatedTime: estimatedTime,
        );

        setState(() {
          final index = _lessons.indexWhere((l) => l.id == _selectedLesson!.id);
          if (index != -1) {
            _lessons[index] = updatedLesson;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson "${_formData['title']}" has been updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update lesson');
      }
    } catch (error) {
      print('Update lesson error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update lesson. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    final filteredLessons = _filteredLessons;
    final totalEnrollments = _lessons.fold(
      0,
      (sum, lesson) => sum + lesson.enrollments,
    );
    final publishedCount =
        _lessons.where((lesson) => lesson.status == 'published').length;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lessons Management',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lessonsTitle,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create, edit, and manage educational content',
                          style: TextStyle(
                            color: AppColors.lessonsSubtitle,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                /*   ElevatedButton.icon(
                    onPressed: _navigateToAddLesson,
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add Lesson'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lessonsHumanBadge,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ), */
                ],
              ),

              SizedBox(height: 24),

              // Stats Cards
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.book,
                    iconColor: AppColors.lessonsHumanBadge,
                    title: 'Total Lessons',
                    value: _lessons.length.toString(),
                  ),
                  /*  _buildStatCard(
                    icon: Icons.people,
                    iconColor: AppColors.infoBlue,
                    title: 'Total Enrollments',
                    value: totalEnrollments.toString(),
                  ),
                  // Removed Average Rating card per requirements
                  _buildStatCard(
                    icon: Icons.schedule,
                    iconColor: AppColors.adminPanelGreen400,
                    title: 'Published',
                    value: publishedCount.toString(),
                  ), */
                ],
              ),

              SizedBox(height: 24),

              // Filters Card
              Card(
                color: AppColors.islamicWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.lessonsBorder),
                ),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Lessons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lessonsTitle,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          // Search
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search lessons or authors...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.grey500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.grey300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.grey300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsHumanBadge,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Category Filter
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String>(
                              value: _categoryFilter,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Categories'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prayer',
                                  child: Text('Prayer'),
                                ),
                                DropdownMenuItem(
                                  value: 'Purification',
                                  child: Text('Purification'),
                                ),
                                DropdownMenuItem(
                                  value: 'Fasting',
                                  child: Text('Fasting'),
                                ),
                                DropdownMenuItem(
                                  value: 'Business Ethics',
                                  child: Text('Business Ethics'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _categoryFilter = value ?? 'all';
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          // Status Filter
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Status'),
                                ),
                                DropdownMenuItem(
                                  value: 'published',
                                  child: Text('Published'),
                                ),
                                DropdownMenuItem(
                                  value: 'draft',
                                  child: Text('Draft'),
                                ),
                                DropdownMenuItem(
                                  value: 'archived',
                                  child: Text('Archived'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _statusFilter = value ?? 'all';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Lessons Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: filteredLessons.length,
                itemBuilder: (context, index) {
                  final lesson = filteredLessons[index];
                  return Card(
                    color: AppColors.islamicWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.lessonsBorder),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getMediaIcon(lesson.mediaType),
                                    size: 16,
                                    color: AppColors.grey500,
                                  ),
                                  SizedBox(width: 8),
                                  _getStatusBadge(lesson.level ?? ""),
                                  Spacer(),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_horiz, size: 16),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _handleViewLesson(lesson);
                                          break;
                                        case 'edit':
                                          _handleEditLesson(lesson);
                                          break;
                                        case 'delete':
                                          _handleDeleteLesson(lesson);
                                          break;
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text('View Details'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 16),
                                                SizedBox(width: 8),
                                                Text('Edit Lesson'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuDivider(),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: AppColors.errorRed,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete Lesson',
                                                  style: TextStyle(
                                                    color: AppColors.errorRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if ((lesson.icon ?? '').isNotEmpty) ...[
                                    Text(
                                      lesson.icon!,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      lesson.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.lessonsTitle,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                lesson.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.lessonsSubtitle,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.grey300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    lesson.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lessonsSubtitle,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Rating removed per requirements
                              SizedBox(height: 12),

                              // Duration and Enrollments
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lesson.duration,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lessonsSubtitle,
                                    ),
                                  ),
                                  /* Text(
                                    '${lesson.enrollments} enrolled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lessonsSubtitle,
                                    ),
                                  ), */
                                ],
                              ),
                              SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () => _handleViewLesson(lesson),
                                      icon: Icon(Icons.visibility, size: 16),
                                      label: Text('View'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.lessonsTitle,
                                        side: BorderSide(
                                          color: AppColors.lessonsBorder,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => _handleEditLesson(lesson),
                                      icon: Icon(Icons.edit, size: 16),
                                      label: Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.lessonsHumanBadge,
                                        foregroundColor: AppColors.islamicWhite,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
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
            ],
          ),
        ),

        // Lesson Player Modal
        if (_selectedLessonData != null)
          LessonPlayer(
            isOpen: _isLessonPlayerOpen,
            onClose: () {
              setState(() {
                _isLessonPlayerOpen = false;
                _selectedLessonData = null;
              });
            },
            onCloseWithProgress: null, // Admin view doesn't track progress
            lessonData: _selectedLessonData!,
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      color: AppColors.islamicWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lessonsBorder),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: iconColor),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lessonsSubtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lessonsTitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.islamicWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lessonsHumanBadge,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.islamicWhite, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Edit Lesson',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.islamicWhite,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.islamicWhite,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      controller: TextEditingController(
                        text: _formData['title'],
                      ),
                      onChanged: (value) => _formData['title'] = value,
                    ),
                    SizedBox(height: 16),

                    // Description Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      controller: TextEditingController(
                        text: _formData['description'],
                      ),
                      onChanged: (value) => _formData['description'] = value,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    // Category Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      controller: TextEditingController(
                        text: _formData['category'],
                      ),
                      onChanged: (value) => _formData['category'] = value,
                    ),
                    SizedBox(height: 16),

                    // Level Field
                    DropdownButtonFormField<String>(
                      value:
                          const [
                                'beginner',
                                'intermediate',
                                'advanced',
                              ].contains(_formData['level'])
                              ? _formData['level']
                              : 'beginner',
                      decoration: InputDecoration(
                        labelText: 'Level *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Beginner'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Intermediate'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Advanced'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _formData['level'] = value ?? 'beginner';
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Icon Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Icon *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      controller: TextEditingController(
                        text: _formData['icon'],
                      ),
                      onChanged: (value) => _formData['icon'] = value,
                    ),
                    SizedBox(height: 16),

                    // Estimated Time Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Estimated Time (minutes) *',
                        labelStyle: TextStyle(color: AppColors.lessonsSubtitle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lessonsHumanBadge,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.islamicWhite,
                      ),
                      controller: TextEditingController(
                        text: _formData['estimatedTime'],
                      ),
                      onChanged: (value) => _formData['estimatedTime'] = value,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lessonsTitle,
                            side: BorderSide(color: AppColors.lessonsBorder),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _handleUpdateLesson();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lessonsHumanBadge,
                            foregroundColor: AppColors.islamicWhite,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Update Lesson'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String category;
  final double rating;
  final int ratingCount;
  final String createdAt;
  final String updatedAt;
  final String author;
  final String duration;
  final int enrollments;
  final String mediaType;
  final String? mediaUrl;
  final String status;
  final String language;
  final String? level;
  final String? icon;
  final int? estimatedTime;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.duration,
    required this.enrollments,
    required this.mediaType,
    this.mediaUrl,
    required this.status,
    required this.language,
    this.level,
    this.icon,
    this.estimatedTime,
  });
}
