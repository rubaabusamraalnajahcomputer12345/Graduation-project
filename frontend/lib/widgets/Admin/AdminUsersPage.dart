import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/widgets/CertificationViewer.dart';

// Islamic Theme Colors matching the web design
class IslamicColors {
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF059669);
  static const Color green600 = Color(0xFF047857);
  static const Color green700 = Color(0xFF065F46);
  static const Color green800 = Color(0xFF064E3B);

  static const Color cream = Color(0xFFFAF9F6);
  static const Color white = Color(0xFFFFFFFF);
}

// User Model
class User {
  final String id;
  final String userId;
  final String displayName;
  final String gender;
  final String email;
  final String role;
  final String country;
  final String language;
  final List<String> savedQuestions;
  final List<String> savedLessons;
  final DateTime createdAt;
  final List<Map<String, dynamic>> notifications;
  final String aiSessionId;
  final bool isEmailVerified;
  final List<String> likedStories;
  final List<String> savedStories;
  final Map<String, dynamic>? volunteerProfile;
  final int questionsAsked;
  final int questionsAnswered;

  User({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.gender,
    required this.email,
    required this.role,
    required this.country,
    required this.language,
    required this.savedQuestions,
    required this.savedLessons,
    required this.createdAt,
    required this.notifications,
    required this.aiSessionId,
    required this.isEmailVerified,
    required this.likedStories,
    required this.savedStories,
    this.volunteerProfile,
    required this.questionsAsked,
    required this.questionsAnswered,
  });

  // Helper getter for joinedAt (alias for createdAt)
  DateTime get joinedAt => createdAt;

  // Helper getter for isActive (always true for existing users)
  bool get isActive => true;

  // Factory constructor to create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      savedQuestions: List<String>.from(json['savedQuestions'] ?? []),
      savedLessons: List<String>.from(json['savedLessons'] ?? []),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now(),
      notifications: List<Map<String, dynamic>>.from(
        json['notifications'] ?? [],
      ),
      aiSessionId: json['ai_session_id']?.toString() ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
      likedStories: List<String>.from(json['likedStories'] ?? []),
      savedStories: List<String>.from(json['savedStories'] ?? []),
      volunteerProfile:
          json['volunteerProfile'] != null
              ? Map<String, dynamic>.from(json['volunteerProfile'])
              : null,
      questionsAsked: json['questionsAsked'] ?? 0,
      questionsAnswered: json['questionsAnswered'] ?? 0,
    );
  }
}

// Volunteer Application Model
class VolunteerApplication {
  final String id;
  final String name;
  final String email;
  final String country;
  final List<String> languages;
  final String bio;
  final String status;
  final DateTime appliedAt;
  final Map<String, dynamic>? certificate; // Add certificate field

  VolunteerApplication({
    required this.id,
    required this.name,
    required this.email,
    required this.country,
    required this.languages,
    required this.bio,
    required this.status,
    required this.appliedAt,
    this.certificate, // Add certificate parameter
  });
}

