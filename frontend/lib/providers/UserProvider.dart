import 'package:flutter/material.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _aiSessionId; // Add AI session ID field

  // Chat session initialization flag

  Map<String, dynamic>? get user => _user;
  List<dynamic> get lessonsProgress =>
      List<dynamic>.from(_user?['lessonsProgress'] ?? []);
  void upsertLessonProgress({
    required String lessonId,
    required int currentStep,
    required bool completed,
  }) {
    if (_user == null) return;
    _user!['lessonsProgress'] ??= [];
    final List progress = _user!['lessonsProgress'] as List;
    final int index = progress.indexWhere(
      (p) => (p['lessonId']?.toString() ?? '') == lessonId,
    );
    final Map<String, dynamic> newEntry = {
      'lessonId': lessonId,
      'currentStep': currentStep,
      'completed': completed,
    };
    if (index >= 0) {
      progress[index] = {...progress[index], ...newEntry};
    } else {
      progress.add(newEntry);
    }
    notifyListeners();
    _saveUserToPrefs(_user!);
  }

  void addSavedStory(String storyId) {
    if (_user != null) {
      _user!["savedStories"].add(storyId);
    }
    notifyListeners();
  }

  String? get role => _user?['role'];
  String? get aiSessionId => _aiSessionId; // Add getter for AI session ID

  String get userId => _user?['id']?.toString() ?? '';

  String? get city => _user?['city'];
  String? get country => _user?['country'];

  bool get isLoggedIn => _user != null;

  // Add this field to store chat messages globally
  List<dynamic> _messages = [];
  List<dynamic> get messages => _messages;

  void addMessage(dynamic message) {
    _messages.add(message);
    notifyListeners();
  }

  void setMessages(List<dynamic> messages) {
    _messages = messages;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Update user city
  Future<void> updateUserCity(BuildContext context, String city) async {
    if (_user == null) return;
    print("Updating city to: $city");
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;
      final response = await http.put(
        Uri.parse(updateCity),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'city': city}),
      );
      print("Response body to updatae city : ${response.body}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          _user!['city'] = city;
          notifyListeners();
          await _saveUserToPrefs(_user!);
        }
      }
    } catch (e) {
      print('Error updating city: $e');
    }
  }

  // Set user after login or profile update
  Future<void> setUser(
    Map<String, dynamic> userData, {
    String? sessionId,
    String? aiSessionId,
  }) async {
    print("=== SET USER DEBUG ===");
    print("setUser called with userData: $userData");
    print("sessionId parameter: $sessionId");
    print("aiSessionId parameter: $aiSessionId");
    print("userData ai_session_id: ${userData['ai_session_id']}");

    _user = userData;

    if (aiSessionId != null) {
      _aiSessionId = aiSessionId;
      print("AI SessionId set from parameter: $aiSessionId");
    }
    // Set ai_session_id from userData if it exists (this is the permanent ID)
    if (userData['ai_session_id'] != null) {
      _aiSessionId = userData['ai_session_id'];
      print("AI SessionId set from userData: ${userData['ai_session_id']}");
    }

    print("Final values:");
    print("User ID: ${_user?['id']}");
    print("AI Session ID: $_aiSessionId");
    print("User set, isLoggedIn: $isLoggedIn");

    notifyListeners();
    await _saveUserToPrefs(userData);
    final prefs = await SharedPreferences.getInstance();

    if (_aiSessionId != null) {
      await prefs.setString('aiSessionId', _aiSessionId!);
      print("AI SessionId saved to prefs: $_aiSessionId");
    }
    print("=== END SET USER DEBUG ===");
  }


  // Set the permanent AI session ID (should only be called once when first created)
  void setAiSessionId(String aiSessionId) async {
    print("=== USERPROVIDER AI SESSION DEBUG ===");
    print("Setting aiSessionId: $aiSessionId");
    print("Previous aiSessionId: $_aiSessionId");

    _aiSessionId = aiSessionId;
    // Update the user data to include the ai_session_id
    if (_user != null) {
      _user!['ai_session_id'] = aiSessionId;
      print("Updated user data with ai_session_id");
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiSessionId', aiSessionId);
    // Also save the updated user data
    if (_user != null) {
      await _saveUserToPrefs(_user!);
      print("User data saved to prefs");
    }

    print("AI SessionId set successfully");
    print("=== END USERPROVIDER AI SESSION DEBUG ===");
  }

  // Clear user on logout
  Future<void> logout() async {
    _user = null;
    _aiSessionId = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
    prefs.remove('sessionId');
    prefs.remove('aiSessionId');
    prefs.setString('token', '');
  }

  // Add a question to savedQuestions and persist
  void toggleSavedQuestion(String questionId) {
    if (_user == null) return;
    _user!["savedQuestions"] ??= [];
    final saved = _user!["savedQuestions"] as List;
    if (saved.contains(questionId)) {
      saved.remove(questionId);
    } else {
      saved.add(questionId);
    }
    notifyListeners();
    _saveUserToPrefs(_user!);
  }

  // Getter for savedQuestions
  List<String> get savedQuestions {
    if (_user == null) return [];
    return List<String>.from(_user!["savedQuestions"] ?? []);
  }

  // Getter for savedQuestions
  List<String> get savedStories {
    if (_user == null) return [];
    return List<String>.from(_user!["savedStories"] ?? []);
  }

  // Getter for savedQuestions
  List<String> get likedStories {
    if (_user == null) return [];
    return List<String>.from(_user!["likedStories"] ?? []);
  }

  // Save user data to local storage
  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(userData));
  }

  // Load user data at app startup
  Future<void> loadUserFromPrefs() async {
    print("=== LOAD USER FROM PREFS DEBUG ===");
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final sessionId = prefs.getString('sessionId');
    final aiSessionId = prefs.getString('aiSessionId');

    print("Loaded from prefs:");
    print("User data: ${userData != null ? "Yes" : "No"}");
    print("Session ID: $sessionId");
    print("AI Session ID: $aiSessionId");

    if (userData != null) {
      _user = jsonDecode(userData);
      _aiSessionId = aiSessionId;
      print("User data loaded:");
      print("User ID: ${_user?['id']}");
      print("User ai_session_id: ${_user?['ai_session_id']}");
      print("AI Session ID set: $_aiSessionId");
      notifyListeners();
    }
    print("=== END LOAD USER FROM PREFS DEBUG ===");
  }
}
