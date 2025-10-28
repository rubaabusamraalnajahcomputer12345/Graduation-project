// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:frontend/widgets/RegisterPage.dart';
import 'package:frontend/widgets/CustomTextField.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  String _accountType = 'user';
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _updateOneSignalId(String onesignalId) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${url}onesignal-id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'onesignalId': onesignalId}),
      );

      if (response.statusCode == 200) {
        print('OneSignal ID updated successfully');
      }
    } catch (e) {
      print('Failed to update OneSignal ID: $e');
    }
  }

  Future<void> signIn() async {
    final requestbody = {
      'email': _emailController.text,
      'password': _passwordController.text,
      'role':
          _accountType == 'admin'
              ? 'admin'
              : _accountType == 'volunteer'
              ? 'volunteer_pending'
              : 'user',
    };
    var response = await http.post(
      Uri.parse(login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestbody),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      if (mounted) {
        if (data['user']['isEmailVerified'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email')),
          );
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful'),
            backgroundColor: AppColors.islamicGreen500,
          ),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);

      print("sign in returned data: $data");
      print("About to set user in provider...");
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).setUser(data['user']);
      print("User set in provider successfully!");
      // Navigate to root so MaterialApp rebuilds and shows ResponsiveLayout
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HidayaApp()));
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // After login:
        final userId = Provider.of<UserProvider>(context, listen: false).userId;
        await OneSignal.login(userId);
        print('OneSignal External ID set to: $userId');
      }
      // Get OneSignal ID and send to backend
      try {
        String? onesignalId;
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          onesignalId = await OneSignal.User.pushSubscription.id;
        }
        if (onesignalId != null) {
          await _updateOneSignalId(onesignalId);
        }
      } catch (e) {
        print('Failed to get OneSignal ID: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background similar to your CSS background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.islamicGreen50,
              AppColors.signInBackground,
              AppColors.islamicGold500.withAlpha(51),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Some simple decorative faded icons
            Positioned(
              top: 40,
              left: 20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.star,
                  size: 48,
                  color: AppColors.islamicGreen600,
                ),
              ),
            ),
            Positioned(
              top: 80,
              right: 40,
              child: Opacity(
                opacity: 0.25,
                child: Icon(
                  Icons.nightlight_round,
                  size: 64,
                  color: AppColors.islamicGold300,
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 30,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: AppColors.islamicGreen300,
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: 20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.nightlight_round,
                  size: 56,
                  color: AppColors.islamicGold300,
                ),
              ),
            ),

            // Main content centered
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(204),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.islamicGreen200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.islamicGreen500.withAlpha(76),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo circle with moon icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.islamicGreen500,
                              AppColors.islamicGreen600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.islamicGreen600.withAlpha(128),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Hidaya',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.islamicGreen800,
                        ),
                      ),
                      Text(
                        'هداية - Guidance in Faith',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.islamicGreen600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Account Type dropdown
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Account Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.islamicGreen700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _accountType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'volunteer',
                                  child: Text('Volunteer'),
                                ),
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text('User'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _accountType = value;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
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
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.islamicGreen800,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Email
                            CustomTextField(
                              label: 'Email Address',
                              hint: 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password with show/hide
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: AppColors.islamicGreen700,
                                ),
                                hintText: 'Enter your password',
                                filled: true,
                                fillColor: Colors.white,
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
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppColors.islamicGreen600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                                                         // Forgot Password button
                             Align(
                               alignment: Alignment.centerRight,
                               child: TextButton(
                                 onPressed: _showForgotPasswordDialog,
                                 child: Text(
                                   'Forgot Password?',
                                   style: TextStyle(
                                     color: AppColors.islamicGreen600,
                                     fontWeight: FontWeight.w600,
                                     fontSize: 14,
                                   ),
                                 ),
                               ),
                             ),

                            const SizedBox(height: 24),

                            // Sign In button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // Handle sign in
                                    final snackBarKey =
                                        GlobalKey<ScaffoldMessengerState>();
                                    snackBarKey.currentState?.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Signing in as $_accountType...',
                                        ),
                                        duration: Duration(seconds: 10),
                                      ),
                                    );
                                    signIn();
                                    snackBarKey.currentState
                                        ?.hideCurrentSnackBar();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.islamicGreen500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                ),
                                child: Text(
                                  'Sign In as $_accountType',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Register button
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Don't have an account? Register",
                                style: TextStyle(
                                  color: AppColors.islamicGreen600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quran quote
                      Column(
                        children: [
                          Text(
                            '"And it is He who sends down rain from heaven, and We produce thereby the vegetation of every kind."',
                            style: TextStyle(
                              color: AppColors.islamicGreen600,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '- Quran 6:99',
                            style: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordDialog(
        scaffoldMessenger: ScaffoldMessenger.of(context),
      ),
    );
  }









}
class ForgotPasswordDialog extends StatefulWidget {
  final ScaffoldMessengerState scaffoldMessenger;

  const ForgotPasswordDialog({super.key, required this.scaffoldMessenger});

  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = widget.scaffoldMessenger;
    if (!mounted) return;

    try {
      final response = await http.post(
        Uri.parse(forgotPassword),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': _emailController.text}),
      );
      
      if (!mounted) return;

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Password reset link sent to your email.'),
            backgroundColor: AppColors.islamicGreen600,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to send reset link. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Pop the dialog after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.islamicWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.islamicGreen200),
      ),
      title: const Text(
        'Forgot Password',
        style: TextStyle(
          color: AppColors.islamicGreen800,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: AppColors.islamicGreen700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
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
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _sendResetLink();
            }
          },
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }
}
