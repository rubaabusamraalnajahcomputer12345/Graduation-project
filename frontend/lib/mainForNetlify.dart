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
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:frontend/providers/NavigationProvider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File, Platform;
import 'package:frontend/widgets/Admin/AdminPanel.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> resetAppState() async {
  // Clear SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  print('SUPABASE_URL: $supabaseUrl');
  print('SUPABASE_ANON_KEY: $supabaseAnonKey');

  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnonKey!);

  // User provider
  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();

  // Gemini
  final geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');
  Gemini.init(apiKey: geminiApiKey!);

  // ------------------------------
  // 2. Check token expiration
  // ------------------------------
  if (userProvider.isLoggedIn) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && AuthUtils.isTokenExpired(token)) {
        print('Token expired on startup, logging out user');
        await userProvider.logout();
      }
    } catch (e) {
      print('Error checking token: $e');
      await userProvider.logout();
    }
  }

  // ------------------------------
  // 3. Firebase initialization
  // ------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ------------------------------
  // 4. OneSignal (mobile only)
  // ------------------------------
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("b068d3f0-99d0-487c-a233-fde4b91a5b8c");
    OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) {
        switch (data['type']) {
          case 'question_answered':
            print(
              'Navigate to question: ${data['questionId']}, answer: ${data['answerId']}',
            );
            break;
          case 'answer_upvoted':
            print(
              'Navigate to upvoted answer: ${data['answerId']} with ${data['upvotesCount']} upvotes',
            );
            break;
          case 'new_question_for_volunteers':
            print(
              'Navigate to new question: ${data['questionId']} in category: ${data['category']}',
            );
            break;
          case 'welcome':
            print('Welcome notification clicked');
            break;
          case 'test':
            print('Test notification clicked');
            break;
          case 'missed_questions_summary':
            print(
              'Navigate to questions page - ${data['count']} missed questions',
            );
            break;
        }
      }
    });
  }

  // ------------------------------
  // 5. Run App
  // ------------------------------
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
