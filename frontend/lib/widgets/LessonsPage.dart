// lib/pages/lessons_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'LessonsPlayer.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:frontend/utils/auth_utils.dart';

class LessonsPage extends StatefulWidget {
  @override
  _LessonsPageState createState() => _LessonsPageState();
}

class _LessonsPageState extends State {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _selectedLevel = 'all';
  bool _isLessonPlayerOpen = false;
  LessonData? _selectedLessonData;
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All Categories'},
    {'id': 'fundamentals', 'name': 'Islamic Fundamentals'},
    {'id': 'worship', 'name': 'Worship & Prayer'},
    {'id': 'quran', 'name': 'Quran Studies'},
    {'id': 'hadith', 'name': 'Hadith & Sunnah'},
    {'id': 'history', 'name': 'Islamic History'},
    {'id': 'ethics', 'name': 'Islamic Ethics'},
    {'id': 'family', 'name': 'Family & Marriage'},
    {'id': 'finance', 'name': 'Islamic Finance'},
  ];

  final List<Map<String, String>> _levels = [
    {'id': 'all', 'name': 'All Levels'},
    {'id': 'beginner', 'name': 'Beginner'},
    {'id': 'intermediate', 'name': 'Intermediate'},
    {'id': 'advanced', 'name': 'Advanced'},
  ];

  final List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(getalllesson));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['status'] == true && decoded['lesson'] is List) {
          final List lessons = decoded['lesson'] as List;
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final List progressList = userProvider.lessonsProgress;
          final mapped =
              lessons.map<Map<String, dynamic>>((item) {
                final Map<String, dynamic> m = item as Map<String, dynamic>;
                final dynamic id =
                    m['_id'] ?? m['lessonId'] ?? UniqueKey().toString();
                final String title = (m['title'] ?? '').toString();
                final String description = (m['description'] ?? '').toString();
                final String category = (m['category'] ?? '').toString();
                final String level = (m['level'] ?? '').toString();
                final String icon = (m['icon'] ?? '📘').toString();
                final int estimatedTime =
                    (m['estimatedTime'] is int)
                        ? m['estimatedTime'] as int
                        : int.tryParse(
                              (m['estimatedTime'] ?? '0').toString(),
                            ) ??
                            0;
                final String lessonId = (m['lessonId'] ?? id).toString();
                Map? progress;
                for (final e in progressList) {
                  if (e is Map &&
                      (e['lessonId']?.toString() ?? '') == lessonId) {
                    progress = e;
                    break;
                  }
                }
                final int currentStep =
                    int.tryParse((progress?['currentStep'] ?? 0).toString()) ??
                    0;
                final bool completed = (progress?['completed'] == true);
                return {
                  'id': id,
                  'lessonId': lessonId,
                  'title': title,
                  'description': description,
                  'category': category,
                  'level': level,
                  'duration': '${estimatedTime} min',
                  'image': icon,
                  'progress': {
                    'currentStep': currentStep,
                    'completed': completed,
                  },
                };
              }).toList();
          if (!mounted) return;
          setState(() {
            _lessons
              ..clear()
              ..addAll(mapped);
            _isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Unexpected response structure.';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load lessons (${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load lessons.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLessons {
    return _lessons.where((lesson) {
      final matchesSearch =
          lesson['title'].toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          lesson['description'].toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == 'all' ||
          lesson['category'].toLowerCase().contains(_selectedCategory);
      final matchesLevel =
          _selectedLevel == 'all' ||
          lesson['level'].toLowerCase() == _selectedLevel;

      return matchesSearch && matchesCategory && matchesLevel;
    }).toList();
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.lessonsBorder;
      case 'intermediate':
        return AppColors.lessonsPrivateBorder;
      case 'advanced':
        return AppColors.lessonsErrorBorder;
      default:
        return AppColors.lessonsGreyBorder;
    }
  }

  Color _getLevelTextColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.lessonsUrgent;
      case 'intermediate':
        return AppColors.lessonsPrivacyText;
      case 'advanced':
        return AppColors.lessonsError;
      default:
        return AppColors.lessonsGrey;
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'all';
      _selectedLevel = 'all';
    });
  }

  Future<void> _handleStartLesson(Map<String, dynamic> lessonSummary) async {
    final String? lessonId =
        (lessonSummary['lessonId'] ?? lessonSummary['id'])?.toString();
    if (lessonId == null || lessonId.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse(getlessonbyid + lessonId));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        if (decoded['status'] == true &&
            decoded['lesson'] is Map<String, dynamic>) {
          final Map<String, dynamic> l =
              decoded['lesson'] as Map<String, dynamic>;
          final String title =
              (l['title'] ?? lessonSummary['title'] ?? '').toString();
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
          if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _selectedLessonData = LessonData(
          lessonTitle: (lessonSummary['title'] ?? 'Lesson'),
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
      if (!mounted) return;
      setState(() {
        _selectedLessonData = LessonData(
          lessonTitle: (lessonSummary['title'] ?? 'Lesson'),
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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 60), // Account for admin button
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'Islamic Lessons',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lessonsTitle,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn and grow in your Islamic knowledge',
                      style: TextStyle(color: AppColors.lessonsSubtitle),
                    ),
                  ],
                ),
              ),

              // Search and Filters
              Card(
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFBFE3D5)),
                ),
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search lessons...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.lessonsSearchIcon,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lessonsCategoryBackground,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lessonsCategoryBackground,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lessonsHumanBadge,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      SizedBox(height: 16),

                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.filter_alt,
                                  color: AppColors.lessonsSearchIcon,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsCategoryBackground,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsCategoryBackground,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsHumanBadge,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              items:
                                  _categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category['id'],
                                      child: Text(
                                        category['name']!,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'all';
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField(
                              value: _selectedLevel,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.military_tech,
                                  color: AppColors.lessonsSearchIcon,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsCategoryBackground,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsCategoryBackground,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lessonsHumanBadge,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              items:
                                  _levels.map((level) {
                                    return DropdownMenuItem(
                                      value: level['id'],
                                      child: Text(
                                        level['name']!,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLevel = value ?? 'all';
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

              SizedBox(height: 20),

              // Results Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredLessons.length} lesson${filteredLessons.length != 1 ? 's' : ''} found',
                    style: TextStyle(color: AppColors.lessonsSubtitle),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Lessons List
              if (filteredLessons.isNotEmpty)
                ...filteredLessons
                    .map(
                      (lesson) => Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Card(
                          color: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Color(0xFFBFE3D5)),
                          ),
                          elevation: 8,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Lesson Icon
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.lessonsHumanBadge,
                                            AppColors.lessonsSubtitle,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          lesson['image'],
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),

                                    // Lesson Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  lesson['title'],
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.lessonsTitle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          Text(
                                            lesson['description'],
                                            style: TextStyle(
                                              color: AppColors.lessonsSubtitle,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 12),

                                          // Badges
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.lessonsBorder,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  lesson['category'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.lessonsUrgent,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getLevelColor(
                                                    lesson['level'],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  lesson['level'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getLevelTextColor(
                                                      lesson['level'],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Stats
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color:
                                                        AppColors
                                                            .lessonsSubtitle,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    lesson['duration'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors
                                                              .lessonsSubtitle,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Consumer<UserProvider>(
                                                builder: (
                                                  context,
                                                  userProvider,
                                                  _,
                                                ) {
                                                  final List p =
                                                      userProvider
                                                          .lessonsProgress;
                                                  final String lessonId =
                                                      (lesson['lessonId'] ??
                                                              lesson['id'])
                                                          .toString();
                                                  Map? entry;
                                                  for (final e in p) {
                                                    if (e is Map &&
                                                        (e['lessonId']
                                                                    ?.toString() ??
                                                                '') ==
                                                            lessonId) {
                                                      entry = e;
                                                      break;
                                                    }
                                                  }
                                                  final int cs =
                                                      int.tryParse(
                                                        (entry?['currentStep'] ??
                                                                0)
                                                            .toString(),
                                                      ) ??
                                                      0;
                                                  final bool done =
                                                      entry?['completed'] ==
                                                      true;
                                                  if (cs <= 0 && !done)
                                                    return SizedBox.shrink();
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        done
                                                            ? Icons.check_circle
                                                            : Icons
                                                                .play_circle_fill,
                                                        size: 16,
                                                        color:
                                                            done
                                                                ? AppColors
                                                                    .askPagePrivateIcon
                                                                : AppColors
                                                                    .lessonsSubtitle,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        done
                                                            ? 'Completed'
                                                            : 'Progress: Step ' +
                                                                cs.toString(),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              AppColors
                                                                  .lessonsSubtitle,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),

                                          ElevatedButton(
                                            onPressed:
                                                () =>
                                                    _handleStartLesson(lesson),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.lessonsHumanBadge,
                                              foregroundColor:
                                                  AppColors.islamicWhite,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  ((lesson['progress']?['currentStep'] ??
                                                                  0) >
                                                              0 &&
                                                          (lesson['progress']?['completed'] !=
                                                              true))
                                                      ? 'Continue Lesson'
                                                      : 'Start Lesson',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList()
              else
                // Empty State
                Card(
                  color: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.lessonsCategoryBackground,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: AppColors.lessonsPrivacyBorder,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No lessons found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lessonsTitle,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter criteria',
                          style: TextStyle(color: Color(0xFF206F4F)),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lessonsUrgent,
                            side: BorderSide(
                              color: AppColors.lessonsPrivacyBorder,
                            ),
                          ),
                          child: Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Lesson Player Modal
        if (_selectedLessonData != null)
          LessonPlayer(
            isOpen: _isLessonPlayerOpen,
            onClose: () {
              if (!mounted) return;
              setState(() {
                _isLessonPlayerOpen = false;
                _selectedLessonData = null;
              });
            },
            onCloseWithProgress: (currentStep, completed) async {
              try {
                // Determine lesson id
                final String? lessonId =
                    _lessons
                        .firstWhere(
                          (l) => l['title'] == _selectedLessonData?.lessonTitle,
                          orElse: () => {},
                        )['lessonId']
                        ?.toString();
                if (lessonId == null || lessonId.isEmpty) return;
                // Auth header
                // Token retrieval via AuthUtils is handled in provider functions usually, but here we call directly
                // Using SharedPreferences to read token
                // Keep UI snappy: update provider first, then fire request
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                userProvider.upsertLessonProgress(
                  lessonId: lessonId,
                  currentStep: currentStep,
                  completed: completed,
                );

                // Also reflect progress in the in-memory lessons list for instant UI consistency
                if (mounted) {
                  setState(() {
                    final int idx = _lessons.indexWhere(
                      (l) => (l['lessonId']?.toString() ?? '') == lessonId,
                    );
                    if (idx >= 0) {
                      final Map<String, dynamic> item =
                          Map<String, dynamic>.from(_lessons[idx]);
                      final Map<String, dynamic> progress =
                          Map<String, dynamic>.from(item['progress'] ?? {});
                      progress['currentStep'] = currentStep;
                      progress['completed'] = completed;
                      item['progress'] = progress;
                      _lessons[idx] = item;
                    }
                  });
                }

                final uri = Uri.parse(updateLessonProgress + lessonId);
                // Build auth header
                // We will fetch token via SharedPreferences to avoid circular deps
                // ignore: use_build_context_synchronously
                final token = await AuthUtils.getValidToken(context);
                if (token == null) return;
                await http.patch(
                  uri,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token,
                  },
                  body: json.encode({'currentStep': currentStep}),
                );
              } catch (_) {}
            },
            lessonData: _selectedLessonData!,
            initialStepIndex:
                (() {
                  final match = _lessons.firstWhere(
                    (l) => l['title'] == _selectedLessonData?.lessonTitle,
                    orElse: () => {},
                  );
                  final int cs =
                      int.tryParse(
                        (match['progress']?['currentStep'] ?? 0).toString(),
                      ) ??
                      0;
                  // currentStep is 1-based in persistence; convert to 0-based index
                  return cs > 0 ? cs - 1 : 0;
                })(),
          ),
      ],
    );
  }
}
