import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:frontend/utils/auth_utils.dart';

class Question {
  final String id;
  final String text;
  final String shortText;
  final User user;
  final DateTime createdAt;
  final bool isPublic;
  final bool isFlagged;
  final bool isAnswered;
  final String category;
  final String language;
  final int likes;
  final int shares;
  final int views;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.text,
    required this.shortText,
    required this.user,
    required this.createdAt,
    required this.isPublic,
    required this.isFlagged,
    required this.isAnswered,
    required this.category,
    required this.language,
    required this.likes,
    required this.shares,
    required this.views,
    required this.answers,
  });

  Question copyWith({
    String? id,
    String? text,
    String? shortText,
    User? user,
    DateTime? createdAt,
    bool? isPublic,
    bool? isFlagged,
    bool? isAnswered,
    String? category,
    String? language,
    int? likes,
    int? shares,
    int? views,
    List<Answer>? answers,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      shortText: shortText ?? this.shortText,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      isFlagged: isFlagged ?? this.isFlagged,
      isAnswered: isAnswered ?? this.isAnswered,
      category: category ?? this.category,
      language: language ?? this.language,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      answers: answers ?? this.answers,
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, text: $text, shortText: $shortText, user: $user, createdAt: $createdAt, isPublic: $isPublic, isFlagged: $isFlagged, isAnswered: $isAnswered, category: $category, language: $language, likes: $likes, shares: $shares, views: $views, answers: $answers)';
  }
}

class Answer {
  final String id;
  final String text;
  final String shortText;
  final Volunteer volunteer;
  final String questionText;
  final DateTime createdAt;
  final int upvotes;
  final String language;
  final bool isFlagged;
  final bool isHidden;
  final bool isTopAnswer;

  Answer({
    required this.id,
    required this.text,
    required this.shortText,
    required this.volunteer,
    required this.questionText,
    required this.createdAt,
    required this.upvotes,
    required this.language,
    required this.isFlagged,
    required this.isHidden,
    this.isTopAnswer = false,
  });

  Answer copyWith({
    String? id,
    String? text,
    String? shortText,
    Volunteer? volunteer,
    String? questionText,
    DateTime? createdAt,
    int? upvotes,
    String? language,
    bool? isFlagged,
    bool? isHidden,
    bool? isTopAnswer,
  }) {
    return Answer(
      id: id ?? this.id,
      text: text ?? this.text,
      shortText: shortText ?? this.shortText,
      volunteer: volunteer ?? this.volunteer,
      questionText: questionText ?? this.questionText,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      language: language ?? this.language,
      isFlagged: isFlagged ?? this.isFlagged,
      isHidden: isHidden ?? this.isHidden,
      isTopAnswer: isTopAnswer ?? this.isTopAnswer,
    );
  }

  @override
  String toString() {
    return 'Answer(id: $id, text: $text, shortText: $shortText, volunteer: $volunteer, questionText: $questionText, createdAt: $createdAt, upvotes: $upvotes, language: $language, isFlagged: $isFlagged, isHidden: $isHidden, isTopAnswer: $isTopAnswer)';
  }
}

class User {
  final String name;
  final String? avatar;

  User({required this.name, this.avatar});
  @override
  String toString() {
    return 'User(name: $name, avatar: $avatar)';
  }
}

class Volunteer {
  final String name;
  final double rating;

  Volunteer({required this.name, required this.rating});
  @override
  String toString() {
    return 'Volunteer(name: $name, rating: $rating)';
  }
}

class AdminQuestions extends StatefulWidget {
  const AdminQuestions({Key? key}) : super(key: key);

  @override
  State<AdminQuestions> createState() => _AdminQuestionsState();
}

