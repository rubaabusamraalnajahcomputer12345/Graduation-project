// ignore_for_file: unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:frontend/widgets/ProfilePage.dart';
import 'package:frontend/widgets/ResponsiveLayou.dart';
import 'package:frontend/widgets/SignInPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:frontend/providers/NavigationProvider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:frontend/widgets/Admin/AdminPanel.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> resetAppState() async {
  // Clear SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '/.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY']!);

  // Check token expiration on app startup
  if (userProvider.isLoggedIn) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && AuthUtils.isTokenExpired(token)) {
        print('Token is expired on app startup, logging out user');
        await userProvider.logout();
      }
    } catch (e) {
      print('Error checking token on startup: $e');
      await userProvider.logout();
    }
  }

  //firbase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Guard OneSignal initialization for mobile only
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // Initialize with your OneSignal App ID
    OneSignal.initialize("b068d3f0-99d0-487c-a233-fde4b91a5b8c");
    // Use this method to prompt for push notifications.
    // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
    OneSignal.Notifications.requestPermission(true);

    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.jsonRepresentation()}');

      // Handle different notification types
      final data = event.notification.additionalData;
      if (data != null) {
        switch (data['type']) {
          case 'question_answered':
            // Navigate to the answered question
            final questionId = data['questionId'];
            final answerId = data['answerId'];
            print('Navigate to question: $questionId, answer: $answerId');
            // You can implement navigation logic here
            break;

          case 'answer_upvoted':
            // Navigate to the upvoted answer
            final questionId = data['questionId'];
            final answerId = data['answerId'];
            final upvotesCount = data['upvotesCount'];
            print(
              'Navigate to upvoted answer: $answerId with $upvotesCount upvotes',
            );
            // You can implement navigation logic here
            break;

          case 'new_question_for_volunteers':
            // Navigate to the new question for volunteers
            final questionId = data['questionId'];
            final category = data['category'];
            print(
              'Navigate to new question: $questionId in category: $category',
            );
            // You can implement navigation logic here
            break;

          case 'welcome':
            // Welcome notification - no navigation needed
            print('Welcome notification clicked');
            break;

          case 'test':
            // Test notification - no navigation needed
            print('Test notification clicked');
            break;

          case 'missed_questions_summary':
            // Navigate to questions page to see missed questions
            final count = data['count'];
            print('Navigate to questions page - $count missed questions');
            // You can implement navigation logic here
            break;
        }
      }
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: HidayaApp(),
    ),
  );
}

class HidayaApp extends StatefulWidget {
  const HidayaApp({super.key});

  @override
  State<HidayaApp> createState() => _HidayaAppState();
}

class _HidayaAppState extends State<HidayaApp> {
  Timer? _tokenCheckTimer;

  @override
  void initState() {
    super.initState();
    // Check token every 5 minutes
    _tokenCheckTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkTokenPeriodically();
    });

    // Check for pending connection data after widget is built
  }

  @override
  void dispose() {
    _tokenCheckTimer?.cancel();
    super.dispose();
  }

  void _checkTokenPeriodically() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      try {
        SharedPreferences.getInstance().then((prefs) {
          final token = prefs.getString('token');
          if (token != null && AuthUtils.isTokenExpired(token)) {
            print('Token expired during periodic check, logging out user');
            userProvider.logout();
          }
        });
      } catch (e) {
        print('Error during periodic token check: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        print("Consumer rebuilt, isLoggedIn: ${userProvider.isLoggedIn}");

        return MaterialApp(
          home:
              userProvider.isLoggedIn
                  ? (userProvider.user?['role'] == 'admin'
                      ? AdminPanel()
                      : ResponsiveLayout(
                        userRole: userProvider.user?['role'] ?? 'user',
                      ))
                  : SignInPage(),
        );
      },
    );
  }
}
