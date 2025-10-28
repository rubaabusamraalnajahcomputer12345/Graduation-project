// lib/pages/ask_page.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import 'QuestionCard.dart';
import 'AIResponseCard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:async'; // Added for Completer
import 'package:provider/provider.dart';
import '../providers/UserProvider.dart';
import '../utils/auth_utils.dart';
import 'MyAnswerCard.dart';

import '../providers/NavigationProvider.dart';

class Questions extends StatefulWidget {
  final int initialTabIndex;
  Questions({this.initialTabIndex = 0});

  @override
  _QuestionsState createState() => _QuestionsState();
}

class _QuestionsState extends State<Questions> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _searchController = TextEditingController();
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;
  late AnimationController _failAnimationController;
  late Animation<double> _failAnimation;
  late TabController _tabController;

  final ScrollController _favoritesScrollController = ScrollController();
  final ScrollController _recentQuestionsScrollController = ScrollController();
  final ScrollController _communityQuestionsScrollController =
      ScrollController();
  late VoidCallback _navListener;
  NavigationProvider? _navProvider;

  String _selectedCategory = '';
  bool _isPublic = true;
  bool _showSuccessMessage = false;
  String _searchQuery = '';
  bool _showFailMessage = false;

  UserProvider? userProvider;

  final List<String> _categories = [
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
  ];

  // Mock data for tabs
  List<Map<String, dynamic>> _communityQuestions = [
    {
      'questionId': '201',
      'text': 'What is the correct way to perform Wudu before prayer?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-2',
        'displayName': 'Sister Aisha',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T08:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-201',
        'questionId': '201',
        'answeredBy': {
          'userId': 'user-sheikh-201',
          'displayName': 'Sheikh Ahmad Ali',
          'gender': 'Male',
          'email': 'sheikh.ahmad@example.com',
          'country': 'Egypt',
          'role': 'scholar',
          'language': 'Arabic',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'Wudu is performed in a specific sequence as taught by Prophet Muhammad (PBUH). Start by washing your hands, then rinse your mouth and nose, wash your face, arms up to elbows, wipe your head, and finally wash your feet up to ankles. Each step should be done three times except for wiping the head.',
        'createdAt': '2024-07-11T08:30:00.000Z',
        'language': 'english',
        'upvotesCount': '24',
      },
      'tags': ['wudu', 'prayer', 'worship'],
      'category': 'Worship',
      '_id': 'dbid-201',
      'timeAgo': '2 hours ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': false,
    },
    {
      'questionId': '202',
      'text': 'Can I pray while traveling and what are the concessions?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-3',
        'displayName': 'Brother Omar',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T06:00:00.000Z',
      'aiAnswer':
          'Yes, Islam provides several concessions for travelers including shortening prayers...',
      'topAnswer': null,
      'tags': ['prayer', 'travel'],
      'category': 'Prayer',
      '_id': 'dbid-202',
      'timeAgo': '4 hours ago',
      'responseType': 'ai',
      'isAnswered': false,
      'isFavorited': false,
    },
    {
      'questionId': '203',
      'text':
          'What are the etiquettes when visiting a mosque for the first time?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-4',
        'displayName': 'Sister Fatima',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T04:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-203',
        'questionId': '203',
        'answeredBy': {
          'userId': 'user-fatima-203',
          'displayName': 'Dr. Fatima Al-Zahra',
          'gender': 'Female',
          'email': 'fatima.alzahra@example.com',
          'country': 'Saudi Arabia',
          'role': 'scholar',
          'language': 'Arabic',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'When visiting a mosque for the first time, observe these etiquettes: 1) Enter with your right foot, 2) Remove your shoes before entering, 3) Dress modestly and appropriately, 4) Maintain silence and respect, 5) Avoid walking in front of someone praying, 6) Greet others with "Assalamu alaikum", 7) Follow the mosque\'s specific rules and customs.',
        'createdAt': '2024-07-11T04:30:00.000Z',
        'language': 'english',
        'upvotesCount': '32',
      },
      'tags': ['etiquette', 'mosque'],
      'category': 'Etiquette',
      '_id': 'dbid-203',
      '__v': 0,
      'timeAgo': '6 hours ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': true,
    },
    {
      'questionId': '204',
      'text':
          'How do I balance Islamic principles with modern workplace demands?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-5',
        'displayName': 'Brother Ahmed',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-10T08:00:00.000Z',
      'aiAnswer':
          'Balancing faith with work requires clear communication and seeking halal alternatives...',
      'topAnswer': null,
      'tags': ['daily life', 'workplace', 'Islam'],
      'category': 'Daily Life',
      '_id': 'dbid-204',
      '__v': 0,
      'timeAgo': '1 day ago',
      'responseType': 'ai',
      'isAnswered': false,
      'isFavorited': false,
    },
  ];

  List<Map<String, dynamic>> _myQuestions = [
    {
      'questionId': '101',
      'text': 'Personal question about family relationships in Islam',
      'isPublic': false,
      'askedBy': {
        'id': 'user-1',
        'displayName': 'Test User',
        'country': 'United States',
      },
      'createdAt': '2024-07-01T10:00:00.000Z',
      'aiAnswer':
          'In Islam, family relationships are based on mutual respect, kindness, and fulfilling each other\'s rights and responsibilities.',
      'topAnswer': {
        'answerId': 'answer-101',
        'questionId': '101',
        'answeredBy': {
          'userId': 'user-khadija-101',
          'displayName': 'Sister Khadija Ibrahim',
          'gender': 'Female',
          'email': 'khadija.ibrahim@example.com',
          'country': 'Morocco',
          'role': 'scholar',
          'language': 'Arabic',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'In Islam, family relationships are built on mutual respect, kindness, and fulfilling each other\'s rights and responsibilities. The Prophet Muhammad (PBUH) emphasized treating family members with compassion and understanding. Communication, patience, and forgiveness are key principles in maintaining healthy family bonds.',
        'createdAt': '2024-07-01T11:00:00.000Z',
        'language': 'english',
        'upvotesCount': '5',
      },
      'tags': ['family', 'relationships', 'Islam'],
      'category': 'Family & Marriage',
      '_id': 'dbid-101',
      '__v': 0,
      'timeAgo': '3 days ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': false,
    },
    {
      'questionId': '102',
      'text': 'How to perform Tahajjud prayer correctly?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-1',
        'displayName': 'Test User',
        'country': 'United States',
      },
      'createdAt': '2024-06-25T08:30:00.000Z',
      'aiAnswer':
          'Tahajjud prayer is performed after Isha and before Fajr, preferably in the last third of the night. It consists of at least two rak\'ahs and can be prayed in sets of two.',
      'topAnswer': null,
      'tags': ['tahajjud', 'prayer', 'worship'],
      'category': 'Worship',
      '_id': 'dbid-102',
      '__v': 0,
      'timeAgo': '1 week ago',
      'responseType': 'ai',
      'isAnswered': false,
      'isFavorited': false,
    },
  ];

  List<Map<String, dynamic>> _favoriteQuestions = [
    {
      'questionId': '201',
      'text': 'Understanding the concept of Tawakkul (trust in Allah)',
      'isPublic': true,
      'askedBy': {
        'id': 'user-201',
        'displayName': 'Brother Yusuf',
        'country': 'Palestine',
      },
      'createdAt': '2024-06-01T10:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-201',
        'questionId': '201',
        'answeredBy': {
          'userId': 'user-omar-201',
          'displayName': 'Dr. Omar Suleiman',
          'gender': 'Male',
          'email': 'omar.suleiman@example.com',
          'country': 'United States',
          'role': 'scholar',
          'language': 'English',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'Tawakkul (trust in Allah) is a fundamental concept in Islam that means placing complete trust in Allah while taking the necessary means and actions. It involves doing your best in any situation, making dua (supplication), and then accepting whatever outcome Allah decrees. The Prophet Muhammad (PBUH) said: "If you were to rely upon Allah with the reliance He is due, He would provide for you just as He provides for the birds."',
        'createdAt': '2024-06-01T11:00:00.000Z',
        'language': 'english',
        'upvotesCount': '89',
      },
      'tags': ['tawakkul', 'trust', 'Allah'],
      'category': 'Spirituality',
      '_id': 'dbid-201',
      'timeAgo': '1 month ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': true,
    },
  ];

  // Recent community questions data
  List<Map<String, dynamic>> _recentQuestions = [
    {
      'questionId': '301',
      'text': 'What is the correct way to perform Wudu?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-301',
        'displayName': 'Sister Aisha',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T08:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-301',
        'questionId': '301',
        'answeredBy': {
          'userId': 'user-sheikh-301',
          'displayName': 'Sheikh Ahmad Ali',
          'gender': 'Male',
          'email': 'sheikh.ahmad@example.com',
          'country': 'Egypt',
          'role': 'scholar',
          'language': 'Arabic',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'Wudu (ablution) is performed in a specific sequence: 1) Wash hands three times, 2) Rinse mouth and nose three times, 3) Wash face three times, 4) Wash arms up to elbows three times, 5) Wipe head once, 6) Wash feet up to ankles three times. Each step should be done thoroughly and with intention.',
        'createdAt': '2024-07-11T08:30:00.000Z',
        'language': 'english',
        'upvotesCount': '3',
      },
      'tags': ['wudu', 'prayer', 'worship'],
      'category': 'Worship',
      '_id': 'dbid-301',
      'timeAgo': '2 hours ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': false,
    },
    {
      'questionId': '302',
      'text': 'Can I pray while traveling?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-302',
        'displayName': 'Brother Omar',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T06:00:00.000Z',
      'aiAnswer':
          'Yes, you can pray while traveling. Islam provides accommodations for travelers including shortening prayers (Qasr) and combining certain prayers. The Quran mentions this in verse 4:101. However, it\'s recommended to seek guidance from a certified scholar for your specific travel circumstances.',
      'topAnswer': null,
      'tags': ['prayer', 'travel'],
      'category': 'Prayer',
      '_id': 'dbid-302',
      '__v': 0,
      'timeAgo': '4 hours ago',
      'responseType': 'ai',
      'isAnswered': false,
      'isFavorited': false,
    },
    {
      'questionId': '303',
      'text': 'What are the etiquettes of visiting a mosque?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-303',
        'displayName': 'Sister Fatima',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T04:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-303',
        'questionId': '303',
        'answeredBy': {
          'userId': 'user-fatima-303',
          'displayName': 'Sister Fatima Al-Zahra',
          'gender': 'Female',
          'email': 'fatima.alzahra@example.com',
          'country': 'Saudi Arabia',
          'role': 'scholar',
          'language': 'Arabic',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'When visiting a mosque, observe these etiquettes: 1) Enter with your right foot, 2) Remove shoes before entering, 3) Dress modestly, 4) Maintain silence and respect, 5) Avoid walking in front of someone praying, 6) Greet others with "Assalamu alaikum", 7) Follow the mosque\'s specific rules.',
        'createdAt': '2024-07-11T04:30:00.000Z',
        'language': 'english',
        'upvotesCount': '0',
      },
      'tags': ['etiquette', 'mosque'],
      'category': 'Etiquette',
      '_id': 'dbid-303',
      '__v': 0,
      'timeAgo': '6 hours ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': false,
    },
    {
      'questionId': '304',
      'text': 'Personal family guidance needed',
      'isPublic': false,
      'askedBy': {
        'id': 'user-304',
        'displayName': 'Anonymous',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-11T03:00:00.000Z',
      'aiAnswer': '',
      'topAnswer': {
        'answerId': 'answer-304',
        'questionId': '304',
        'answeredBy': {
          'userId': 'user-buale-304',
          'displayName': 'Buale',
          'gender': 'Male',
          'email': 'buale@example.com',
          'country': 'Somalia',
          'role': 'scholar',
          'language': 'Somali',
          'savedQuestions': [],
          'savedLessons': [],
          'createdAt': {'\$date': '2024-01-01T00:00:00.000Z'},
        },
        'text':
            'For personal family guidance, I recommend seeking advice from a local Islamic scholar or counselor who can provide specific guidance based on your situation. Islam emphasizes family harmony, communication, and mutual respect. Consider scheduling a private consultation for detailed advice.',
        'createdAt': '2024-07-11T03:30:00.000Z',
        'language': 'english',
        'upvotesCount': '1',
      },
      'tags': ['family', 'guidance'],
      'category': 'Family & Marriage',
      '_id': 'dbid-304',
      '__v': 0,
      'timeAgo': '8 hours ago',
      'responseType': 'human',
      'isAnswered': true,
      'isFavorited': false,
    },
    {
      'questionId': '305',
      'text': 'How should I handle conflicts with Islamic principles at work?',
      'isPublic': true,
      'askedBy': {
        'id': 'user-305',
        'displayName': 'Brother Ahmed',
        'country': 'Palestine',
      },
      'createdAt': '2024-07-10T08:00:00.000Z',
      'aiAnswer':
          'Balancing Islamic principles with workplace requirements can be challenging. The key is open communication with your employer about your religious needs, seeking halal alternatives when possible, and consulting with Islamic scholars for guidance on specific situations. Remember that Islam emphasizes both fulfilling your obligations and maintaining your faith.',
      'topAnswer': null,
      'tags': ['work', 'Islamic principles', 'conflict'],
      'category': 'Daily Life',
      '_id': 'dbid-305',
      'timeAgo': '1 day ago',
      'responseType': 'ai',
      'isAnswered': false,
      'isFavorited': false,
    },
  ];

  List<Map<String, dynamic>> _myAnswers = [
    {
      'question': {
        'questionId': '501',
        'text': 'What is Zakat and who is eligible to receive it?',
        'category': 'Islamic Finance',
        'askedBy': {'displayName': 'Brother Ali'},
        'createdAt': '2024-07-09T10:00:00.000Z',
      },
      'topAnswer': {
        'answerId': 'answer-501',
        'text':
            'Zakat is a form of almsgiving and one of the Five Pillars of Islam. Eligible recipients include the poor, needy, and others as specified in the Quran.',
        'answeredBy': {'displayName': 'Sheikh Omar'},
        'createdAt': '2024-07-09T12:00:00.000Z',
        'upvotesCount': 10,
      },
      'volunteerAnswer': {
        'answerId': 'answer-502',
        'text':
            'Zakat is obligatory charity. It should be given to the poor and those in need as described in Surah At-Tawbah.',
        'answeredBy': {'displayName': 'You'},
        'createdAt': '2024-07-09T13:00:00.000Z',
        'upvotesCount': 2,
      },
    },
    {
      'question': {
        'questionId': '502',
        'text': 'How many times a day do Muslims pray?',
        'category': 'Worship',
        'askedBy': {'displayName': 'Sister Maryam'},
        'createdAt': '2024-07-08T09:00:00.000Z',
      },
      'topAnswer': {
        'answerId': 'answer-503',
        'text':
            'Muslims pray five times a day: Fajr, Dhuhr, Asr, Maghrib, and Isha.',
        'answeredBy': {'displayName': 'Imam Bilal'},
        'createdAt': '2024-07-08T10:00:00.000Z',
        'upvotesCount': 15,
      },
      'volunteerAnswer': {
        'answerId': 'answer-504',
        'text':
            'There are five daily prayers in Islam, each at specific times throughout the day and night.',
        'answeredBy': {'displayName': 'You'},
        'createdAt': '2024-07-08T11:00:00.000Z',
        'upvotesCount': 3,
      },
    },
  ];
  bool _myAnswersLoaded = true;
  bool _myQuestionsLoaded = false;
  bool _communityQuestionsLoaded = false;

  Timer? _timer;

  final Map<String, GlobalKey> _questionKeys = {}; // Add this line
  bool _isAutoLoading = false; // Add this line

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _successAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _successAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _failAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _failAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _failAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    // Get userProvider after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      userProvider = Provider.of<UserProvider>(context, listen: false);
      _getCommunityAndRecentQuestions();
      _getMyQuestions();
      getFavoriteQuestions();
      _getMyAnswers();

      // Listen to user provider changes to update favorites
      userProvider?.addListener(() {
        if (mounted && _communityQuestionsLoaded && _myQuestionsLoaded) {
          getFavoriteQuestions();
        }
      });
    });
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 0 && _tabController.indexIsChanging) {
        _getCommunityAndRecentQuestions();
        getFavoriteQuestions();
      } else if (_tabController.index == 1 && _tabController.indexIsChanging) {
        if (userProvider?.user?['role'] == 'certified_volunteer' ||
            userProvider?.user?['role'] == 'volunteer_pending') {
          _getMyAnswers();
        } else {
          _getMyQuestions();
        }
      } else if (_tabController.index == 2 && _tabController.indexIsChanging) {
        getFavoriteQuestions();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navListener = () {
        if (_navProvider?.scrollToFavorites == true) {
          _tabController.animateTo(2);
          if (_favoritesScrollController.hasClients) {
            _favoritesScrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          _navProvider?.resetScrollToFavorites();
        }
      };
      _navProvider?.addListener(_navListener);
    });
    _communityQuestionsScrollController.addListener(() {
      if (_communityQuestionsScrollController.position.pixels >=
          _communityQuestionsScrollController.position.maxScrollExtent - 50) {
        _loadMoreCommunityQuestionsIfNeeded();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navProvider == null) {
      _navProvider = Provider.of<NavigationProvider>(context, listen: false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _searchController.dispose();
    _successAnimationController.dispose();
    _failAnimationController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    // Remove listener to prevent memory leaks
    userProvider?.removeListener(() {});
    _navProvider?.removeListener(_navListener);
    _favoritesScrollController.dispose();
    _recentQuestionsScrollController.dispose();
    _communityQuestionsScrollController.dispose();
    super.dispose();
  }

  void _submitQuestion() async {
    if (_formKey.currentState!.validate() && _selectedCategory.isNotEmpty) {
      try {
        final token = await AuthUtils.getValidToken(context);
        if (token == null) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final tags = await extractTagsFromQuestionGemini(
          _questionController.text,
        );
        // Generate AI answer before submitting
        var aiAnswer = await generateAIAnswerGemini(_questionController.text);
        if (aiAnswer.trim().isEmpty) {
          aiAnswer = 'pending';
        }

        final requestbody = {
          "text": _questionController.text,
          "isPublic": _isPublic,
          "category": _selectedCategory,
          "tags": tags,
          "aiAnswer": aiAnswer,
        };

        var response = await http.post(
          Uri.parse(questions),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(requestbody),
        );
        final data = jsonDecode(response.body);

        if (response.statusCode == 201) {
          if (data['status'] == true) {
            print('Question submitted successfully');

            // Refresh my questions to include the new question
            if (mounted) {
              _getMyQuestions();
            }

            // Reset form
            _questionController.clear();
            setState(() {
              _selectedCategory = '';
              _isPublic = true;
              _showSuccessMessage = true;
              _showFailMessage = false;
            });

            _successAnimationController.forward();

            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showSuccessMessage = false;
                });
                _successAnimationController.reset();
              }
            });
          } else {
            print('Question submission failed');
            setState(() {
              _showFailMessage = true;
              _showSuccessMessage = false;
            });
            _failAnimationController.forward();
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showFailMessage = false;
                });
                _failAnimationController.reset();
              }
            });
          }
        } else {
          setState(() {
            _showFailMessage = true;
            _showSuccessMessage = false;
          });
          _failAnimationController.forward();
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showFailMessage = false;
              });
              _failAnimationController.reset();
            }
          });
        }
      } catch (e) {
        print('Error submitting question: $e');
        setState(() {
          _showFailMessage = true;
          _showSuccessMessage = false;
        });
        _failAnimationController.forward();
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showFailMessage = false;
            });
            _failAnimationController.reset();
          }
        });
      }
    }
  }

  Future<List<String>> extractTagsFromQuestionGemini(
    String questionText,
  ) async {
    final prompt =
        'Extract 3-5 relevant tags (single words or short phrases) from the following question. Return ONLY a JSON array of strings, e.g. ["tag1", "tag2", "tag3"]. Question: "$questionText"';

    final completer = Completer<List<String>>();
    StringBuffer buffer = StringBuffer();

    Gemini.instance
        .promptStream(parts: [Part.text(prompt)])
        .listen(
          (value) {
            if (value?.output != null) {
              buffer.write(value!.output);
            }
          },
          onDone: () {
            try {
              final output = buffer.toString();
              final jsonStart = output.indexOf('[');
              final jsonEnd = output.lastIndexOf(']');
              if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
                final jsonString = output.substring(jsonStart, jsonEnd + 1);
                final List<dynamic> tags = jsonDecode(jsonString);
                if (!completer.isCompleted) {
                  completer.complete(tags.whereType<String>().toList());
                }
                return;
              }
              // Fallback: try to parse the whole output as JSON
              try {
                final List<dynamic> tags = jsonDecode(output);
                if (!completer.isCompleted) {
                  completer.complete(tags.whereType<String>().toList());
                }
              } catch (_) {
                if (!completer.isCompleted) {
                  completer.complete([]);
                }
              }
            } catch (e) {
              print('Error extracting tags from Gemini: $e');
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            }
          },
          onError: (e) {
            print('Error extracting tags from Gemini: $e');
            if (!completer.isCompleted) {
              completer.complete([]);
            }
          },
        );

    return completer.future;
  }

  // Generate AI answer from Gemini for submission
  Future<String> generateAIAnswerGemini(String questionText) async {
    final prompt = '''
Provide a concise, clear Islamic answer to the following question.
Use proper spacing between all words and punctuation.
Format the response in a clear, readable manner with correct grammar and spacing.
Answer is English only.
Question: "$questionText"
''';

    StringBuffer buffer = StringBuffer();
    final completer = Completer<String>();
    String previousOutput = '';

    try {
      Gemini.instance
          .promptStream(parts: [Part.text(prompt)])
          .listen(
            (value) {
              if (value?.output != null) {
                final current = value?.output?.trim() ?? '';
                final lastChar =
                    previousOutput.isNotEmpty
                        ? previousOutput[previousOutput.length - 1]
                        : '';

                // Add a space if needed
                if (lastChar.isNotEmpty &&
                    !lastChar.contains(RegExp(r'[ \n\r\t.,;:!?(){}\[\]]')) &&
                    !current.startsWith(RegExp(r'[ \n\r\t.,;:!?(){}\[\]]'))) {
                  buffer.write(' ');
                }

                buffer.write(current);
                previousOutput = current;
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(buffer.toString());
              }
            },
            onError: (e) {
              print('Error fetching AI answer from Gemini: $e');
              if (!completer.isCompleted) {
                completer.complete('');
              }
            },
          );

      return await completer.future;
    } catch (e) {
      print("error extracting tags: $e");
      return '';
    }
  }

  //Todo: show myAnswers tab for certifiedVolunteers
  //Done deep checking
  List<Map<String, dynamic>> _getFilteredCommunityQuestions() {
    return _communityQuestions
        .where(
          (q) =>
              q['isFlagged'] != true &&
              (_searchQuery.isEmpty ||
                  q['text'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  q['category'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  (q['tags'] != null &&
                      (q['tags'] as List).any(
                        (tag) => tag.toString().toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      ))),
        )
        .toList();
  }

  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreCommunityQuestions = true;
  bool _isLoadingCommunityQuestions = false;

  Future<void> _getCommunityAndRecentQuestions({bool loadMore = false}) async {
    //loadMore is used to load more questions when user scrolls to the bottom of the list
    if (_isLoadingCommunityQuestions) return;
    if (!loadMore) {
      // Reset pagination if not loading more (initial load or refresh)
      _currentPage = 1;
      _hasMoreCommunityQuestions = true;
    }
    if (!_hasMoreCommunityQuestions) return;

    _isLoadingCommunityQuestions = true;

    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        if (mounted) {
          setState(() {
            _communityQuestions = [];
            _recentQuestions = [];
            _communityQuestionsLoaded = true;
          });
        }
        _isLoadingCommunityQuestions = false;
        return;
      }

      final url = Uri.parse(
        "$publicQuestions?page=$_currentPage&limit=$_pageSize",
      );
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final questions = data['question'];
        print('questions: ${questions.length}');
        if (questions is List && questions.isNotEmpty) {
          List<Map<String, dynamic>> updatedQuestions = [];
          for (var question in questions) {
            final askedByRaw = question['askedBy'];
            Map<String, dynamic> askedBy;
            if (askedByRaw is String) {
              askedBy = {'id': askedByRaw, 'displayName': askedByRaw};
            } else if (askedByRaw is Map) {
              askedBy = {
                'id': askedByRaw['id'] ?? '',
                'displayName': askedByRaw['displayName'] ?? '',
                'country': askedByRaw['country'] ?? '',
              };
            } else {
              askedBy = {'id': '', 'displayName': '', 'country': ''};
            }

            updatedQuestions.add({
              'questionId': question['questionId'] ?? question['_id'] ?? '',
              'text': question['text'] ?? '',
              'isPublic': question['isPublic'] ?? true,
              'askedBy': askedBy,
              'createdAt':
                  question['createdAt'] ?? DateTime.now().toIso8601String(),
              'aiAnswer': question['aiAnswer'] ?? '',
              'topAnswer': question['topAnswer'] ?? null,
              'tags': question['tags'] ?? [],
              'category': question['category'] ?? '',
              '_id': question['_id'] ?? '',
              'timeAgo': _calculateTimeAgo(question['createdAt']),
              'responseType': (question['topAnswer'] == null) ? 'ai' : 'human',
              'isAnswered': (question['topAnswer'] != null),
              'isFlagged': question['isFlagged'] ?? false,
            });
          }
          // Exclude questions asked by the current user
          final currentUserId = userProvider?.userId;
          if (currentUserId != null) {
            updatedQuestions =
                updatedQuestions
                    .where((q) => q['askedBy']?['id'] != currentUserId)
                    .toList();
          }

          if (mounted) {
            setState(() {
              if (loadMore) {
                _communityQuestions.addAll(updatedQuestions);
              } else {
                _communityQuestions = updatedQuestions;
              }
              _recentQuestions = List<Map<String, dynamic>>.from(
                _communityQuestions,
              )..sort((a, b) {
                final aDate =
                    DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
                final bDate =
                    DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
                return bDate.compareTo(aDate);
              });
              _communityQuestionsLoaded = true;
            });
            getFavoriteQuestions();
            await retryPendingAIs(_communityQuestions);
          }
          print('updatedQuestions: ${updatedQuestions.length}');

          // If received less than page size, no more pages left
          if (questions.length < _pageSize) {
            _hasMoreCommunityQuestions = false;
          } else {
            _currentPage++;
          }
        } else {
          if (mounted) {
            setState(() {
              if (!loadMore) {
                _communityQuestions = [];
                _recentQuestions = [];
              }
              _communityQuestionsLoaded = true;
            });
            getFavoriteQuestions();
          }
          _hasMoreCommunityQuestions = false;
        }
      } else {
        print("Failed to load community questions");
        if (mounted) {
          setState(() {
            if (!loadMore) {
              _communityQuestions = [];
              _recentQuestions = [];
            }
            _communityQuestionsLoaded = true;
          });
          getFavoriteQuestions();
        }
        _hasMoreCommunityQuestions = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!loadMore) {
            _communityQuestions = [];
            _recentQuestions = [];
          }
          _communityQuestionsLoaded = true;
        });
        getFavoriteQuestions();
      }
      print('Error loading community questions: $e');
    } finally {
      _isLoadingCommunityQuestions = false;
    }
  }

  //Done deep checking
  void _getMyQuestions() async {
    // Fetch my questions and expect flagged questions
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        // User was logged out due to expired token
        if (mounted) {
          setState(() {
            _myQuestions = [];
            _myQuestionsLoaded = true;
          });
        }
        return;
      }

      var response = await http.get(
        Uri.parse(myquestions),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == true) {
          final questions = data['question'];
          if (questions is List) {
            List<Map<String, dynamic>> updatedMyQuestions = [];
            for (var question in questions) {
              // askedBy is a String or Map in backend, convert to Map for UI
              //expect flagged questions
              
              final askedByRaw = question['askedBy'];
              Map<String, dynamic> askedBy;
              if (askedByRaw is String) {
                askedBy = {'id': askedByRaw, 'displayName': askedByRaw};
              } else if (askedByRaw is Map) {
                askedBy = {
                  'id': askedByRaw['id'] ?? '',
                  'displayName': askedByRaw['displayName'] ?? '',
                  'country': askedByRaw['country'] ?? '',
                };
              } else {
                askedBy = {'id': '', 'displayName': '', 'country': ''};
              }
              updatedMyQuestions.add({
                'questionId': question['questionId'] ?? question['_id'] ?? '',
                'text': question['text'] ?? '',
                'isPublic': question['isPublic'] ?? true,
                'askedBy': askedBy,
                'createdAt':
                    question['createdAt'] ?? DateTime.now().toIso8601String(),
                'aiAnswer': question['aiAnswer'] ?? '',
                'topAnswer': question['topAnswer'] ?? null,
                'tags': question['tags'] ?? [],
                'category': question['category'] ?? '',
                '_id': question['_id'] ?? '',
                // UI compatibility fields
                'timeAgo': _calculateTimeAgo(question['createdAt']),
                'responseType':
                    (question['topAnswer'] == null) ? 'ai' : 'human',
                'isAnswered': (question['topAnswer'] != null),
                'isFlagged': question['isFlagged'] ?? false,
              });
            }

            // Sort by creation date (newest first)
            updatedMyQuestions.sort((a, b) {
              final aDate =
                  DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
              final bDate =
                  DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
              return bDate.compareTo(aDate); // descending: newest first
            });

            if (mounted) {
              setState(() {
                _myQuestions = updatedMyQuestions;
                _myQuestionsLoaded = true;
              });
              // Update favorites when my questions are loaded
              getFavoriteQuestions();
              await retryPendingAIs(_myQuestions);
            }
          } else {
            if (mounted) {
              setState(() {
                _myQuestions = [];
                _myQuestionsLoaded = true;
              });
              getFavoriteQuestions();
            }
            print('No my questions found or questions is not a List.');
          }
        } else {
          print("my questions failed to load");
          if (mounted) {
            setState(() {
              _myQuestions = [];
              _myQuestionsLoaded = true;
            });
            getFavoriteQuestions();
          }
        }
      } else {
        print("my questions request failed with status:  [38;5;9m");
        if (mounted) {
          setState(() {
            _myQuestions = [];
            _myQuestionsLoaded = true;
          });
          getFavoriteQuestions();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myQuestions = [];
          _myQuestionsLoaded = true;
        });
        getFavoriteQuestions();
      }
      print('Error loading my questions: $e');
    }
  }

  void _getMyAnswers() async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        if (mounted) {
          setState(() {
            _myAnswers = [];
            _myAnswersLoaded = true;
          });
        }
        return;
      }

      var response = await http.get(
        Uri.parse(myAnswersUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final answers = data['answers'];
        if (answers is List) {
          Map<String, Map<String, dynamic>> latestAnswersByQuestion = {};
          for (var ans in answers) {
            final question = ans['question'];
            final questionId = question?['questionId'];
            if (questionId == null) continue;
            if (ans['isFlagged'] == true ||
                ans['isHidden'] == true ||
                ans['hiddenTemporary'] == true)
              continue;
            // If you want the latest answer, compare createdAt
            if (!latestAnswersByQuestion.containsKey(questionId) ||
                DateTime.parse(ans['createdAt']).isAfter(
                  DateTime.parse(
                    latestAnswersByQuestion[questionId]!['createdAt'],
                  ),
                )) {
              latestAnswersByQuestion[questionId] = ans;
            }
          }

          List<Map<String, dynamic>> myAnswersList = [];
          for (var ans in latestAnswersByQuestion.values) {
            Map<String, dynamic>? question = ans['question'];
            final topAnswerId = question?['topAnswerId'];
            Map<String, dynamic>? topAnswer;
            topAnswer = ans["topAnswer"];
            myAnswersList.add({
              'question': question,
              'topAnswer': topAnswer,
              'volunteerAnswer': ans,
              'askedBy': ans["askedBy"],
            });
          }
          if (!mounted) return;
          setState(() {
            _myAnswers = myAnswersList;
            _myAnswersLoaded = true;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _myAnswers = [];
          _myAnswersLoaded = true;
        });
      }
    } catch (e) {
      print("error fetching my answer: $e");
      if (!mounted) return;
      setState(() {
        _myAnswers = [];
        _myAnswersLoaded = true;
      });
    }
  }

  // Helper function to calculate time ago
  String _calculateTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Just now';

    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  //Done deep checking
  // Get favorite questions for the user by matching savedQuestions IDs with questions in _recentQuestions and _communityQuestions
  void getFavoriteQuestions() {
    if (userProvider == null) return;
    if (_communityQuestionsLoaded && _myQuestionsLoaded) {
      final savedIds = (userProvider!.savedQuestions) as List?;
      if (savedIds == null || savedIds.isEmpty) {
        print("no saved questions for this user");
        if (mounted) {
          setState(() {
            _favoriteQuestions = [];
          });
        }
        return;
      }
      final Set<String> idSet = savedIds.map((e) => e.toString()).toSet();
      print("saved questions ids: $idSet");

      // Use a Map to avoid duplicates by question ID
      final Map<String, Map<String, dynamic>> favoritesMap = {};

      // Check recent questions first
      for (final q in _recentQuestions) {
        final qid = q['questionId'] ?? q['_id'] ?? '';
        if (idSet.contains(qid)) {
          favoritesMap[qid] = q;
        }
      }

      // Check my questions (will override if same ID exists)
      for (final q in _myQuestions) {
        final qid = q['questionId'] ?? q['_id'] ?? '';
        if (idSet.contains(qid)) {
          favoritesMap[qid] = q;
        }
      }

      final List<Map<String, dynamic>> favorites = favoritesMap.values.toList();

      if (mounted) {
        setState(() {
          _favoriteQuestions = favorites;
        });
      }
    }
  }

  void refreshAllTabs() {
    _getCommunityAndRecentQuestions();
    _getMyAnswers();
    getFavoriteQuestions();
    _getMyQuestions();
  }

  Future<void> _loadMoreCommunityQuestionsIfNeeded() async {
    if (_isAutoLoading || !_hasMoreCommunityQuestions) return;
    _isAutoLoading = true;
    await _getCommunityAndRecentQuestions(loadMore: true);
    await Future.delayed(Duration(milliseconds: 100));
    if (_communityQuestions.isNotEmpty) {
      final lastQuestionId = _communityQuestions.last['questionId'];
      final key = _questionKeys[lastQuestionId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
    _isAutoLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userProvider?.role == "user")
              // Header
              _buildHeader(),
            SizedBox(height: 24),

            // Submit Question Form
            if (userProvider?.role == "user") _buildSubmissionForm(),
            SizedBox(height: 24),

            // Guidelinesif (userProvider?.role == "user")
            if (userProvider?.role == "user") _buildGuidelines(),
            SizedBox(height: 24),

            // Tabbed Interface
            _buildTabbedInterface(),
            SizedBox(height: 24),

            // Recent Questions
            _buildRecentQuestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask Your Question',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF104C34),
            ),
            textAlign: TextAlign.start,
          ),
          SizedBox(height: 8),
          Text(
            'Get guidance from certified Islamic scholars and volunteers',
            style: TextStyle(color: Color(0xFF206F4F)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm() {
    bool isValid =
        _selectedCategory.isNotEmpty &&
        _questionController.text.trim().isNotEmpty;

    return Card(
      color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(0xFFBFE3D5)),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.help_outline, color: Color(0xFF104C34), size: 20),
                SizedBox(width: 8),
                Text(
                  'Submit Your Question',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF104C34),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Success Message
            if (_showSuccessMessage)
              AnimatedBuilder(
                animation: _successAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _successAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        border: Border.all(color: Color(0xFFBFE3D5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF206F4F),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Question submitted successfully!',
                            style: TextStyle(
                              color: Color(0xFF104C34),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_showFailMessage)
              AnimatedBuilder(
                animation: _failAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _failAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE6E6),
                        border: Border.all(color: Color(0xFFD32F2F)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error, color: Color(0xFFD32F2F), size: 20),
                          SizedBox(width: 8),
                          // Use Flexible to allow text to wrap and avoid overflow
                          Flexible(
                            child: Text(
                              'Failed to submit question. Please try again.',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Public/Private Toggle
                  _buildVisibilityToggle(),
                  SizedBox(height: 20),

                  // Category Selection
                  _buildCategoryDropdown(),
                  SizedBox(height: 20),

                  // Question Input
                  _buildQuestionInput(),
                  SizedBox(height: 24),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Visibility',
          style: TextStyle(
            color: Color(0xFF165A3F),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF4FBF8),
            border: Border.all(color: Color(0xFFBFE3D5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _isPublic ? Icons.lock_open : Icons.lock,
                color: Color(0xFF206F4F),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPublic ? 'Public Question' : 'Private Question',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF104C34),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _isPublic
                          ? 'Visible to the community and may receive AI responses'
                          : 'Only certified volunteers can view your question',
                      style: TextStyle(fontSize: 12, color: Color(0xFF206F4F)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeColor: Color(0xFF2D8662),
              ),
            ],
          ),
        ),
        if (!_isPublic)
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFCF7E8),
              border: Border.all(color: Color(0xFFE8C181)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Color(0xFFD4A574), size: 16),
                SizedBox(width: 8),
                Text(
                  'Only certified volunteers can view your question.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F7556),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: Color(0xFF165A3F),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField(
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select a category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFBFE3D5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFBFE3D5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2D8662), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items:
              _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Question',
          style: TextStyle(
            color: Color(0xFF165A3F),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _questionController,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(
            hintText:
                'Please describe your question in detail. Include context if relevant.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFBFE3D5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFBFE3D5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2D8662), width: 2),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your question';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    bool isValid =
        _selectedCategory.isNotEmpty &&
        _questionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid ? _submitQuestion : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2D8662),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 16),
            SizedBox(width: 8),
            Text(
              'Submit Question',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    return Card(
      color: Color(0xFFFCF7E8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(0xFFE8C181)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guidelines for Asking Questions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF104C34),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ...[
                  'Every question is welcome!',
                  ' Ask with sincerity and respect.,'
                      'Be clear and focused.',
                  'Choose the most relevant category.',
                ]
                .map(
                  (guideline) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: Color(0xFF45A376),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            guideline,
                            style: TextStyle(
                              color: Color(0xFF165A3F),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

 Widget _buildRecentQuestions() {
  debugPrint("🚩 _recentQuestions: ${_recentQuestions}");
  debugPrint("🚩 _recentQuestions: ${_recentQuestions.length}");
  final filteredQuestions = _recentQuestions
      .where((question) =>
          question['isFlagged'] != true)
      .toList();

  return Card(
    color: Colors.white.withOpacity(0.8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Color(0xFFBFE3D5)),
    ),
    elevation: 8,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.question_answer, color: Color(0xFF104C34), size: 20),
              Text(
                'Recent Community Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF104C34),
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ListView.builder(
              controller: _recentQuestionsScrollController,
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = filteredQuestions[index];
                final questionId = question['questionId'] ?? question['_id'];

                return QuestionCard(
                  key: ValueKey(questionId), 
                  question: question,

                  onReportSuccess: () {
                    setState(() {
                      final originalIndex = _recentQuestions.indexWhere(
                        (q) => (q['questionId'] ?? q['_id']) == questionId,
                      );
                      if (originalIndex != -1) {
                        _recentQuestions[originalIndex]['isFlagged'] = true;
                      }
                    });
                  },

                  onReportAnswerSuccess: () {
                    final originalIndex = _recentQuestions.indexWhere(
                      (q) => (q['questionId'] ?? q['_id']) == questionId,
                    );

                    if (originalIndex != -1) {
                      setState(() {
                        if (_recentQuestions[originalIndex]['topAnswer'] == null) {
                          _recentQuestions[originalIndex]['topAnswer'] = {};
                        }

                        _recentQuestions[originalIndex]['topAnswer']['isFlagged'] = true;

                        _recentQuestions[originalIndex] = {
                          ..._recentQuestions[originalIndex],
                          'lastModified': DateTime.now().millisecondsSinceEpoch,
                        };
                      });
                      
                      // Force immediate UI refresh to show the new answer
                      refreshAllTabs();
                    }
                  },

                  // When updating the question
                  onUpdate: (updatedFields) {
                    setState(() {
                      final originalIndex = _recentQuestions.indexWhere(
                        (q) => (q['questionId'] ?? q['_id']) == questionId,
                      );
                      if (originalIndex != -1) {
                        _recentQuestions[originalIndex] = {
                          ..._recentQuestions[originalIndex],
                          ...updatedFields,
                        };
                      }
                    });
                  },

                  onRefresh: refreshAllTabs,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildTabbedInterface() {
    final userRole = userProvider?.user?['role'] ?? 'user';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Questions & Answers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF104C34),
          ),
        ),
        SizedBox(height: 20),

        Card(
          color: Colors.transparent,
          /* shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFBFE3D5)),
          ), */
          elevation: 0,
          child: Column(
            children: [
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFBFE3D5), width: 1),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Check if screen is wide enough to fit all tabs
                    bool isWideScreen = constraints.maxWidth > 600;

                    return TabBar(
                      controller: _tabController,
                      labelColor: Color(0xFF206F4F),
                      unselectedLabelColor: Color(0xFF45A376),
                      indicatorColor: Color(0xFF2D8662),
                      indicatorWeight: 3,
                      isScrollable: !isWideScreen,
                      labelPadding:
                          isWideScreen
                              ? EdgeInsets.symmetric(horizontal: 16)
                              : EdgeInsets.symmetric(horizontal: 8),
                      labelStyle: TextStyle(
                        fontSize: isWideScreen ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: isWideScreen ? 14 : 13,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.question_answer, size: 16),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Recommended',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              /* SizedBox(width: 2),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F3ED),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_communityQuestions.length}',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ), */
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  (userRole == 'certified_volunteer' ||
                                          userRole == 'volunteer_pending')
                                      ? 'My Answers'
                                      : 'My Questions',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(width: 2),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F3ED),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (userRole == 'certified_volunteer' ||
                                          userRole == 'volunteer_pending')
                                      ? '${_myAnswers.length}'
                                      : '${_myQuestions.length}',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, size: 16),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Favorites',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(width: 2),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F3ED),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_favoriteQuestions.length}',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Tab Content
              Container(
                height: MediaQuery.of(context).size.height * 0.8,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCommunityTab(),
                    (userRole == 'certified_volunteer' ||
                            userRole == 'volunteer_pending')
                        ? _buildMyAnswersTab()
                        : _buildMyQuestionsTab(),
                    _buildFavoritesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _printCommunityQuestions() {
    const encoder = JsonEncoder.withIndent('  ');
    final pretty = encoder.convert(_communityQuestions);
    debugPrint(pretty);
  }

  Widget _buildCommunityTab() {
    List<Map<String, dynamic>> filteredQuestions =
        _getFilteredCommunityQuestions();

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search community questions...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF45A376)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFBFE3D5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFBFE3D5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2D8662), width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 16),

              // Questions List
              Expanded(
                child:
                    filteredQuestions.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No community questions yet'
                                  : 'No questions found matching " [38;5;9m{_searchQuery}"',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller:
                              _communityQuestionsScrollController, // Attach controller here
                          itemCount: filteredQuestions.length,
                          itemBuilder: (context, index) {
                            final question = filteredQuestions[index];
                            final questionId = question['questionId'];
                            _questionKeys.putIfAbsent(
                              questionId,
                              () => GlobalKey(),
                            );
                            return QuestionCard(
                              key: _questionKeys[questionId],
                              question: question,
                              onUpdate: (updatedFields) {
                                print(
                                  "✅ onUpdate triggered with: $updatedFields",
                                );
                                //Update the question in the list to show the new changes directly on the screen
                                setState(() {
                                  _communityQuestions[index].addAll(updatedFields);

                                });
                                //Use a helper function to refresh all tabs
                                _refreshQuestion(index);//refresh the question to show the new changes directly on the screen
                               refreshAllTabs();  
                              
              
                              },
                              onReportSuccess: () {
                                final questionId = question['questionId'];
                                final originalIndex = _communityQuestions
                                    .indexWhere(
                                      (q) => q['questionId'] == questionId,
                                    );
                                if (originalIndex != -1) {
                                  setState(() {
                                    _communityQuestions[originalIndex]['isFlagged'] =
                                        true;
                                  });
                                }
                              },
                                                     onReportAnswerSuccess: () {
                            _printCommunityQuestions();
                          final questionId = question['questionId'];
                             final originalIndex = _communityQuestions
                             .indexWhere(
                           (q) => q['questionId'] == questionId,
                                  );

                             if (originalIndex != -1) {    
                            setState(() {
        // Ensure the structure exists
                if (_communityQuestions[originalIndex]['topAnswer'] == null) {
                        _communityQuestions[originalIndex]['topAnswer'] = {};
                        }
                     _communityQuestions[originalIndex]['topAnswer']['isFlagged'] = true;
        
        // Force immediate UI update by marking the entire question as modified
                    _communityQuestions[originalIndex] = {
                  ..._communityQuestions[originalIndex],
                    'lastModified': DateTime.now().millisecondsSinceEpoch,
                  };
                                    });
                       }
    
                   refreshAllTabs();
                },
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
        if (filteredQuestions.isNotEmpty)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () async {
                await _getCommunityAndRecentQuestions(loadMore: true);
                await Future.delayed(Duration(milliseconds: 100));
                if (_communityQuestions.isNotEmpty) {
                  // Scroll to last question widget
                  final lastQuestionId = _communityQuestions.last['questionId'];
                  final key = _questionKeys[lastQuestionId];
                  if (key != null && key.currentContext != null) {
                    Scrollable.ensureVisible(
                      key.currentContext!,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              backgroundColor: AppColors.askPageSubtitle,
              child: Icon(Icons.arrow_downward, color: Colors.white),
              tooltip: 'Scroll Down',
            ),
          ),
      ],
    );
  }

  Widget _buildMyQuestionsTab() {
     final visibleQuestions = _myQuestions
      .where((q) => q['isFlagged'] != true) 
      .toList();
    return Padding(
      padding: EdgeInsets.all(16),
      child:
          visibleQuestions.isEmpty
              ? _buildEmptyState(
                'No questions asked yet',
                'Start by asking your first question',
              )
              : ListView.builder(
                itemCount: visibleQuestions.length,
                itemBuilder: (context, index) {
                  final question = visibleQuestions[index];
                                     return QuestionCard(
                     question: question,
                     onRefresh: refreshAllTabs,
                     onReportSuccess: () {
                       if (!mounted) return;
                       setState(() {
                         final id = question['questionId'];
                         final originalIndex = _myQuestions.indexWhere(
                           (q) => q['questionId'] == id,
                         );
                         if (originalIndex != -1) {
                           _myQuestions.removeAt(originalIndex);
                         }
                       });
                     },
                     onReportAnswerSuccess: () {
                       if (!mounted) return;
                       setState(() {
                         final id = question['questionId'];
                         final originalIndex = _myQuestions.indexWhere(
                           (q) => q['questionId'] == id,
                         );
                         if (originalIndex != -1) {
                           if (_myQuestions[originalIndex]['topAnswer'] == null) {
                             _myQuestions[originalIndex]['topAnswer'] = {};
                           }
                           _myQuestions[originalIndex]['topAnswer']['isFlagged'] = true;
                           
                           // Force immediate UI update
                           _myQuestions[originalIndex] = {
                             ..._myQuestions[originalIndex],
                             'lastModified': DateTime.now().millisecondsSinceEpoch,
                           };
                         }
                       });
                          refreshAllTabs();
                     },
                   );
                },
              ),
    );
  }

  Widget _buildMyAnswersTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child:
          _myAnswers.isEmpty
              ? _buildEmptyState(
                'No answers submitted yet',
                'Start by answering questions in the community',
              )
              : ListView.builder(
                itemCount: _myAnswers.length,
                itemBuilder: (context, index) {
                  final item = _myAnswers[index];
                  print('item from my answers: $item');
                  return MyAnswerCard(
                    item: item,
                    onDelete: () {
                      if (!mounted) return;
                      setState(() {
                        _myAnswers.removeAt(index);
                      });
                    },
                    onEdit: (text) {
                      print('Editing answer at index $index with text: $text');
                      // Handle edit action
                      //edit the answer after edit it in the data base
                      setState(() {
                        print('New text: $text');
                        _myAnswers[index]['volunteerAnswer']['text'] = text;
                        _myAnswers[index]['topAnswer']['text'] = text;
                        //make sure to update upvotesCount
                        _myAnswers[index]['volunteerAnswer']['upvotesCount'] =
                            0;
                      });
                      _refreshQuestion(index);
                    },
                  );
                },
              ),
    );
  }

Widget _buildFavoritesTab() {
  final filteredFavorites =
      _favoriteQuestions.where((q) => q['isFlagged'] != true).toList();

  return Padding(
    padding: EdgeInsets.all(16),
    child: filteredFavorites.isEmpty
        ? _buildEmptyState(
            'No favorite questions',
            'Save questions you find helpful',
          )
        : ListView.builder(
            controller: _favoritesScrollController,
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              final question = filteredFavorites[index];

                             return QuestionCard(
                 question: question,
                 onReportSuccess: () {
                   if (!mounted) return;
                   setState(() {
                     final id = question['questionId'] ?? question['_id'];
                     final originalIndex = _favoriteQuestions.indexWhere(
                       (q) => (q['questionId'] ?? q['_id']) == id,
                     );
                     if (originalIndex != -1) {
                       _favoriteQuestions[originalIndex]['isFlagged'] = true;
                     }
                   });
                 },
                 onReportAnswerSuccess: () {
                   if (!mounted) return;
                   setState(() {
                     final id = question['questionId'] ?? question['_id'];
                     final originalIndex = _favoriteQuestions.indexWhere(
                       (q) => (q['questionId'] ?? q['_id']) == id,
                     );
                     if (originalIndex != -1) {
                       if (_favoriteQuestions[originalIndex]['topAnswer'] == null) {
                         _favoriteQuestions[originalIndex]['topAnswer'] = {};
                       }
                       _favoriteQuestions[originalIndex]['topAnswer']['isFlagged'] = true;
                       
                       // Force immediate UI update
                       _favoriteQuestions[originalIndex] = {
                         ..._favoriteQuestions[originalIndex],
                         'lastModified': DateTime.now().millisecondsSinceEpoch,
                       };
                     }
                   });
                   refreshAllTabs();
                 },
                onUpdate: (updatedFields) {
                if (!mounted) return;
                 setState(() {
                final questionId = filteredFavorites[index]['questionId'] ??
               filteredFavorites[index]['_id'];

                 final originalIndex = _favoriteQuestions.indexWhere(
                  (q) => (q['questionId'] ?? q['_id']) == questionId,
                    );

               if (originalIndex != -1) {
                _favoriteQuestions[originalIndex].addAll(updatedFields);
               }
              });
             refreshAllTabs();
               },
                 onRefresh: refreshAllTabs,
               );
            },
          ),
  );
}

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer, size: 64, color: Color(0xFF93C5AE)),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF104C34),
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Color(0xFF206F4F)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper to update AI answer on backend
  Future<void> updateAIAnswerOnBackend(
    String questionId,
    String aiAnswer,
  ) async {
    final token = await AuthUtils.getValidToken(context);
    if (token == null) return;
    await http.patch(
      Uri.parse('$questions/$questionId/ai-answer'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"aiAnswer": aiAnswer}),
    );
  }

  // Helper to retry pending AI answers
  Future<void> retryPendingAIs(List<Map<String, dynamic>> questions) async {
    for (var q in questions) {
      if (q['aiAnswer'] == 'pending') {
        final newAnswer = await generateAIAnswerGemini(q['text']);
        if (newAnswer.trim().isNotEmpty && newAnswer != 'pending') {
          q['aiAnswer'] = newAnswer;
          await updateAIAnswerOnBackend(q['questionId'], newAnswer);
        }
      }
    }
  }

  Future<void> _refreshQuestion(int index) async {
    final questionId = _myAnswers[index]['question']['questionId'];
    final response = await http.get(
      Uri.parse('$questions/$questionId'),
      headers: {'Content-Type': 'application/json'},
    );
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final updatedQuestion = jsonDecode(response.body);
      print(' 😭😭😭😭 Updated question: $updatedQuestion');
      setState(() {
        //_myAnswers[index]['question'] = updatedQuestion;
        _myAnswers[index]['topAnswer'] = updatedQuestion['topAnswer'];
      });
    }
  }
   

   




  
}