class _AdminQuestionsState extends State<AdminQuestions>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedVisibility = 'All';
  String _selectedLanguage = 'All';
  Question? _selectedQuestion;
  Answer? _selectedAnswer;

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

  // Mock data
  List<Question> _questions = [
    Question(
      id: '1',
      text:
          "I'm new to Islam and want to understand the five daily prayers. Can someone explain when exactly I should pray each prayer and what are the key steps I need to follow? I've read about Fajr, Dhuhr, Asr, Maghrib, and Isha but I'm confused about the timing.",
      shortText: 'How to perform the five daily prayers correctly?',
      user: User(name: 'Sarah Johnson'),
      createdAt: DateTime.parse('2024-06-20T10:30:00Z'),
      isPublic: true,
      isFlagged: false,
      isAnswered: true,
      category: 'Prayer',
      language: 'English',
      likes: 24,
      shares: 8,
      views: 156,
      answers: [
        Answer(
          id: 'a1',
          text:
              'The five daily prayers are fundamental to Islamic practice. Fajr is before sunrise, Dhuhr at midday, Asr in the afternoon, Maghrib at sunset, and Isha at night. Each prayer has specific steps including ablution (wudu), facing Qibla, and following the prescribed movements and recitations.',
          shortText: 'Complete guide to the five daily prayers...',
          volunteer: Volunteer(name: 'Ahmad Hassan', rating: 4.8),
          questionText: 'How to perform the five daily prayers correctly?',
          createdAt: DateTime.parse('2024-06-20T11:00:00Z'),
          upvotes: 18,
          language: 'English',
          isFlagged: false,
          isHidden: false,
          isTopAnswer: true,
        ),
      ],
    ),
    Question(
      id: '2',
      text:
          'What is the correct way to perform wudu (ablution)? I want to make sure I\'m doing it correctly.',
      shortText: 'What is the correct way to perform wudu?',
      user: User(name: 'Muhammad Ali'),
      createdAt: DateTime.parse('2024-06-19T15:45:00Z'),
      isPublic: true,
      isFlagged: false,
      isAnswered: true,
      category: 'Purification',
      language: 'English',
      likes: 31,
      shares: 12,
      views: 203,
      answers: [
        Answer(
          id: 'a2',
          text:
              'Wudu involves washing specific parts of the body in order: hands, mouth, nose, face, arms, head, and feet. Start with the intention (niyyah) and say Bismillah.',
          shortText: 'Step-by-step wudu procedure...',
          volunteer: Volunteer(name: 'Fatima Al-Zahra', rating: 4.6),
          questionText: 'What is the correct way to perform wudu?',
          createdAt: DateTime.parse('2024-06-19T16:15:00Z'),
          upvotes: 25,
          language: 'English',
          isFlagged: false,
          isHidden: false,
          isTopAnswer: true,
        ),
      ],
    ),
    Question(
      id: '3',
      text:
          'Someone told me that music is haram in Islam. Is this true? What about nasheed?',
      shortText: 'Is music haram in Islam?',
      user: User(name: 'Omar Khan'),
      createdAt: DateTime.parse('2024-06-18T20:15:00Z'),
      isPublic: false,
      isFlagged: true,
      isAnswered: false,
      category: 'Lifestyle',
      language: 'English',
      likes: 5,
      shares: 1,
      views: 67,
      answers: [],
    ),
    Question(
      id: '4',
      text: 'When is it permissible to break the fast during Ramadan?',
      shortText: 'When can you break fast during Ramadan?',
      user: User(name: 'Aisha Mohamed'),
      createdAt: DateTime.parse('2024-06-17T09:20:00Z'),
      isPublic: true,
      isFlagged: false,
      isAnswered: true,
      category: 'Fasting',
      language: 'English',
      likes: 19,
      shares: 6,
      views: 134,
      answers: [
        Answer(
          id: 'a3',
          text:
              'There are specific circumstances when breaking the fast is permissible or required, such as illness, travel, pregnancy, or if continuing would cause harm.',
          shortText: 'Permissible circumstances for breaking fast...',
          volunteer: Volunteer(name: 'Imam Abdullah', rating: 4.9),
          questionText: 'When can you break fast during Ramadan?',
          createdAt: DateTime.parse('2024-06-17T10:00:00Z'),
          upvotes: 22,
          language: 'English',
          isFlagged: false,
          isHidden: false,
          isTopAnswer: true,
        ),
      ],
    ),
    Question(
      id: '5',
      text:
          'This is a very long question text that should demonstrate the ellipsis functionality when the text exceeds the available space in the container. It contains multiple sentences and should be properly truncated with ellipsis to maintain a clean and consistent layout across all screen sizes.',
      shortText:
          'This is a very long question text that should demonstrate the ellipsis functionality when the text exceeds the available space in the container. It contains multiple sentences and should be properly truncated with ellipsis to maintain a clean and consistent layout across all screen sizes.',
      user: User(name: 'Test User with Long Name'),
      createdAt: DateTime.parse('2024-06-16T14:30:00Z'),
      isPublic: true,
      isFlagged: false,
      isAnswered: true,
      category: 'Islamic Law',
      language: 'English',
      likes: 45,
      shares: 15,
      views: 289,
      answers: [
        Answer(
          id: 'a4',
          text:
              'This is a very long answer text that should also demonstrate the ellipsis functionality. It contains detailed information about Islamic law and various interpretations from different scholars. The text should be properly truncated to maintain the layout consistency.',
          shortText:
              'This is a very long answer text that should also demonstrate the ellipsis functionality. It contains detailed information about Islamic law and various interpretations from different scholars. The text should be properly truncated to maintain the layout consistency.',
          volunteer: Volunteer(
            name: 'Scholar with Very Long Name',
            rating: 4.9,
          ),
          questionText:
              'This is a very long question text that should demonstrate the ellipsis functionality when the text exceeds the available space in the container.',
          createdAt: DateTime.parse('2024-06-16T15:00:00Z'),
          upvotes: 35,
          language: 'English',
          isFlagged: false,
          isHidden: false,
          isTopAnswer: true,
        ),
      ],
    ),
  ];

  List<Answer> _answers = [
    Answer(
      id: 'ans1',
      text:
          'The five daily prayers are fundamental to Islamic practice. Fajr is before sunrise, Dhuhr at midday, Asr in the afternoon, Maghrib at sunset, and Isha at night. Each prayer has specific steps including ablution (wudu), facing Qibla, and following the prescribed movements and recitations.',
      shortText: 'Complete guide to the five daily prayers...',
      volunteer: Volunteer(name: 'Ahmad Hassan', rating: 4.8),
      questionText: 'How to perform the five daily prayers correctly?',
      createdAt: DateTime.parse('2024-06-20T11:00:00Z'),
      upvotes: 18,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans2',
      text:
          'Wudu involves washing specific parts of the body in order: hands, mouth, nose, face, arms, head, and feet. Start with the intention (niyyah) and say Bismillah.',
      shortText: 'Step-by-step wudu procedure...',
      volunteer: Volunteer(name: 'Fatima Al-Zahra', rating: 4.6),
      questionText: 'What is the correct way to perform wudu?',
      createdAt: DateTime.parse('2024-06-19T16:15:00Z'),
      upvotes: 25,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans3',
      text:
          'Music in Islam is a complex topic with different scholarly opinions. Generally, vocals without instruments (nasheed) are more widely accepted.',
      shortText: 'Islamic perspective on music and nasheed...',
      volunteer: Volunteer(name: 'Muhammad Khan', rating: 4.7),
      questionText: 'Is music haram in Islam?',
      createdAt: DateTime.parse('2024-06-18T21:00:00Z'),
      upvotes: 8,
      language: 'English',
      isFlagged: true,
      isHidden: false,
    ),
    Answer(
      id: 'ans4',
      text:
          'There are specific circumstances when breaking the fast is permissible or required, such as illness, travel, pregnancy, or if continuing would cause harm.',
      shortText: 'Permissible circumstances for breaking fast...',
      volunteer: Volunteer(name: 'Imam Abdullah', rating: 4.9),
      questionText: 'When can you break fast during Ramadan?',
      createdAt: DateTime.parse('2024-06-17T10:00:00Z'),
      upvotes: 22,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans5',
      text:
          'This is a very long answer text that should also demonstrate the ellipsis functionality. It contains detailed information about Islamic law and various interpretations from different scholars.',
      shortText:
          'This is a very long answer text that should also demonstrate the ellipsis functionality. It contains detailed information about Islamic law and various interpretations from different scholars.',
      volunteer: Volunteer(name: 'Scholar with Very Long Name', rating: 4.9),
      questionText:
          'This is a very long question text that should demonstrate the ellipsis functionality when the text exceeds the available space in the container.',
      createdAt: DateTime.parse('2024-06-16T15:00:00Z'),
      upvotes: 35,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans6',
      text:
          'The Quran emphasizes the importance of seeking knowledge and education. Prophet Muhammad (PBUH) said "Seeking knowledge is obligatory for every Muslim."',
      shortText: 'Islamic perspective on education and knowledge...',
      volunteer: Volunteer(name: 'Dr. Aisha Rahman', rating: 4.7),
      questionText: 'What does Islam say about education?',
      createdAt: DateTime.parse('2024-06-15T14:30:00Z'),
      upvotes: 31,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans7',
      text:
          'Charity (Zakat) is one of the five pillars of Islam. It is obligatory for Muslims who meet certain wealth criteria to give 2.5% of their wealth annually.',
      shortText: 'Understanding Zakat and charitable giving...',
      volunteer: Volunteer(name: 'Umar Farooq', rating: 4.5),
      questionText: 'How much should I give in charity?',
      createdAt: DateTime.parse('2024-06-14T09:15:00Z'),
      upvotes: 19,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
    Answer(
      id: 'ans8',
      text:
          'Hijab is a form of modesty in Islam. It includes both physical covering and modest behavior. The requirements vary among different Islamic schools of thought.',
      shortText: 'Understanding hijab and Islamic modesty...',
      volunteer: Volunteer(name: 'Zainab Ahmed', rating: 4.8),
      questionText: 'What are the requirements for hijab?',
      createdAt: DateTime.parse('2024-06-13T16:45:00Z'),
      upvotes: 28,
      language: 'English',
      isFlagged: false,
      isHidden: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getQuestions()
        .then((questions) {
          setState(() {
            _questions = questions;
          });
        })
        .catchError((e) {
          // handle error if needed
          print('Error loading questions: $e');
        });
    getAnswers()
        .then((answers) {
          setState(() {
            _answers = answers;
          });
        })
        .catchError((e) {
          // handle error if needed
          print('Error loading questions: $e');
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //get all questions from the database and  fill the gathered questions from the database to the _questions list
  //get all answers from the database and fill the gathered answers from the database to the _answers list
  Future<List<Question>> getQuestions() async {
    //get all questions from the database
    final url = Uri.parse(adminAllQuestionsUrl);
    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception('Failed to load questions');
    }
    if (data is! List) {
      throw Exception('Unexpected API response structure');
    }
    final List<Question> _questionslist = [];

    for (var q in data) {
      final List<Answer> answers = [];

      for (var a in q['answers'] ?? []) {
        answers.add(
          Answer(
            id: a['id'],
            text: a['text'],
            shortText: a['shortText'],
            questionText: a['questionText'],
            createdAt: DateTime.parse(a['createdAt']),
            upvotes: a['upvotes'],
            language: a['language'],
            isFlagged: a['isFlagged'],
            isHidden: a['isHidden'],
            isTopAnswer: a['isTopAnswer'],
            volunteer: Volunteer(
              name: a['volunteer']['name'],
              rating: (a['volunteer']['rating'] ?? 0).toDouble(),
            ),
          ),
        );
      }

      _questionslist.add(
        Question(
          id: q['id'],
          text: q['text'],
          shortText: q['shortText'],
          user: User(name: q['user']['name'], avatar: q['user']['avatar']),
          createdAt: DateTime.parse(q['createdAt']),
          isPublic: q['isPublic'],
          isFlagged: q['isFlagged'],
          isAnswered: q['isAnswered'],
          category: q['category'],
          language: q['language'],
          likes: q['likes'],
          shares: q['shares'],
          views: q['views'],
          answers: answers,
        ),
      );
    }

    return _questionslist;
  }

  Future<List<Answer>> getAnswers() async {
    //get all answers from the database
    final url = Uri.parse(adminAllAnswersUrl);
    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions');
    }
    if (data is! List) {
      throw Exception('Unexpected API response structure');
    }
    final List<Answer> _answerslist = [];
    for (var a in data) {
      _answerslist.add(
        Answer(
          id: a['id'],
          text: a['text'],
          shortText: a['shortText'],
          questionText: a['questionText'],
          createdAt: DateTime.parse(a['createdAt']),
          upvotes: a['upvotes'],
          language: a['language'],
          isFlagged: a['isFlagged'],
          isHidden: a['isHidden'],
          isTopAnswer: a['isTopAnswer'],
          volunteer: Volunteer(
            name: a['volunteer']['name'],
            rating: (a['volunteer']['rating'] ?? 0).toDouble(),
          ),
        ),
      );
    }

    return _answerslist;
  }

  List<Question> get _filteredQuestions {
    return _questions.where((question) {
      final matchesSearch =
          question.shortText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          question.user.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || question.category == _selectedCategory;
      final matchesVisibility =
          _selectedVisibility == 'All' ||
          (_selectedVisibility == 'Public' && question.isPublic) ||
          (_selectedVisibility == 'Private' && !question.isPublic);
      final matchesLanguage =
          _selectedLanguage == 'All' || question.language == _selectedLanguage;
      return matchesSearch &&
          matchesCategory &&
          matchesVisibility &&
          matchesLanguage;
    }).toList();
  }

  List<Answer> get _filteredAnswers {
    return _answers.where((answer) {
      final matchesSearch =
          answer.shortText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          answer.volunteer.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          answer.questionText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesVisibility =
          _selectedVisibility == 'All' ||
          (_selectedVisibility == 'Public' && !answer.isHidden) ||
          (_selectedVisibility == 'Private' && answer.isHidden);
      final matchesLanguage =
          _selectedLanguage == 'All' || answer.language == _selectedLanguage;
      return matchesSearch && matchesVisibility && matchesLanguage;
    }).toList();
  }

  List<dynamic> get _flaggedContent {
    final flaggedQuestions =
        _questions
            .where((q) => q.isFlagged)
            .map((q) => {'type': 'question', 'data': q})
            .toList();
    final flaggedAnswers =
        _answers
            .where((a) => a.isFlagged)
            .map((a) => {'type': 'answer', 'data': a})
            .toList();
    return [...flaggedQuestions, ...flaggedAnswers];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions & Answers',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: islamicGreen800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage questions, answers, and moderate content',
                          style: TextStyle(
                            fontSize: 16,
                            color: islamicGreen600,
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
                      _buildTabButton('All Questions', 0),
                      _buildTabButton('Answers', 1),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsCards(isMobile),
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
                                  ? 'All Questions'
                                  : _tabController.index == 1
                                  ? 'All Answers'
                                  : 'Flagged Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: islamicGreen800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search and Filters
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: _buildSearchAndFilters(isMobile),
                      ),

                      // Table Content
                      Expanded(child: _buildCurrentTabContent(isMobile)),
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

  Widget _buildTabButton(String text, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? islamicGreen600 : Colors.transparent,
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

  Widget _buildStatsCards(bool isMobile) {
    final stats = [
      {
        'title': 'Total Questions',
        'value': _questions.length.toString(),
        'icon': Icons.chat_bubble_outline,
        'color': islamicGreen600,
      },
      {
        'title': 'Answered',
        'value': _questions.where((q) => q.isAnswered).length.toString(),
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      },
      {
        'title': 'Total Answers',
        'value': _answers.length.toString(),
        'icon': Icons.access_time,
        'color': Colors.orange,
      },
      {
        'title': 'Flagged Content',
        'value': _flaggedContent.length.toString(),
        'icon': Icons.flag_outlined,
        'color': Colors.red,
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

  Widget _buildSearchAndFilters(bool isMobile) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search questions or users...',
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
        // Filters
        _buildCategoryFilter(),
        const SizedBox(width: 8),
        _buildVisibilityFilter(),
      ],
    );
  }

  Widget _buildFilterButton(String text, IconData icon) {
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

  Widget _buildCategoryFilter() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      itemBuilder:
          (BuildContext context) =>
              [
                'All',
                'Islamic Law',
                'Quran',
                'Hadith',
                'Islamic History',
                'Islamic Ethics',
                'Islamic Finance',
                'Islamic Education',
                'Family & Marriage',
                'Health & Wellness',
                'Technology & Modern Life',
                'Other',
              ].map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      if (_selectedCategory == category)
                        Icon(Icons.check, size: 16, color: islamicGreen600),
                      if (_selectedCategory != category)
                        const SizedBox(width: 16),
                      Text(category),
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
            Icon(Icons.category, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              _selectedCategory == 'All' ? 'All Category' : _selectedCategory,
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

  Widget _buildVisibilityFilter() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedVisibility = value;
        });
      },
      itemBuilder:
          (BuildContext context) =>
              ['All', 'Public', 'Private'].map((String visibility) {
                return PopupMenuItem<String>(
                  value: visibility,
                  child: Row(
                    children: [
                      if (_selectedVisibility == visibility)
                        Icon(Icons.check, size: 16, color: islamicGreen600),
                      if (_selectedVisibility != visibility)
                        const SizedBox(width: 16),
                      Text(visibility),
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
            Icon(Icons.visibility, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              _selectedVisibility == 'All'
                  ? 'All Visibility'
                  : _selectedVisibility,
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

  Widget _buildCurrentTabContent(bool isMobile) {
    return Column(
      children: [
        // Results info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Showing 1 to ${_getCurrentData().length} of ${_getCurrentData().length} results',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child:
              _tabController.index == 1
                  ? _buildAnswersTableHeader()
                  : _buildTableHeader(),
        ),

        // Table Content
        Expanded(
          child: ListView.builder(
            itemCount: _getCurrentData().length,
            itemBuilder: (context, index) {
              if (_tabController.index == 0) {
                return _buildQuestionRow(_filteredQuestions[index], index);
              } else if (_tabController.index == 1) {
                return _buildAnswerRow(_filteredAnswers[index], index);
              } else {
                final item = _flaggedContent[index];
                if (item['type'] == 'question') {
                  return _buildQuestionRow(
                    item['data'],
                    index,
                    showFlaggedBadge: true,
                  );
                } else {
                  return _buildAnswerRow(
                    item['data'],
                    index,
                    showFlaggedBadge: true,
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  List<dynamic> _getCurrentData() {
    if (_tabController.index == 0) return _filteredQuestions;
    if (_tabController.index == 1) return _filteredAnswers;
    return _flaggedContent;
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildHeaderCell('Question')),
        Expanded(flex: 2, child: _buildHeaderCell('User')),
        Expanded(flex: 1, child: _buildHeaderCell('Category')),
        Expanded(flex: 1, child: _buildHeaderCell('Status')),
        Expanded(flex: 2, child: _buildHeaderCell('Engagement')),
        Expanded(flex: 1, child: _buildHeaderCell('Created')),
        const SizedBox(width: 40), // Actions column
      ],
    );
  }

  Widget _buildAnswersTableHeader() {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildHeaderCell('Answer')),
        Expanded(flex: 2, child: _buildHeaderCell('Volunteer')),
        Expanded(flex: 1, child: _buildHeaderCell('Upvotes')),
        Expanded(flex: 1, child: _buildHeaderCell('Status')),
        Expanded(flex: 1, child: _buildHeaderCell('Created')),
        const SizedBox(width: 40), // Actions column
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

  Widget _buildQuestionRow(
    Question question,
    int index, {
    bool showFlaggedBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: InkWell(
        onTap: () => _showQuestionDetails(question),
        child: Row(
          children: [
            // Question Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.shortText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        question.isPublic ? 'Public' : 'Private',
                        question.isPublic ? islamicGreen600 : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        question.language,
                        Colors.purple,
                        outlined: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // User Column
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: islamicGreen100,
                    child: Text(
                      // For Question Row
                      question.user.name
                          .split(' ')
                          .where((n) => n.isNotEmpty)
                          .take(2)
                          .map((n) => n[0])
                          .join('')
                          .toUpperCase(),
                      style: TextStyle(
                        color: islamicGreen600,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.user.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Category Column
            Expanded(
              flex: 1,
              child: _buildBadge(
                question.category,
                Colors.blue,
                outlined: true,
              ),
            ),

            const SizedBox(width: 16),

            // Status Column
            Expanded(flex: 1, child: _buildStatusBadge(question)),

            const SizedBox(width: 16),

            // Engagement Column
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _buildEngagementStat(Icons.bookmark, question.likes),
                  const SizedBox(width: 12),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Created Column
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(question.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),

            const SizedBox(width: 16),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleQuestionAction(value, question),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Question'),
                    ),
                    const PopupMenuItem(
                      value: 'flag',
                      child: Text('Flag/Unflag'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
              child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerRow(
    Answer answer,
    int index, {
    bool showFlaggedBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: InkWell(
        onTap: () => _showAnswerDetails(answer),
        child: Row(
          children: [
            // Answer Column
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer.shortText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Re: ${answer.questionText}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Volunteer Column
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          answer.volunteer.name
                              .split(' ')
                              .where((n) => n.isNotEmpty)
                              .take(2)
                              .map((n) => n[0])
                              .join('')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          answer.volunteer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Upvotes Column
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${answer.upvotes}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Status Column
            Expanded(flex: 1, child: _buildAnswerStatusBadge(answer)),

            const SizedBox(width: 16),

            // Created Column
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(answer.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),

            const SizedBox(width: 16),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAnswerAction(value, answer),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Full Answer'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Answer'),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Text('Hide Answer'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
              child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Question question) {
    if (question.isFlagged) {
      return _buildBadge('Flagged', Colors.red);
    } else if (question.isAnswered) {
      return _buildBadge('Answered', Colors.green);
    } else {
      return _buildBadge('Pending', Colors.orange);
    }
  }

  Widget _buildAnswerStatusBadge(Answer answer) {
    if (answer.isFlagged) {
      return _buildBadge('Flagged', Colors.red);
    } else if (answer.isHidden) {
      return _buildBadge('Hidden', Colors.orange);
    } else {
      return _buildBadge('Active', Colors.green);
    }
  }

  Widget _buildQuestionCard(
    Question question,
    bool isMobile, {
    bool showFlaggedBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => _showQuestionDetails(question),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: islamicGreen50.withOpacity(0.1),
                    child: Text(
                      // For Question Row
                      question.user.name
                          .split(' ')
                          .where((n) => n.isNotEmpty)
                          .take(2)
                          .map((n) => n[0])
                          .join('')
                          .toUpperCase(),
                      style: TextStyle(
                        color: islamicGreen500,
                        fontSize: 12,
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
                          question.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(question.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected:
                        (value) => _handleQuestionAction(value, question),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Details'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Question'),
                          ),
                          const PopupMenuItem(
                            value: 'flag',
                            child: Text('Flag/Unflag'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Question Text
              Text(
                question.shortText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 8),
              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (showFlaggedBadge) _buildBadge('Flagged', Colors.red),
                  _buildBadge(
                    question.isAnswered ? 'Answered' : 'Pending',
                    question.isAnswered ? Colors.green : Colors.orange,
                  ),
                  _buildBadge(
                    question.isPublic ? 'Public' : 'Private',
                    question.isPublic ? islamicGreen500 : Colors.grey,
                  ),
                  _buildBadge(question.category, Colors.blue, outlined: true),
                  _buildBadge(question.language, Colors.purple, outlined: true),
                ],
              ),
              const SizedBox(height: 12),
              // Engagement Stats
              Row(
                children: [
                  _buildEngagementStat(Icons.favorite_outline, question.likes),
                  const SizedBox(width: 16),
                  _buildEngagementStat(Icons.share_outlined, question.shares),
                  const SizedBox(width: 16),
                  _buildEngagementStat(
                    Icons.visibility_outlined,
                    question.views,
                  ),
                  const Spacer(),
                  if (question.answers.isNotEmpty)
                    Text(
                      '${question.answers.length} answers',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(
    Answer answer,
    bool isMobile, {
    bool showFlaggedBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => _showAnswerDetails(answer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: Text(
                      answer.volunteer.name
                          .split(' ')
                          .where((n) => n.isNotEmpty)
                          .take(2)
                          .map((n) => n[0])
                          .join('')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
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
                          answer.volunteer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${answer.volunteer.rating}/5',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAnswerAction(value, answer),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Full Answer'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Answer'),
                          ),
                          const PopupMenuItem(
                            value: 'hide',
                            child: Text('Hide Answer'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Question Reference
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Re: ${answer.questionText}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 8),
              // Answer Text
              Text(
                answer.shortText,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 8),
              // Badges and Stats
              Row(
                children: [
                  if (showFlaggedBadge) _buildBadge('Flagged', Colors.red),
                  if (answer.isTopAnswer)
                    _buildBadge('Top Answer', Colors.green),
                  _buildBadge(answer.language, Colors.purple, outlined: true),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${answer.upvotes}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        border: outlined ? Border.all(color: const Color(0xFFD1D5DB)) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: outlined ? const Color(0xFF6B7280) : color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _deleteQuestion(String id) async {
    print('🍓🫕🍫 Deleting question with ID: $id');
    final url = Uri.parse('$deleteQuestionUrl$id');

    final token = await AuthUtils.getValidToken(context);
    print('🍓🫕🍫 Using token: $token');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('🍓🫕🍫 ${response.body}');

      if (response.statusCode == 200) {
        _showSnackbar('Question deleted successfully');
        // refresh UI
        setState(() {
          _questions.removeWhere((q) => q.id == id);
        });
      } else {
        _showSnackbar('Failed to delete question');
      }
    } catch (e) {
      _showSnackbar('Error deleting question');
    }
  }

  Future<void> _FlagByAdmin(String id, bool isFlagged) async {
    final url = Uri.parse('$flagQuestionUrl$id');
    print('Flagging question with ID: $id');
    print('Is flagged: $isFlagged');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isFlagged': !isFlagged}),
      );
      print('Response status: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          final index = _questions.indexWhere((q) => q.id == id);
          if (index != -1) {
            _questions[index] = _questions[index].copyWith(
              isFlagged: !isFlagged,
            );
          }
        });
        _showSnackbar('Flag status updated successfully');
      } else {
        _showSnackbar('Failed to update flag status');
      }
    } catch (e) {
      _showSnackbar('Error updating flag status');
    }
  }

  void _handleQuestionAction(String action, Question question) {
    switch (action) {
      case 'view':
        _showQuestionDetails(question);
        break;
      case 'edit':
        _showEditQuestionDialog(question);
        break;
      case 'flag':
        _FlagByAdmin(question.id, question.isFlagged);
        _showSnackbar(
          'Question ${question.isFlagged ? "unflagged" : "flagged"}',
        );
        break;
      case 'delete':
        _showDeleteConfirmation('question', () {
          _deleteQuestion(question.id);
        });
        break;
    }
  }

  void _handleAnswerAction(String action, Answer answer) {
    switch (action) {
      case 'view':
        _showAnswerDetails(answer);
        break;
      case 'edit':
        _showEditAnswerDialog(answer);
        break;
      case 'hide':
        _hideAnswer(answer.id, answer.isHidden);
        _showSnackbar('Answer hidden from public view');
        break;
      case 'delete':
        _showDeleteConfirmation('answer', () {
          _deleteAnswer(answer.id);
        });
        break;
    }
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 600,
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
                            'Question Details',
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
                          // User info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: islamicGreen100,
                                child: Text(
                                  question.user.name
                                      .split(' ')
                                      .where((n) => n.isNotEmpty)
                                      .take(2)
                                      .map((n) => n[0])
                                      .join('')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: islamicGreen600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(question.createdAt),
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Question text
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Answers
                          if (question.answers.isNotEmpty) ...[
                            Text(
                              'Answers (${question.answers.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: islamicGreen800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...question.answers.map(
                              (answer) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.green
                                              .withOpacity(0.1),
                                          child: Text(
                                            answer.volunteer.name
                                                .split(' ')
                                                .where((n) => n.isNotEmpty)
                                                .take(2)
                                                .map((n) => n[0])
                                                .join('')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                answer.volunteer.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${answer.volunteer.rating}/5',
                                                    style: const TextStyle(
                                                      color: Color(0xFF6B7280),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (answer.isTopAnswer)
                                          _buildBadge(
                                            'Top Answer',
                                            Colors.green,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(answer.text),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${answer.upvotes} upvotes • ${_formatDate(answer.createdAt)}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditQuestionDialog(question);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: islamicGreen600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Edit Question'),
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

  void _showAnswerDetails(Answer answer) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
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
                            'Answer Details',
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
                          // Volunteer info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Text(
                                  answer.volunteer.name
                                      .split(' ')
                                      .where((n) => n.isNotEmpty)
                                      .take(2)
                                      .map((n) => n[0])
                                      .join('')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    answer.volunteer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Question reference
                          const Text(
                            'Question:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              answer.questionText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Answer text
                          const Text(
                            'Answer:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              answer.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Posted on ${_formatDate(answer.createdAt)} • Language: ${answer.language}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
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
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // Update the question details
                            Navigator.pop(context);
                            await Future.delayed(Duration(milliseconds: 100));
                            _showEditAnswerDialog(answer);
                            //  _showSnackbar('Question updated successfully');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: islamicGreen600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Edit Answer'),
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

  Future<void> _updateQuestionByAdmin(
    String questionId,
    String text,
    String category,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    // Update the question in the database
    // This is a placeholder for actual update logic
    print('Updating question $questionId');
    print('New text: $text');
    print('New category: $category');

    // Simulate a successful update
    try {
      final response = await http.put(
        Uri.parse('$adminUpdateQuestionUrl/$questionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'category': category}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final index = _questions.indexWhere((q) => q.id == questionId);
        print('🔍 Found question at index: $index');
        if (index != -1) {
          print('📝 Before update: ${_questions[index].text}');
          setState(() {
            _questions[index] = _questions[index].copyWith(
              text: text,
              shortText:
                  text.length > 100 ? text.substring(0, 100) + '...' : text,
              category: category,
            );
          });
          print('✅ After update: ${_questions[index].text}');
        } else {
          print('❌ Question not found in _questions list');
        }
        _showSnackbar('Question updated successfully');
      } else {
        print('❌ Failed to update question: ${response.body}');
        _showSnackbar('Failed to update question');
      }
    } catch (e) {
      print('🔥 Error: $e');
      _showSnackbar('An error occurred while updating the question');
    }
  }

  void _showEditQuestionDialog(Question question) {
    final textController = TextEditingController(text: question.text);
    String selectedCategory = question.category;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                            'Edit Question',
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          onChanged: (value) => selectedCategory = value!,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items:
                              [
                                    'Worship',
                                    'Prayer',
                                    'Fasting',
                                    'Hajj & Umrah',
                                    'Islamic Finance',
                                    'Family & Marriage',
                                    'Daily Life',
                                    'Quran & Sunnah',
                                    'Islamic History',
                                    'Etiquette',
                                    'Other',
                                  ]
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Question Text',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: textController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'Enter question text...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // Update the question details
                            await _updateQuestionByAdmin(
                              question.id,
                              textController.text,
                              selectedCategory,
                            );
                            Navigator.pop(context);
                            //  _showSnackbar('Question updated successfully');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: islamicGreen600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Changes'),
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

  void _showDeleteConfirmation(String type, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete $type'),
            content: Text(
              'Are you sure you want to delete this $type? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
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
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateAnswerByAdmin(String answerId, String updatedText) async {
    try {
      final response = await http.put(
        Uri.parse('$adminUpdateAnswerUrl/$answerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': updatedText}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final index = _questions.indexWhere(
          (q) => q.answers.any((a) => a.id == answerId),
        );
        if (index == -1) {
          _showSnackbar('Question not found');
          return;
        }

        final question = _questions[index];

        final updatedAnswers =
            question.answers.map((a) {
              if (a.id == answerId) {
                // Only reset upvotes if the text has changed
                if (a.text != updatedText) {
                  return a.copyWith(
                    text: updatedText,
                    shortText: updatedText,
                    upvotes: 0,
                  );
                }
                return a.copyWith(text: updatedText, shortText: updatedText);
              }
              return a;
            }).toList();

        final updatedQuestion = question.copyWith(answers: updatedAnswers);

        setState(() {
          _questions = List<Question>.from(_questions);
          _questions[index] = updatedQuestion;
          final answerIndex = _answers.indexWhere((a) => a.id == answerId);
          if (answerIndex != -1) {
            if (_answers[answerIndex].text != updatedText) {
              _answers[answerIndex] = _answers[answerIndex].copyWith(
                text: updatedText,
                shortText: updatedText,
                upvotes: 0,
              );
            } else {
              _answers[answerIndex] = _answers[answerIndex].copyWith(
                text: updatedText,
                shortText: updatedText,
              );
            }
          }
        });

        _showSnackbar('Answer updated successfully');
        print('🔄 UI updated successfully.');
      } else {
        _showSnackbar('Failed to update answer');
      }
    } catch (e, stack) {
      print('❌ Error updating answer: $e');
      print(stack);
      _showSnackbar('Error updating answer');
    }
  }

  void _showEditAnswerDialog(Answer answer) {
    final TextEditingController _controller = TextEditingController(
      text: answer.text,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Answer'),
            content: SizedBox(
              width: 500,
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Edit your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedText = _controller.text.trim();
                  if (updatedText.isEmpty) {
                    _showSnackbar('Answer cannot be empty');
                    return;
                  }

                  await _updateAnswerByAdmin(answer.id, updatedText);

                  Navigator.pop(context);

                  _showSnackbar('Answer updated successfully');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: islamicGreen600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAnswer(String answerId) async {
    // Implement the logic to delete the answer
    // This is a placeholder for actual delete logic
    print('Deleting answer with ID: $answerId');
    try {
      final response = await http.delete(Uri.parse('$deleteAns$answerId'));
      // You may want to handle the response and update the UI here
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _answers.removeWhere((a) => a.id == answerId);
          for (var question in _questions) {
            question.answers.removeWhere((a) => a.id == answerId);
          }
        });
        _showSnackbar('Answer deleted successfully');
      } else {
        _showSnackbar('Failed to delete answer');
      }
    } catch (e) {
      print('❌ Error deleting answer: $e');
      _showSnackbar('Error deleting answer');
    }
  }

  Future<void> _hideAnswer(String answerId, bool isHidden) async {
    //Hide or unhide an answer
    // Implement the logic to hide the answer
    // This is a placeholder for actual hide logic
    print('Hiding answer with ID: $answerId');
    try {
      final response = await http.put(
        Uri.parse('$adminHideAnswerUrl/$answerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isHidden': !isHidden}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          //update the UI to reflect the hidden answer (isHidden=true)
          final answerIndex = _answers.indexWhere((a) => a.id == answerId);
          if (answerIndex != -1) {
            _answers[answerIndex] = _answers[answerIndex].copyWith(
              isHidden: !isHidden,
            );
          }
          for (var question in _questions) {
            final qAnswerIndex = question.answers.indexWhere(
              (a) => a.id == answerId,
            );
            if (qAnswerIndex != -1) {
              question.answers[qAnswerIndex] = question.answers[qAnswerIndex]
                  .copyWith(isHidden: !isHidden);
            }
          }
        });
        // Show a snackbar or some feedback to the user
        _showSnackbar(
          'Answer ${!isHidden ? 'hidden' : 'unhidden'} successfully',
        );
      } else {
        _showSnackbar('Failed to hide answer');
      }
    } catch (e) {
      print('❌ Error hiding answer: $e');
      _showSnackbar('Error hiding answer');
    }
  }
}