// Main Users Management Page
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _countryFilter = 'all';
  String _languageFilter = 'all';

  // Edit user form controllers
  final _editFormKey = GlobalKey<FormState>();
  TextEditingController? _usernameController;
  TextEditingController? _emailController;
  String? _gender;
  TextEditingController? _countryController;
  TextEditingController? _languageController;
  TextEditingController? _bioController;

  // Volunteer-specific controllers
  TextEditingController? _certTitleController;
  TextEditingController? _certInstitutionController;
  TextEditingController? _spokenLanguagesController;

  // File handling
  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;

  // Search states
  List<String> _searchedCountries = [];
  bool _isSearchingCountry = false;
  List<String> _searchedLanguages = [];
  bool _isSearchingLanguage = false;
  List<String> _searchedSpokenLanguages = [];
  bool _isSearchingSpokenLanguages = false;
  List<String> _selectedSpokenLanguages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize users with mock data
    _initializeUsers();
    fetchAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose controllers if they are initialized
    _usernameController?.dispose();
    _emailController?.dispose();
    _countryController?.dispose();
    _languageController?.dispose();
    _bioController?.dispose();
    _certTitleController?.dispose();
    _certInstitutionController?.dispose();
    _spokenLanguagesController?.dispose();
    super.dispose();
  }

  // Initialize users with mock data
  void _initializeUsers() {
    setState(() {
      users = [
        User(
          id: "1",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142da5",
          displayName: "Ahmad Hassan",
          gender: "Male",
          email: "ahmad.hassan@email.com",
          role: "certified_volunteer",
          country: "Saudi Arabia",
          language: "Arabic",
          savedQuestions: [
            "9a2d4518-74da-4c51-ab5c-bc6c402bd11d",
            "7eb947f0-7b59-43f7-8676-3e1714f99921",
          ],
          savedLessons: ["lesson1", "lesson2"],
          createdAt: DateTime(2024, 1, 15),
          notifications: [
            {
              "id": "7db9985f-2e43-4590-8f71-0d9733c047fd",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Ahmad! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "af7763a2-affc-4a94-aa3c-61142462712f",
          isEmailVerified: true,
          likedStories: ["story1", "story2"],
          savedStories: ["story3"],
          volunteerProfile: {
            'bio': 'Islamic studies graduate with 5 years teaching experience.',
            'languages': ['Arabic', 'English'],
            'certificate': {
              'title': 'Quran Recitation Level 1',
              'institution': 'Sheikh Ahmad Al-Mansour',
              'url':
                  'https://mdkcqahrvtfgdhpvblfk.supabase.co/storage/v1/object/public/certifications/Screenshot%202025-07-21%20225732.png',
              'uploadedAt': DateTime.now().toIso8601String(),
              '_id': 'cert1_id',
            },
            '_id': 'volunteer1_profile_id',
          },
          questionsAsked: 2,
          questionsAnswered: 5,
        ),
        User(
          id: "2",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142da6",
          displayName: "Fatima Al-Zahra",
          gender: "Female",
          email: "fatima.zahra@email.com",
          role: "user",
          country: "Lebanon",
          language: "Arabic",
          savedQuestions: [
            "8b3e5629-85eb-5d62-bc7d-cd7d513ce022",
            "9f4c6730-96fc-6e73-cd8e-de8e624df133",
          ],
          savedLessons: ["lesson3"],
          createdAt: DateTime(2024, 2, 20),
          notifications: [
            {
              "id": "8ecaa96g-3f54-4601-9f82-1e0844d158ge",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Fatima! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "bf8874b3-bggd-5b05-bb4d-72253573823g",
          isEmailVerified: false,
          likedStories: ["story4"],
          savedStories: [],
          volunteerProfile: null,
          questionsAsked: 2,
          questionsAnswered: 0,
        ),
        User(
          id: "3",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142da7",
          displayName: "Muhammad Khan",
          gender: "Male",
          email: "muhammad.khan@email.com",
          role: "certified_volunteer",
          country: "Pakistan",
          language: "Urdu",
          savedQuestions: [
            "7c2d4518-74da-4c51-ab5c-bc6c402bd11e",
            "8d3e5629-85eb-5d62-bc7d-cd7d513ce023",
          ],
          savedLessons: ["lesson4", "lesson5", "lesson6"],
          createdAt: DateTime(2024, 1, 10),
          notifications: [
            {
              "id": "9fdbb07h-4g65-5712-0g93-2f1955e269hf",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Muhammad! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "cg9985c4-chhe-6c16-cc5e-83364684934h",
          isEmailVerified: true,
          likedStories: ["story5", "story6", "story7"],
          savedStories: ["story8"],
          volunteerProfile: {
            'bio': 'Community imam with expertise in Islamic jurisprudence.',
            'languages': ['English', 'Hausa'],
            'certificate': {
              'title': 'Islamic Studies Diploma',
              'institution': 'Al-Azhar University',
              'url': 'https://example.com/cert2',
              'uploadedAt': DateTime.now().toIso8601String(),
              '_id': 'cert2_id',
            },
            '_id': 'volunteer2_profile_id',
          },
          questionsAsked: 2,
          questionsAnswered: 8,
        ),
        User(
          id: "4",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142da8",
          displayName: "Sarah Johnson",
          gender: "Female",
          email: "sarah.johnson@email.com",
          role: "user",
          country: "United States",
          language: "English",
          savedQuestions: [
            "6b1c3407-63c9-3b40-9a4b-ab4b301ac00c",
            "7c2d4518-74da-4c51-ab5c-bc6c402bd11d",
            "8d3e5629-85eb-5d62-bc7d-cd7d513ce022",
          ],
          savedLessons: ["lesson7", "lesson8"],
          createdAt: DateTime(2024, 3, 5),
          notifications: [
            {
              "id": "0gecc18i-5h76-6823-1h04-3g2066f370ig",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Sarah! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "dh1106d5-diif-7d27-dd6f-94475795045i",
          isEmailVerified: true,
          likedStories: ["story9"],
          savedStories: ["story10", "story11"],
          volunteerProfile: null,
          questionsAsked: 3,
          questionsAnswered: 0,
        ),
        User(
          id: "5",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142da9",
          displayName: "Ali Rahman",
          gender: "Male",
          email: "ali.rahman@email.com",
          role: "admin",
          country: "Malaysia",
          language: "English",
          savedQuestions: ["5a0b2306-52b8-2a2f-893a-9a2a2009bffb"],
          savedLessons: ["lesson9"],
          createdAt: DateTime(2023, 12, 1),
          notifications: [
            {
              "id": "1hfdd29j-6i87-7934-2i15-4h3177g481jh",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Ali! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "ei2217e6-ejjg-8e38-ee7g-05586806156j",
          isEmailVerified: true,
          likedStories: ["story12"],
          savedStories: [],
          volunteerProfile: null,
          questionsAsked: 1,
          questionsAnswered: 0,
        ),
        User(
          id: "6",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142daa",
          displayName: "Omar Ibrahim",
          gender: "Male",
          email: "omar.ibrahim@email.com",
          role: "user",
          country: "Egypt",
          language: "Arabic",
          savedQuestions: [
            "4z9a1205-41a7-191e-7829-8919190f8eea",
            "5a0b2306-52b8-2a2f-893a-9a2a2009bffb",
            "6b1c3407-63c9-3b40-9a4b-ab4b301ac00c",
          ],
          savedLessons: ["lesson10"],
          createdAt: DateTime(2024, 4, 12),
          notifications: [
            {
              "id": "2igee30k-7j98-8045-3j26-5i4288h592ik",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Omar! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "fj3328f7-fkkh-9f49-ff8h-16697917267k",
          isEmailVerified: false,
          likedStories: ["story13", "story14"],
          savedStories: ["story15"],
          volunteerProfile: null,
          questionsAsked: 3,
          questionsAnswered: 0,
        ),
        User(
          id: "7",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142dab",
          displayName: "Zainab Ahmed",
          gender: "Female",
          email: "zainab.ahmed@email.com",
          role: "certified_volunteer",
          country: "Morocco",
          language: "Arabic",
          savedQuestions: ["3y8z0104-30z6-080d-6718-7808080e7dd9"],
          savedLessons: ["lesson11", "lesson12"],
          createdAt: DateTime(2024, 2, 28),
          notifications: [
            {
              "id": "3jhff41l-8k09-9156-4k37-6j5399i703jl",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Zainab! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "gk4439g8-glli-0g50-gg9i-27708028378l",
          isEmailVerified: true,
          likedStories: ["story16"],
          savedStories: ["story17", "story18"],
          volunteerProfile: {
            'bio': 'Islamic studies graduate with 5 years teaching experience.',
            'languages': ['Arabic', 'English'],
            'certificate': {
              'title': 'Quran Recitation Level 1',
              'institution': 'Sheikh Ahmad Al-Mansour',
              'url': 'https://example.com/cert3',
              'uploadedAt': DateTime.now().toIso8601String(),
              '_id': 'cert3_id',
            },
            '_id': 'volunteer3_profile_id',
          },
          questionsAsked: 1,
          questionsAnswered: 12,
        ),
        User(
          id: "8",
          userId: "da2fc1c0-6b06-4961-a6c4-92336d142dac",
          displayName: "Abdullah Malik",
          gender: "Male",
          email: "abdullah.malik@email.com",
          role: "user",
          country: "Turkey",
          language: "Turkish",
          savedQuestions: ["2x7y9f03-2fy5-f7c-5607-67f7f7f6cc8"],
          savedLessons: [],
          createdAt: DateTime(2024, 5, 15),
          notifications: [
            {
              "id": "4kigg52m-9l10-0267-5l48-7k6400j814km",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello Abdullah! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "hl5540h9-hmmj-1h61-hh0j-38819139489m",
          isEmailVerified: false,
          likedStories: [],
          savedStories: [],
          volunteerProfile: null,
          questionsAsked: 1,
          questionsAnswered: 0,
        ),
        User(
          id: "5",
          userId: "91a80781-3817-48b0-8db9-c9011737bf06",
          displayName: "volunteer1",
          gender: "Female",
          email: "Volunteer1@gmail.com",
          role: "certified_volunteer",
          country: "British Indian Ocean Territory",
          language: "Chinese",
          savedQuestions: ["abc123", "c48337dd-eb10-4c3d-b6d3-5c246b40bd62"],
          savedLessons: [],
          createdAt: DateTime(2025, 7, 20),
          notifications: [
            {
              "id": "test_notification_id",
              "type": "welcome",
              "title": "Welcome to Hidaya! 🎉",
              "message": "Hello volunteer1! Welcome to Hidaya!",
              "read": false,
              "createdAt": DateTime.now().toIso8601String(),
            },
          ],
          aiSessionId: "63ae7fae-afe0-4357-8011-08a584b13b3c",
          isEmailVerified: true,
          likedStories: [],
          savedStories: [],
          volunteerProfile: {
            'certificate': {
              'title': 'Updated Certificate Test2',
              'institution': 'Updated Institution Test2',
              'url':
                  'https://mdkcqahrvtfgdhpvblfk.supabase.co/storage/v1/object/public/certifications/1.Introduction%20to%20Management%20Process.pdf',
              'uploadedAt': DateTime(2025, 7, 10).toIso8601String(),
              '_id': '686f3475ee269d62fe941e1c',
            },
            'languages': ['Afrikaans', 'Bihari', 'Azerbaijani', 'Abkhaz'],
            'bio': 'This is the volunteer bio uptodate',
            '_id': '686f3475ee269d62fe941e1b',
          },
          questionsAsked: 2,
          questionsAnswered: 1,
        ),
      ];
    });
  }

  Future<void> fetchAllUsers() async {
    try {
      final uri = Uri.parse(allUsersUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (responseData.containsKey('usersdata') &&
            responseData['usersdata'] is List) {
          final List<dynamic> usersData = responseData['usersdata'];
          if (mounted) {
            setState(() {
              users =
                  usersData.map((userData) => User.fromJson(userData)).toList();
            });
          }
          print("users fetched successfully ${users.length} users");
        } else {
          print("Invalid response structure: ${response.body}");
        }
      } else {
        print(
          "error in fetching all users here ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      print("error in fetching all users $e");
    }
  }

  // Search functions for countries and languages
  Future<void> searchCountries(
    String query,
    void Function(void Function()) setState,
  ) async {
    if (query.isEmpty) {
      setState(() {
        _searchedCountries = [];
        _isSearchingCountry = false;
      });
      return;
    }
    setState(() {
      _isSearchingCountry = true;
    });
    final response = await http.get(
      Uri.parse('https://restcountries.com/v3.1/name/$query'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final countryNames =
          data
              .map<String>((item) => item['name']['common'].toString())
              .toList();
      countryNames.sort();
      setState(() {
        _searchedCountries = countryNames;
        _isSearchingCountry = false;
      });
    } else {
      setState(() {
        _searchedCountries = [];
        _isSearchingCountry = false;
      });
    }
  }

  Future<void> searchLanguages(
    String query,
    void Function(void Function()) setState,
  ) async {
    if (query.isEmpty) {
      setState(() {
        _searchedLanguages = [];
        _isSearchingLanguage = false;
      });
      return;
    }
    setState(() {
      _isSearchingLanguage = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/haliaeetus/iso-639/master/data/iso_639-1.json',
      ),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<String> languages = [];
      data.forEach((code, lang) {
        final name = lang['name']?.toString() ?? '';
        if (name.toLowerCase().contains(query.toLowerCase())) {
          languages.add(name);
        }
      });
      languages.sort();
      setState(() {
        _searchedLanguages = languages;
        _isSearchingLanguage = false;
      });
    } else {
      setState(() {
        _searchedLanguages = [];
        _isSearchingLanguage = false;
      });
    }
  }

  Future<void> searchSpokenLanguages(
    String query,
    void Function(void Function()) setState,
  ) async {
    if (query.isEmpty) {
      setState(() {
        _searchedSpokenLanguages = [];
        _isSearchingSpokenLanguages = false;
      });
      return;
    }
    setState(() {
      _isSearchingSpokenLanguages = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/haliaeetus/iso-639/master/data/iso_639-1.json',
      ),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<String> languages = [];
      data.forEach((code, lang) {
        final name = lang['name']?.toString() ?? '';
        if (name.toLowerCase().contains(query.toLowerCase())) {
          languages.add(name);
        }
      });
      languages.sort();
      setState(() {
        _searchedSpokenLanguages = languages;
        _isSearchingSpokenLanguages = false;
      });
    } else {
      setState(() {
        _searchedSpokenLanguages = [];
        _isSearchingSpokenLanguages = false;
      });
    }
  }

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

  Future<String> uploadFile(file) async {
    Uint8List? fileBytes;
    final fileName = file.name;
    // Platform-safe file bytes access
    if (file.bytes != null) {
      fileBytes = file.bytes;
    } else if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
    }

    if (fileBytes == null) {
      print('❌ Unable to read file bytes');
      return '';
    }
    try {
      final response = await Supabase.instance.client.storage
          .from('certifications') // ✅ use same bucket
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isNotEmpty) {
        print('Upload successful');

        final publicUrl = Supabase.instance.client.storage
            .from('certifications') // ✅ use same bucket
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

  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        // User was logged out due to expired token
        return;
      }

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Use the new admin edit user endpoint
      final userId = updatedData['id'] ?? updatedData['userId'] ?? '';

      if (userId.isEmpty) {
        print("Error: No user ID found in updatedData");
        return;
      }

      var request = http.Request('PUT', Uri.parse(adminEditUserUrl));

      // Build request body based on user role
      Map<String, dynamic> requestBody = {
        "userId": userId,
        "displayName": updatedData['displayName'],
        "gender": updatedData['gender'],
        "email": updatedData['email'],
        "country": updatedData['country'],
        "language": updatedData['language'],
        "role": updatedData['role'],
      };

      // Add role-specific fields
      String role = updatedData['role'] as String? ?? '';
      if (role == 'certified_volunteer' ||
          role == 'volunteer_pending' ||
          role == 'volunteer') {
        // Volunteer-specific fields - handle both old and new structure
        if (updatedData['volunteerProfile'] != null) {
          // New structure with volunteerProfile
          final volunteerProfile =
              updatedData['volunteerProfile'] as Map<String, dynamic>;
          requestBody["bio"] = volunteerProfile['bio'] ?? '';
          requestBody["spoken_languages"] = volunteerProfile['languages'] ?? [];

          final certificate =
              volunteerProfile['certificate'] as Map<String, dynamic>?;
          requestBody["certification_title"] = certificate?['title'] ?? '';
          requestBody["certification_institution"] =
              certificate?['institution'] ?? '';
          requestBody["certification_url"] = certificate?['url'] ?? '';
        } else {
          // Fallback to old structure
          requestBody["bio"] = updatedData['bio'] ?? '';
          requestBody["spoken_languages"] =
              updatedData['languagesSpoken'] ?? [];

          final certificate =
              updatedData['certificate'] as Map<String, dynamic>?;
          requestBody["certification_title"] = certificate?['title'] ?? '';
          requestBody["certification_institution"] =
              certificate?['institution'] ?? '';
          requestBody["certification_url"] = certificate?['url'] ?? '';
        }
      }

      request.body = json.encode(requestBody);
      request.headers.addAll(headers);

      print("=== FRONTEND ADMIN EDIT DEBUG ===");
      print("Request URL: $adminEditUserUrl");
      print("Request body: $requestBody");
      print("User ID being updated: $userId");

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print(responseBody);

        // Success: update userObj with returned user info
        final responseData = jsonDecode(responseBody);
        final updatedUser = responseData['user']; // Extract user from response

        // Transform the API response to match frontend structure
        final transformedUser = {
          'id': updatedUser['userId'] ?? updatedUser['_id'],
          'displayName': updatedUser['displayName'],
          'email': updatedUser['email'],
          'role': updatedUser['role'],
          'gender': updatedUser['gender'],
          'country': updatedUser['country'],
          'language': updatedUser['language'],
          'volunteerProfile': updatedUser['volunteerProfile'],
          'savedQuestions': updatedUser['savedQuestions'] ?? [],
          'savedLessons': updatedUser['savedLessons'] ?? [],
        };

        // Only add bio field for non-volunteer users
        if (updatedUser['role'] == 'user' || updatedUser['role'] == 'admin') {
          transformedUser['bio'] = updatedUser['bio'] ?? '';
        }

        // Update the users list with the transformed data
        setState(() {
          final index = users.indexWhere(
            (u) => u.userId == transformedUser['id'],
          );
          if (index != -1) {
            // Create a new User object with updated data
            final updatedUserObj = User(
              id: users[index].id,
              userId: transformedUser['id'],
              displayName: transformedUser['displayName'],
              gender: transformedUser['gender'],
              email: transformedUser['email'],
              role: transformedUser['role'],
              country: transformedUser['country'],
              language: transformedUser['language'],
              savedQuestions: List<String>.from(
                transformedUser['savedQuestions'],
              ),
              savedLessons: List<String>.from(transformedUser['savedLessons']),
              createdAt: users[index].createdAt, // Keep original creation date
              notifications:
                  users[index].notifications, // Keep original notifications
              aiSessionId:
                  users[index].aiSessionId, // Keep original AI session ID
              isEmailVerified:
                  updatedUser['isEmailVerified'] ??
                  users[index].isEmailVerified,
              likedStories:
                  users[index].likedStories, // Keep original liked stories
              savedStories:
                  users[index].savedStories, // Keep original saved stories
              volunteerProfile: transformedUser['volunteerProfile'],
              questionsAsked: users[index].questionsAsked,
              questionsAnswered: users[index].questionsAnswered,
            );

            // Replace the user in the list
            users[index] = updatedUserObj;
          }
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User profile updated successfully by admin!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print(response.reasonPhrase);
        // Handle error: show an error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
      }
    } catch (e) {
      print('Exception in updateProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while updating the profile.'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // Helper method to get bio value from User object
  String _getBioValueFromUser(User user) {
    if (user.volunteerProfile != null) {
      return user.volunteerProfile!['bio']?.toString() ?? '';
    }
    return '';
  }

  // Helper method to get volunteer field value from User object
  String _getVolunteerFieldFromUser(User user, String fieldPath) {
    if (user.volunteerProfile == null) {
      return '';
    }

    final volunteerProfile = user.volunteerProfile!;

    if (fieldPath.contains('.')) {
      final parts = fieldPath.split('.');
      final mainField = parts[0];
      final subField = parts[1];

      if (volunteerProfile[mainField] != null) {
        final subObject = volunteerProfile[mainField] as Map<String, dynamic>?;
        return subObject?[subField]?.toString() ?? '';
      }
    } else {
      return volunteerProfile[fieldPath]?.toString() ?? '';
    }

    return '';
  }

  // Helper method to get volunteer languages from User object
  List<String> _getVolunteerLanguagesFromUser(User user) {
    if (user.volunteerProfile == null) {
      return [];
    }

    final volunteerProfile = user.volunteerProfile!;
    final languages = volunteerProfile['languages'] as List<dynamic>?;

    if (languages != null) {
      return languages.map((lang) => lang.toString()).toList();
    }

    return [];
  }

  Future<void> updateUserProfile(Map<String, dynamic> updatedData) async {
    final token = await AuthUtils.getValidToken(context);
    if (token == null) {
      return;
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var request = http.Request('PUT', Uri.parse(profile));

    // Build request body based on user role
    Map<String, dynamic> requestBody = {
      "displayName": updatedData['displayName'],
      "gender": updatedData['gender'],
      "email": updatedData['email'],
      "country": updatedData['country'],
      "language": updatedData['language'],
      "role": updatedData['role'],
    };

    // Add role-specific fields
    String role = updatedData['role'] as String? ?? '';
    if (role == 'certified_volunteer' ||
        role == 'volunteer_pending' ||
        role == 'volunteer') {
      // Volunteer-specific fields - handle both old and new structure
      if (updatedData['volunteerProfile'] != null) {
        // New structure with volunteerProfile
        final volunteerProfile =
            updatedData['volunteerProfile'] as Map<String, dynamic>;
        requestBody["bio"] = volunteerProfile['bio'] ?? '';
        requestBody["spoken_languages"] = volunteerProfile['languages'] ?? [];

        final certificate =
            volunteerProfile['certificate'] as Map<String, dynamic>?;
        requestBody["certification_title"] = certificate?['title'] ?? '';
        requestBody["certification_institution"] =
            certificate?['institution'] ?? '';
        requestBody["certification_url"] = certificate?['url'] ?? '';
      } else {
        // Fallback to old structure
        requestBody["bio"] = updatedData['bio'] ?? '';
        requestBody["spoken_languages"] = updatedData['languagesSpoken'] ?? [];

        final certificate = updatedData['certificate'] as Map<String, dynamic>?;
        requestBody["certification_title"] = certificate?['title'] ?? '';
        requestBody["certification_institution"] =
            certificate?['institution'] ?? '';
        requestBody["certification_url"] = certificate?['url'] ?? '';
      }
    }

    request.body = json.encode(requestBody);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print(responseBody);

      // Success: update the user in the local list
      final responseData = jsonDecode(responseBody);
      final updatedUser = responseData['user'];

      // Update the user in the local list
      setState(() {
        final index = users.indexWhere(
          (u) => u.id == updatedUser['userId'] ?? updatedUser['_id'],
        );
        if (index != -1) {
          // Update the user object with new data
          final user = users[index];
          // Note: In a real app, you'd want to update the User model properly
          // For now, we'll just show a success message
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      print(response.reasonPhrase);
      // Handle error: show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // State variable for users
  List<User> users = [];

  // Getter to filter pending volunteers from users
  List<User> get pendingVolunteers =>
      users.where((user) => user.role == "volunteer_pending").toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.green50,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              IslamicColors.green50,
              IslamicColors.cream,
              Color(0xFFFFFBEB), // Islamic gold 50
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildNavigationTabs(),
                const SizedBox(height: 24),
                _buildContentArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: IslamicColors.green800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage all users, volunteers, and administrators',
              style: TextStyle(fontSize: 16, color: IslamicColors.green600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: IslamicColors.green600,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize:
            TabBarIndicatorSize.tab, // ✅ Makes indicator full tab width
        labelColor: Colors.white, // ✅ To contrast with green background
        unselectedLabelColor: Colors.grey[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          const Tab(text: 'All Users'),
          const Tab(text: 'Volunteers'),
          Tab(text: 'Applications (${pendingVolunteers.length})'),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          '${users.length}',
          Icons.people,
          IslamicColors.green600,
        ),
        _buildStatCard(
          'Volunteers',
          '${users.where((u) => u.role == "certified_volunteer").length}',
          Icons.verified_user,
          Colors.green[600]!,
        ),
        _buildStatCard(
          'Admins',
          '${users.where((u) => u.role == "admin").length}',
          Icons.star,
          Colors.red[600]!,
        ),
        _buildStatCard(
          'Pending Applications',
          '${pendingVolunteers.length}',
          Icons.people,
          Colors.blue[600]!,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IslamicColors.green100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: IslamicColors.green800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IslamicColors.green100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: IslamicColors.green100)),
            ),
            child: Row(
              children: [
                Text(
                  _getTabTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: IslamicColors.green800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 500, // Set a fixed height for TabBarView
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersTable(),
                      _buildVolunteersTable(),
                      _buildApplicationsTable(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_tabController.index) {
      case 0:
        return 'All Users';
      case 1:
        return 'Certified Volunteers';
      case 2:
        return 'Volunteer Applications';
      default:
        return 'All Users';
    }
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: IslamicColors.green200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterDropdown('Role', _roleFilter, [
                'all',
                'user',
                'certified_volunteer',
                'admin',
              ], (value) => setState(() => _roleFilter = value)),
              const SizedBox(width: 16),
              _buildFilterDropdown(
                'Country',
                _countryFilter,
                [
                  'all',
                  'Saudi Arabia',
                  'Lebanon',
                  'Pakistan',
                  'United States',
                  'Malaysia',
                  'Egypt',
                  'Morocco',
                  'Turkey',
                ],
                (value) => setState(() => _countryFilter = value),
              ),
              const SizedBox(width: 16),
              _buildFilterDropdown(
                'Language',
                _languageFilter,
                ['all', 'English', 'Arabic', 'Urdu', 'Turkish'],
                (value) => setState(() => _languageFilter = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: IslamicColors.green200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (newValue) => onChanged(newValue!),
          icon: const Icon(Icons.filter_list, size: 16),
          items:
              options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option == 'all' ? 'All $label' : _formatOption(option),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  String _formatOption(String option) {
    if (option == 'certified_volunteer') return 'Volunteer';
    return option.split('_').map((word) => word.capitalize()).join(' ');
  }

  Widget _buildUsersTable() {
    final filteredUsers = _getFilteredUsers();

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: IslamicColors.green100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(IslamicColors.green50),
            columns: const [
              DataColumn(
                label: Text(
                  'User',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Country',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Language',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Joined',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Activity',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Verified',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows:
                filteredUsers
                    .map((user) => _buildUserRow(user))
                    .whereType<DataRow>()
                    .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteersTable() {
    final volunteers =
        users.where((u) => u.role == "certified_volunteer").toList();

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: IslamicColors.green100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(IslamicColors.green50),
            columns: const [
              DataColumn(
                label: Text(
                  'Volunteer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Country',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Language',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Text(
                    'Bio',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Certificate Title',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Certificate URL',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows: volunteers.map((user) => _buildVolunteerRow(user)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: IslamicColors.green100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(IslamicColors.green50),
            columns: const [
              DataColumn(
                label: Text(
                  'Applicant',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Country',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Language',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              DataColumn(
                label: Text(
                  'Applied',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Review Application',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows:
                pendingVolunteers
                    .map((user) => _buildPendingVolunteerRow(user))
                    .toList(),
          ),
        ),
      ),
    );
  }

  DataRow? _buildUserRow(User user) {
    if (user.role == 'volunteer_pending') {
      return null;
    }
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(
                  user.displayName.split(' ').map((n) => n[0]).join(''),
                  style: TextStyle(
                    color: const Color(0xFF1565C0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(_buildRoleBadge(user.role)),
        DataCell(Text(user.country)),
        DataCell(Text(user.language)),
        DataCell(Text(_formatDate(user.joinedAt))),
        DataCell(
          user.role == "user"
              ? Text(
                'Questions: ${user.questionsAsked}',
                style: const TextStyle(fontSize: 12),
              )
              : Text(
                'Answers: ${user.questionsAnswered}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
        ),

        DataCell(
          Icon(
            user.isEmailVerified ? Icons.check_circle : Icons.error,
            color:
                user.isEmailVerified
                    ? IslamicColors.green600
                    : const Color.fromARGB(235, 245, 77, 77),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) => _handleUserAction(value, user),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit User')),

                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete User',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
          ),
        ),
      ],
    );
  }

  DataRow _buildVolunteerRow(User user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                child: Text(
                  user.displayName.split(' ').map((n) => n[0]).join(''),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(user.country)),
        DataCell(Text(user.language)),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              _getBioValueFromUser(user),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ),
        DataCell(Text(_getVolunteerFieldFromUser(user, 'certificate.title'))),
        DataCell(
          _getVolunteerFieldFromUser(user, 'certificate.url').isNotEmpty
              ? InkWell(
                onTap: () {
                  final url = _getVolunteerFieldFromUser(
                    user,
                    'certificate.url',
                  );
                  if (url.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CertificationViewer(fileUrl: url),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No certificate available to view'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: Text(
                  'View Certificate',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
              : Text('No certificate'),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) => _handleUserAction(value, user),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Volunteer'),
                  ),
                ],
          ),
        ),
      ],
    );
  }

  DataRow _buildPendingVolunteerRow(User user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  user.displayName.split(' ').map((n) => n[0]).join(''),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(user.country)),
        DataCell(Text(user.language)),
        DataCell(Text(_formatDate(user.joinedAt))),

        DataCell(
          ElevatedButton(
            onPressed: () => _reviewApplication(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.green600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Review Application',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (role) {
      case 'user':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'User';
        break;
      case 'certified_volunteer':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Volunteer';
        break;
      case 'admin':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Admin';
        break;
      default:
        backgroundColor = const Color.fromARGB(255, 220, 220, 220);
        textColor = Colors.grey[800]!;
        label = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<User> _getFilteredUsers() {
    return users.where((user) {
      final matchesSearch =
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter == 'all' || user.role == _roleFilter;
      final matchesCountry =
          _countryFilter == 'all' || user.country == _countryFilter;
      final matchesLanguage =
          _languageFilter == 'all' || user.language == _languageFilter;

      return matchesSearch && matchesRole && matchesCountry && matchesLanguage;
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _editUser(user);
        break;

      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user.displayName}'),
                Text('Email: ${user.email}'),
                Text('Role: ${user.role}'),
                Text('Country: ${user.country}'),
                Text('Language: ${user.language}'),
                Text('Joined: ${_formatDate(user.joinedAt)}'),
                if (user.role == 'user')
                  Text('Questions Asked: ${user.questionsAsked}'),
                if (user.role == 'certified_volunteer')
                  Text('Answers Given: ${user.questionsAnswered}'),
                if (user.role == 'certified_volunteer')
                  Text('Bio: ${_getBioValueFromUser(user)}', softWrap: true),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _editUser(User user) {
    // Convert User model to Map for the form
    Map<String, dynamic> userObj = {
      'id': user.userId,
      'displayName': user.displayName,
      'email': user.email,
      'role': user.role,
      'gender': user.gender,
      'country': user.country,
      'language': user.language,
      'volunteerProfile': user.volunteerProfile,
      'savedQuestions': user.savedQuestions,
      'savedLessons': user.savedLessons,
      'isEmailVerified': user.isEmailVerified,
      'likedStories': user.likedStories,
      'savedStories': user.savedStories,
    };

    // Initialize controllers with user data
    _usernameController = TextEditingController(text: userObj['displayName']);
    _emailController = TextEditingController(text: userObj['email']);
    _gender = userObj['gender'];
    _countryController = TextEditingController(text: userObj['country']);
    _languageController = TextEditingController(text: userObj['language']);

    // Initialize volunteer-specific controllers
    if (userObj['role'] != 'user') {
      _bioController = TextEditingController(text: _getBioValueFromUser(user));
      _certTitleController = TextEditingController(
        text: _getVolunteerFieldFromUser(user, 'certificate.title'),
      );
      _certInstitutionController = TextEditingController(
        text: _getVolunteerFieldFromUser(user, 'certificate.institution'),
      );
      _spokenLanguagesController = TextEditingController();
      _selectedSpokenLanguages = _getVolunteerLanguagesFromUser(user);
    } else {
      _bioController = TextEditingController();
      _certTitleController = TextEditingController();
      _certInstitutionController = TextEditingController();
      _spokenLanguagesController = TextEditingController();
      _selectedSpokenLanguages = [];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.islamicWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.islamicGreen200),
              ),
              title: Text(
                'Edit User Profile',
                style: TextStyle(
                  color: AppColors.islamicGreen800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 400,
                height: 800,
                child: SingleChildScrollView(
                  child: Form(
                    key: _editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen500,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.islamicWhite,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter user name'
                                      : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen500,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.islamicWhite,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter user email'
                                      : null,
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen500,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.islamicWhite,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                          style: TextStyle(
                            color: AppColors.islamicGreen800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Country input (async, searchable)
                        TextFormField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: 'Country *',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: 'Search for country',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.islamicGreen200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.islamicGreen500,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            suffixIcon:
                                _isSearchingCountry
                                    ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                          onChanged: (value) {
                            searchCountries(value, setState);
                          },
                        ),
                        const SizedBox(height: 8),

                        if (_searchedCountries.isNotEmpty)
                          SizedBox(
                            height: 150,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: AppColors.islamicGreen200,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.islamicGreen500.withAlpha(
                                      30,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: _searchedCountries.length,
                                itemBuilder: (context, index) {
                                  final country = _searchedCountries[index];
                                  return ListTile(
                                    title: Text(
                                      country,
                                      style: TextStyle(
                                        color: AppColors.islamicGreen800,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _countryController?.text = country;
                                        _searchedCountries = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                        SizedBox(height: 12),
                        TextFormField(
                          controller: _languageController,
                          decoration: InputDecoration(
                            labelText: 'Language',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.islamicGreen500,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.islamicWhite,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            searchLanguages(value, setState);
                          },
                        ),
                        if (_searchedLanguages.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.islamicGreen200,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.islamicGreen500.withAlpha(
                                    30,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchedLanguages.length,
                              itemBuilder: (context, index) {
                                final language = _searchedLanguages[index];
                                return ListTile(
                                  title: Text(
                                    language,
                                    style: TextStyle(
                                      color: AppColors.islamicGreen800,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _languageController?.text = language;
                                      _searchedLanguages = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                        SizedBox(height: 12),
                        if (userObj['role'] != 'user') ...[
                          TextFormField(
                            controller: _bioController,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              labelStyle: TextStyle(
                                color: AppColors.islamicGreen700,
                                fontWeight: FontWeight.w500,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.islamicGreen500,
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen500,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.islamicWhite,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            maxLines: 2,
                          ),
                          SizedBox(height: 12),

                          // Spoken Languages
                          TextFormField(
                            controller: _spokenLanguagesController,
                            decoration: InputDecoration(
                              labelText: 'Spoken Languages *',
                              labelStyle: TextStyle(
                                color: AppColors.islamicGreen700,
                                fontWeight: FontWeight.w500,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.islamicGreen500,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: 'Type to search and select languages',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.islamicGreen200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.islamicGreen500,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              suffixIcon:
                                  _isSearchingSpokenLanguages
                                      ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                            onChanged: (value) {
                              searchSpokenLanguages(value, setState);
                            },
                          ),
                          const SizedBox(height: 8),

                          if (_searchedSpokenLanguages.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: AppColors.islamicGreen200,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.islamicGreen500.withAlpha(
                                      30,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchedSpokenLanguages.length,
                                itemBuilder: (context, index) {
                                  final language =
                                      _searchedSpokenLanguages[index];
                                  final alreadySelected =
                                      _selectedSpokenLanguages.contains(
                                        language,
                                      );
                                  return ListTile(
                                    title: Text(
                                      language,
                                      style: TextStyle(
                                        color:
                                            alreadySelected
                                                ? AppColors.islamicGreen400
                                                : AppColors.islamicGreen800,
                                      ),
                                    ),
                                    trailing:
                                        alreadySelected
                                            ? const Icon(
                                              Icons.check,
                                              color: AppColors.islamicGreen400,
                                            )
                                            : null,
                                    onTap: () {
                                      setState(() {
                                        if (!alreadySelected) {
                                          _selectedSpokenLanguages.add(
                                            language,
                                          );
                                        }
                                        _spokenLanguagesController?.clear();
                                        _searchedSpokenLanguages = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),

                          if (_selectedSpokenLanguages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 8,
                                children:
                                    _selectedSpokenLanguages
                                        .map(
                                          (lang) => Chip(
                                            label: Text(lang),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedSpokenLanguages.remove(
                                                  lang,
                                                );
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                          SizedBox(height: 12),

                          // Certificate Title
                          TextFormField(
                            controller: _certTitleController,
                            decoration: InputDecoration(
                              labelText: 'Certification Title',
                              labelStyle: TextStyle(
                                color: AppColors.islamicGreen700,
                                fontWeight: FontWeight.w500,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.islamicGreen500,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: 'e.g., Quran Recitation Level 1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen500,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.islamicWhite,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Certificate Institution
                          TextFormField(
                            controller: _certInstitutionController,
                            decoration: InputDecoration(
                              labelText: 'Certification Institution / Sheikh',
                              labelStyle: TextStyle(
                                color: AppColors.islamicGreen700,
                                fontWeight: FontWeight.w500,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.islamicGreen500,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: 'e.g., Sheikh Ahmad Al-Mansour',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.islamicGreen500,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.islamicWhite,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // File Upload
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await selectFile();
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    _selectedFile != null
                                        ? (_uploadedFileUrl != null
                                            ? 'Uploaded: ${_selectedFile!.name}'
                                            : 'Selected: ${_selectedFile!.name}')
                                        : 'Upload New Certificate',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.islamicGreen400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.islamicGreen600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.islamicGreen500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    elevation: 4,
                    shadowColor: AppColors.islamicGreen600.withAlpha(128),
                  ),
                  onPressed: () async {
                    if (_editFormKey.currentState!.validate()) {
                      // Handle file upload if a new file is selected
                      String certUrl = '';
                      if (userObj['role'] != 'user' && _selectedFile != null) {
                        certUrl = await uploadFile(_selectedFile!);
                        if (certUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to upload certificate'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      setState(() {
                        userObj['userId'] = userObj['userId'];
                        userObj['displayName'] =
                            _usernameController?.text ?? '';
                        userObj['email'] = _emailController?.text ?? '';
                        userObj['gender'] = _gender ?? '';
                        userObj['country'] = _countryController?.text ?? '';
                        userObj['language'] = _languageController?.text ?? '';

                        // Set volunteer-specific fields
                        if (userObj['role'] != 'user') {
                          // For volunteers, save to volunteerProfile
                          if (userObj['volunteerProfile'] != null) {
                            final volunteerProfile =
                                userObj['volunteerProfile']
                                    as Map<String, dynamic>;
                            volunteerProfile['bio'] =
                                _bioController?.text ?? '';
                            volunteerProfile['languages'] =
                                _selectedSpokenLanguages;

                            // Update certificate information
                            if (volunteerProfile['certificate'] != null) {
                              final certificate =
                                  volunteerProfile['certificate']
                                      as Map<String, dynamic>;
                              certificate['title'] =
                                  _certTitleController?.text ?? '';
                              certificate['institution'] =
                                  _certInstitutionController?.text ?? '';
                              if (certUrl.isNotEmpty) {
                                certificate['url'] = certUrl;
                              }
                            } else {
                              volunteerProfile['certificate'] = {
                                'title': _certTitleController?.text ?? '',
                                'institution':
                                    _certInstitutionController?.text ?? '',
                                'url': certUrl.isNotEmpty ? certUrl : '',
                                'uploadedAt': DateTime.now().toIso8601String(),
                                '_id': '',
                              };
                            }
                          } else {
                            // Create volunteerProfile if it doesn't exist
                            userObj['volunteerProfile'] = {
                              'bio': _bioController?.text ?? '',
                              'languages': _selectedSpokenLanguages,
                              'certificate': {
                                'title': _certTitleController?.text ?? '',
                                'institution':
                                    _certInstitutionController?.text ?? '',
                                'url': certUrl.isNotEmpty ? certUrl : '',
                                'uploadedAt': DateTime.now().toIso8601String(),
                                '_id': '',
                              },
                              '_id': '',
                            };
                          }
                        } else if (userObj['role'] == 'user') {
                          // For regular users, save to top-level bio
                          userObj['bio'] = '';
                        }
                      });

                      // Call updateProfile function
                      await updateProfile(userObj);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _upgradeUser(User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upgraded ${user.displayName} to volunteer')),
    );
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.islamicWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.errorRedLight),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.errorRed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete User',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete ${user.displayName}? This action cannot be undone.',
              style: TextStyle(color: AppColors.islamicGreen800, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.islamicGreen600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteUser(user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: AppColors.islamicWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _reviewApplication(User user) {
    final certificate =
        user.volunteerProfile != null
            ? user.volunteerProfile!['certificate'] as Map<String, dynamic>?
            : null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: IslamicColors.green50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: IslamicColors.green100,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_ind,
                        color: IslamicColors.green600,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Volunteer Application',
                              style: TextStyle(
                                color: IslamicColors.green800,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review and approve or reject this volunteer application',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Applicant Information Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: IslamicColors.green50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IslamicColors.green100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: IslamicColors.green600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Applicant Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: IslamicColors.green800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildFullInfoRow('Full Name', user.displayName),
                              _buildFullInfoRow('Email Address', user.email),
                              _buildFullInfoRow('Country', user.country),
                              _buildFullInfoRow('Language', user.language),
                              _buildFullInfoRow(
                                'Bio',
                                _getBioValueFromUser(user),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Certificate Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: IslamicColors.green50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IslamicColors.green100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    color: IslamicColors.green600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Certificate Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: IslamicColors.green800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (certificate != null) ...[
                                _buildFullInfoRow(
                                  'Certificate Title',
                                  certificate['title'] ?? 'N/A',
                                ),
                                _buildFullInfoRow(
                                  'Institution',
                                  certificate['institution'] ?? 'N/A',
                                ),
                                if ((certificate['url'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    CertificationViewer(
                                                      fileUrl:
                                                          certificate['url'],
                                                    ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Certificate File',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: IslamicColors.green600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: Colors.orange[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No certificate provided by the applicant',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer with Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await _rejectVolunteer(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await _approveVolunteer(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IslamicColors.green600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Approve Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for full-width info rows
  Widget _buildFullInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontSize: 14,
                color: value.isEmpty ? Colors.grey[500] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteUser(User user) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        return;
      }

      final response = await http.delete(
        Uri.parse(deletAccounturl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'userId': user.userId, // Send the user ID to delete
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          // Remove user from local list
          setState(() {
            users.removeWhere((u) => u.userId == user.userId);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User ${user.displayName} deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to delete user: ${data['message'] ?? 'Unknown error'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print("Delete failed: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error deleting user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to approve volunteer
  Future<void> _approveVolunteer(User user) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) {
        return;
      }

      final response = await http.post(
        Uri.parse(approveVolunteerUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'volunteerId': user.userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update user role locally
          setState(() {
            final userIndex = users.indexWhere((u) => u.userId == user.userId);
            if (userIndex != -1) {
              users[userIndex] = User(
                id: users[userIndex].id,
                userId: users[userIndex].userId,
                displayName: users[userIndex].displayName,
                gender: users[userIndex].gender,
                email: users[userIndex].email,
                role: 'certified_volunteer', // Update role
                country: users[userIndex].country,
                language: users[userIndex].language,
                savedQuestions: users[userIndex].savedQuestions,
                savedLessons: users[userIndex].savedLessons,
                createdAt: users[userIndex].createdAt,
                notifications: users[userIndex].notifications,
                aiSessionId: users[userIndex].aiSessionId,
                isEmailVerified: users[userIndex].isEmailVerified,
                likedStories: users[userIndex].likedStories,
                savedStories: users[userIndex].savedStories,
                volunteerProfile: users[userIndex].volunteerProfile,
                questionsAsked: users[userIndex].questionsAsked,
                questionsAnswered: users[userIndex].questionsAnswered,
              );
            }
          });

          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Approved ${user.displayName}\'s application'),
                backgroundColor: IslamicColors.green600,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to approve application: ${data['message'] ?? 'Unknown error'}',
                ),
                backgroundColor: Colors.red[600],
              ),
            );
          }
        }
      } else {
        print("Approve failed: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve application. Please try again.'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } catch (e) {
      print("Error approving volunteer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving volunteer: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // Method to reject volunteer
  Future<void> _rejectVolunteer(User user) async {
    try {
      Navigator.of(context).pop();
      // Call the delete user method to remove the rejected volunteer
      await deleteUser(user);
    } catch (e) {
      print("Error rejecting volunteer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting volunteer: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