Future<String?> generateAIAnswerGemini(String questionText) async {
  final prompt = '''
Provide a concise, clear Islamic answer to the following question.
Use proper spacing between all words and punctuation.
Format the response in a clear, readable manner with correct grammar and spacing.
Question: "$questionText"
''';

  StringBuffer buffer = StringBuffer();
  final completer = Completer<String>();
  String previousOutput = '';

  try {
      print("DEBUG >>> Starting promptStream call...");
    Gemini.instance
        .promptStream(parts: [Part.text(prompt)])
        .listen(
          (value) {
            if (value?.output != null) {
              final current = value?.output?.trim() ?? '';
              final lastChar =
                  previousOutput.isNotEmpty
                      ? previousOutput[previousOutput.length - 1]
                      : '';

              // Add a space if needed
              if (lastChar.isNotEmpty &&
                  !lastChar.contains(RegExp(r'[ \n\r\t.,;:!?(){}\[\]]')) &&
                  !current.startsWith(RegExp(r'[ \n\r\t.,;:!?(){}\[\]]'))) {
                buffer.write(' ');
              }

              buffer.write(current);
              previousOutput = current;
            }
          },
          onDone: () {
                    print("DEBUG >>> Final buffer: ${buffer.toString()}");
            if (!completer.isCompleted) {
              completer.complete(buffer.toString());
            }
          },
          onError: (e) {
            print('Error fetching AI answer from Gemini: $e');
            if (!completer.isCompleted) {
              completer.complete('');
            }
          },
        );

    return await completer.future;
  } catch (e) {
    print("error extracting tags: $e");
    return null;
  }
}
