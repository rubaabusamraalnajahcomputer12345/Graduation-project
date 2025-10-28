import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/CertificationViewer.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/widgets/Qustions.dart';
import 'package:frontend/providers/NavigationProvider.dart';
import 'package:frontend/widgets/NotificationCenter.dart';
import 'package:frontend/widgets/SignInPage.dart';
import 'package:frontend/services/meeting_request_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State {
  late Map<String, dynamic> userObj = {
    'id': '',
    'displayName': '',
    'email': '',
    'role': '',
    'gender': '',
    'country': '',
    'language': '',
    // Volunteer-specific fields (optional, only for volunteers)
    'volunteerProfile': {
      'certificate': {
        'institution': '',
        'title': '',
        'url': '',
        'uploadedAt': '',
        '_id': '',
      },
      'languages': [],
      'bio': '',
      '_id': '',
    },
    'savedQuestions': [],
    'savedLessons': [],
  };

  // Controllers for edit form
  final _editFormKey = GlobalKey<FormState>(); //for validation....
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String? _gender;
  late TextEditingController _countryController;
  late TextEditingController _languageController;
  TextEditingController? _bioController;

  // Volunteer-specific controllers
  late TextEditingController _certTitleController;
  late TextEditingController _certInstitutionController;
  late TextEditingController _spokenLanguagesController;

  // Password change controllers
  final _passwordFormKey = GlobalKey<FormState>();
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // File handling
  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;

  List<String> _searchedCountries = [];
  bool _isSearchingCountry = false;

  List<String> _searchedLanguages = [];
  bool _isSearchingLanguage = false;

  // Spoken languages for volunteers
  List<String> _selectedSpokenLanguages = [];
  List<String> _searchedSpokenLanguages = [];
  bool _isSearchingSpokenLanguages = false;

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
      print(languages);
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

  Future<void> _sendTestNotification() async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${url}notifications/test'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'message':
              'Hello! This is a test notification from your Hidaya app! 🎉',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification sent! Check your device.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error Profile: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
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

  Future<void> changePassword() async {
    //Todo: implement change password logic
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated password '),
          backgroundColor: const Color.fromARGB(255, 0, 111, 59),
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          if (!mounted) {
            return;
          }
          await AuthUtils.logout(context);
        } else {}
      } else {
        print("delete failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("error deleting : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Get user data from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final role = userProvider.user?['role'] ?? '';
    userObj = userProvider.user ?? getInitialUserObj(role);

    _usernameController = TextEditingController(
      text: userObj['displayName'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: userObj['email'] as String? ?? '',
    );
    _gender = userObj['gender'] as String?;
    _countryController = TextEditingController(
      text: userObj['country'] as String? ?? '',
    );
    _languageController = TextEditingController(
      text: userObj['language'] as String? ?? '',
    );

    // Initialize volunteer-specific controllers
    if (userObj['role'] != 'user') {
      _bioController = TextEditingController(text: _getBioValue());
      _certTitleController = TextEditingController(
        text: _getVolunteerField('certificate.title'),
      );
      _certInstitutionController = TextEditingController(
        text: _getVolunteerField('certificate.institution'),
      );
      _spokenLanguagesController = TextEditingController();

      // Initialize selected spoken languages
      _selectedSpokenLanguages = _getVolunteerLanguages();
    } else {
      // Initialize with empty controllers for non-volunteer users to avoid null issues
      _bioController = TextEditingController();
      _certTitleController = TextEditingController();
      _certInstitutionController = TextEditingController();
      _spokenLanguagesController = TextEditingController();
      _selectedSpokenLanguages = [];
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    _bioController?.dispose();
    _certTitleController.dispose();
    _certInstitutionController.dispose();
    _spokenLanguagesController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder:
          (context) =>
              ChangePasswordDialog(scaffoldMessenger: scaffoldMessenger),
    );
  }

  void _showEditProfileDialog() {
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
                'Edit Profile',
                style: TextStyle(
                  color: AppColors.islamicGreen800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 400,
                height: 800, // increased height for volunteer fields
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
                                      ? 'Enter your name'
                                      : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
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
                                      ? 'Enter your email'
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
                            hintText: 'Search for your country',
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
                            height: 150, // or 200
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
                                        _countryController.text = country;
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
                                      _languageController.text = language;
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
                                        _spokenLanguagesController.clear();
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
                        userObj['displayName'] = _usernameController.text;
                        userObj['email'] = _emailController.text;
                        userObj['gender'] = _gender ?? '';
                        userObj['country'] = _countryController.text;
                        userObj['language'] = _languageController.text;

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

  Widget _buildUserInfoSection({
    bool showEdit = true,
    bool showButtons = true,
  }) {
    return Stack(
      children: [
        Column(
          children: [
            // Avatar
            Container(
              width: 96,
              height: 96,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.islamicGreen500,
                    AppColors.islamicGreen600,
                  ],
                ),
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            // User Info
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        userObj['gender'] == 'Female'
                            ? 'Sister '
                            : userObj['gender'] == 'Male'
                            ? 'Brother '
                            : '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  TextSpan(
                    text: userObj['displayName'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.islamicGreen800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(Icons.email, userObj['email'] as String? ?? ''),
            SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              userObj['country'] as String? ?? '',
            ),
            SizedBox(height: 8),
            _buildInfoRow(Icons.language, userObj['language'] as String? ?? ''),
            if (showButtons) ...[
              SizedBox(height: 24),
              Divider(color: AppColors.islamicGreen200),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.islamicGreen600,
                        side: BorderSide(color: AppColors.islamicGreen300),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationCenter(),
                          ),
                        );
                      },
                      icon: Icon(Icons.notifications_active, size: 16),
                      label: Text('View All Notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.islamicGreen500,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthUtils.logout(context);
                },
                icon: Icon(Icons.logout, size: 16),
                label: Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
        // Settings button at top right
        Positioned(top: 0, right: 0, child: _buildSettingsMenu()),
      ],
    );
  }

  // Settings menu widget (gear icon with dropdown)
  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: AppColors.islamicGreen600, size: 26),
      color: AppColors.islamicWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      onSelected: (value) {
        if (value == "delete_account") {
          ConfirmDeleteAccountModal.show(
            context,
            onConfirm: () {
              deleteAccount();
            },
            onCancel: () {
              Navigator.of(context).pop(); // Just close the modal
            },
          );
        } else if (value == "change_password") {
          _showChangePasswordDialog();
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<String>(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(Icons.lock, color: AppColors.islamicGreen500, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(color: AppColors.islamicGreen800),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete_account',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.errorRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ],
              ),
            ),
          ],
      tooltip: 'Settings',
      elevation: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.islamicGreen50,
              AppColors.islamicCream,
              AppColors.islamicGold50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 768) {
                      // Desktop layout - align columns to the top
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLeftColumn()),
                          SizedBox(width: 24),
                          Expanded(child: _buildRightColumn()),
                        ],
                      );
                    } else if (constraints.maxWidth > 768 &&
                        userObj['role'] != 'volunteer_pending' &&
                        userObj['role'] != 'user') {
                      // Desktop layout for admin or certified_volunteer
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Expanded(child: _buildLeftColumn()),
                          SizedBox(width: 24),
                          Expanded(child: _buildRightColumn()),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildLeftColumn(),
                          SizedBox(height: 24),
                          _buildRightColumn(),
                        ],
                      );
                    }
                  },
                ),

                // Footer Quote
                Container(
                  margin: EdgeInsets.only(top: 48),
                  padding: EdgeInsets.only(top: 32),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.islamicGreen200),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"And those who believe and do righteous deeds - no fear shall they have, nor shall they grieve."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.islamicGreen600,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '- Quran 2:62',
                        style: TextStyle(
                          color: AppColors.islamicGreen500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

  Widget _buildLeftColumn() {
    if (userObj['role'] == 'volunteer_pending') {
      return Column(children: [_buildPendingVolunteerSection()]);
    }
    return Column(
      children: [
        _buildCommonSection(),
        SizedBox(height: 24),
        if (userObj['role'] == 'admin') _buildAdminSection(),
        if (userObj['role'] == 'user' ||
            userObj['role'] == 'certified_volunteer')
          _buildSavedContentSection(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (userObj['role'] == 'volunteer_pending' ||
            userObj['role'] == 'user') ...[
          // Show meeting requests for regular users
          _buildMeetingRequestsSection(),
        ] else ...[
          // Show volunteer sections for certified volunteers and admins
          if (userObj['role'] == 'certified_volunteer')
            _buildCertifiedVolunteerSection(),
          if (userObj['role'] == 'admin') ...[
            _buildCertifiedVolunteerSection(),
            SizedBox(height: 24),
            _buildSavedContentSection(),
          ],

          // Add Meeting Requests Section for all users
          SizedBox(height: 24),
          _buildMeetingRequestsSection(),
        ],
      ],
    );
  }

  Widget _buildPendingVolunteerSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserInfoSection(showEdit: false, showButtons: false),
            SizedBox(height: 24),
            Divider(color: AppColors.islamicGreen200),
            SizedBox(height: 24),
            Icon(
              Icons.hourglass_top,
              color: AppColors.islamicGold400,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Your application to become a Certified Muslim Volunteer is under review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.islamicGreen700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You will be recieved an email once your application is approved.\n\nThank you for your willingness to volunteer and contribute to our community!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.islamicGreen600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: _buildUserInfoSection(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.islamicGreen600),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: AppColors.islamicGreen600),
        ),
      ],
    );
  }

  Widget _buildCertifiedVolunteerSection() {
    return Column(
      children: [
        // Badge
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.islamicGreen50, AppColors.islamicGold50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: AppColors.islamicGreen600),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.islamicGreen500,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Certified Muslim Volunteer',

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),

        // Certificate Details
        _buildInfoCard(
          'Certification Details',
          Icons.military_tech,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Institution',
                _getVolunteerField('certificate.institution'),
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                'Certificate Title',
                _getVolunteerField('certificate.title'),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final certificateUrl = _getVolunteerField('certificate.url');
                  if (certificateUrl.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CertificationViewer(fileUrl: certificateUrl),
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
                icon: Icon(Icons.visibility),
                label: Text('View Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen500,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Bio
        _buildInfoCard(
          'Islamic Background',
          Icons.description,
          Text(
            _getVolunteerField('bio'),
            style: TextStyle(color: AppColors.islamicGreen600, height: 1.5),
          ),
        ),
        SizedBox(height: 24),

        // Languages
        _buildInfoCard(
          'Languages Spoken',
          Icons.language,
          Wrap(
            spacing: 8,
            runSpacing: 8, // Adds vertical space between wrap elements
            children:
                _getVolunteerLanguages()
                    .map(
                      (lang) => Chip(
                        label: Text(lang),
                        backgroundColor: AppColors.islamicGreen200,
                        labelStyle: TextStyle(color: AppColors.islamicGreen600),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.islamicGold50, AppColors.islamicGreen50],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.islamicGreen800,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.islamicGreen800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.settings),
                label: Text('Go to Admin Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen500,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Text(
                'Quick Actions:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                ),
              ),
              SizedBox(height: 12),
              _buildActionTile(Icons.people, 'View Volunteers'),
              _buildActionTile(Icons.flag, 'Review Flags'),
              _buildActionTile(Icons.person_add, 'Promote Users'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedContentSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.islamicGreen800,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildContentCard(
                    Icons.book,
                    'Saved Stories',
                    (userObj['savedStories'] == null ||
                            userObj['savedStories'].isEmpty)
                        ? 'save first story'
                        : userObj['savedStories'].length.toString(),
                    'stories saved',
                    AppColors.islamicGreen50,
                    AppColors.islamicGreen600,
                    () {
                      final navProvider = Provider.of<NavigationProvider>(
                        context,
                        listen: false,
                      );
                      navProvider.setMainTabIndex(2); // 2 = Lessons tab
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildContentCard(
                    Icons.help,
                    'My Questions',
                    (userObj['savedQuestions'] == null ||
                            userObj['savedQuestions'].isEmpty)
                        ? 'start saving questions'
                        : userObj['savedQuestions'].length.toString(),
                    'questions asked',
                    AppColors.islamicGold50,
                    AppColors.islamicGold400,
                    () {
                      final navProvider = Provider.of<NavigationProvider>(
                        context,
                        listen: false,
                      );
                      navProvider.setMainTabIndex(1); // 1 = Ask tab
                      navProvider.setQuestionsTabIndex(
                        2,
                      ); // 2 = Favorites sub-tab
                      navProvider.triggerScrollToFavorites();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Widget content) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.islamicGreen800, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.islamicGreen800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.islamicGreen600,
          ),
        ),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.islamicGreen600)),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.islamicGreen600),
              SizedBox(width: 12),
              Text(title, style: TextStyle(color: AppColors.islamicGreen600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(
    IconData icon,
    String title,
    String count,
    String subtitle,
    Color bgColor,
    Color iconColor,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.islamicGreen800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(subtitle, style: TextStyle(fontSize: 12, color: iconColor)),
          ],
        ),
      ),
    );
  }

  // Helper method to get volunteer profile fields safely
  String _getVolunteerField(String fieldPath) {
    if (userObj['volunteerProfile'] == null) {
      return '';
    }

    final volunteerProfile =
        userObj['volunteerProfile'] as Map<String, dynamic>;

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

  // Helper method to get volunteer languages
  List<String> _getVolunteerLanguages() {
    if (userObj['volunteerProfile'] == null) {
      return [];
    }

    final volunteerProfile =
        userObj['volunteerProfile'] as Map<String, dynamic>;
    final languages = volunteerProfile['languages'] as List<dynamic>?;

    if (languages != null) {
      return languages.map((lang) => lang.toString()).toList();
    }

    return [];
  }

  // Helper method to get bio value for both user and volunteer roles
  String _getBioValue() {
    // For volunteers, bio is in volunteerProfile
    if (userObj['volunteerProfile'] != null) {
      final volunteerProfile =
          userObj['volunteerProfile'] as Map<String, dynamic>;
      return volunteerProfile['bio']?.toString() ?? '';
    }
    // For regular users, bio is directly in userObj
    return userObj['bio']?.toString() ?? '';
  }

  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    final token = await AuthUtils.getValidToken(context);
    if (token == null) {
      // User was logged out due to expired token
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
    // For user and admin roles, only basic fields are sent (no bio, languages, or certificate)

    request.body = json.encode(requestBody);
    request.headers.addAll(headers);

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
        'ai_session_id': updatedUser['ai_session_id'],
      };

      // Only add bio field for non-volunteer users
      if (updatedUser['role'] == 'user' || updatedUser['role'] == 'admin') {
        transformedUser['bio'] = updatedUser['bio'] ?? '';
      }

      setState(() {
        userObj = transformedUser;
      });

      // Update the UserProvider with the transformed data
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).setUser(transformedUser);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.islamicGreen600,
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
  }
}

class ChangePasswordDialog extends StatefulWidget {
  final ScaffoldMessengerState scaffoldMessenger;

  const ChangePasswordDialog({super.key, required this.scaffoldMessenger});

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Keep references before the async gap.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = widget.scaffoldMessenger;

    if (!mounted) return;

    final token = await AuthUtils.getValidToken(context);
    if (token == null || !mounted) return;

    final response = await http.post(
      Uri.parse(changePassword),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: AppColors.islamicGreen600,
        ),
      );

      // Pop the dialog after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) navigator.pop();
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to change password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    Navigator.of(context).pop(); // Close the current dialog
    showDialog(
      context: context,
      builder:
          (context) =>
              ForgotPasswordDialog(scaffoldMessenger: widget.scaffoldMessenger),
    );
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
        'Change Password',
        style: TextStyle(
          color: AppColors.islamicGreen800,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _passwordFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(
                  color: AppColors.islamicGreen700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Enter your current password'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: AppColors.islamicGreen700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(
                  color: AppColors.islamicGreen700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.islamicGreen600),
                ),
              ),
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
            if (_passwordFormKey.currentState!.validate()) {
              _changePassword();
            }
          },
          child: const Text('Change Password'),
        ),
      ],
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

    // TODO: Implement API call to backend
    final token = await AuthUtils.getValidToken(context);
    if (token == null || !mounted) return;

    final response = await http.post(
      Uri.parse(forgotPassword),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': _emailController.text}),
    );
    print(response.body);
    if (!mounted) return;

    if (response.statusCode == 200) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
          backgroundColor: AppColors.islamicGreen600,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset link. Please try again.'),
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

Map<String, dynamic> getInitialUserObj(String role) {
  if (role == 'certified_volunteer' ||
      role == 'volunteer_pending' ||
      role == 'volunteer') {
    return {
      'id': '',
      'displayName': '',
      'email': '',
      'role': role,
      'gender': '',
      'country': '',
      'language': '',
      'volunteerProfile': {
        'certificate': {
          'institution': '',
          'title': '',
          'url': '',
          'uploadedAt': '',
          '_id': '',
        },
        'languages': [],
        'bio': '',
        '_id': '',
      },
      'savedQuestions': [],
      'savedLessons': [],
    };
  } else if (role == 'user') {
    return {
      'id': '',
      'displayName': '',
      'email': '',
      'role': 'user',
      'gender': '',
      'country': '',
      'language': '',
      'savedQuestions': [],
      'savedLessons': [],
    };
  } else if (role == 'admin') {
    return {
      'id': '',
      'displayName': '',
      'email': '',
      'role': 'admin',
      'gender': '',
      'country': '',
      'language': '',
      'savedQuestions': [],
      'savedLessons': [],
    };
  } else {
    // Default fallback
    return {
      'id': '',
      'displayName': '',
      'email': '',
      'role': '',
      'gender': '',
      'country': '',
      'language': '',
      'savedQuestions': [],
      'savedLessons': [],
    };
  }
}

class QuestionsWithFavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Questions(initialTabIndex: 2);
  }
}

class ConfirmDeleteAccountModal extends StatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmDeleteAccountModal({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ConfirmDeleteAccountModal(
          onConfirm: onConfirm,
          onCancel: onCancel ?? () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  State<ConfirmDeleteAccountModal> createState() =>
      _ConfirmDeleteAccountModalState();
}

class _ConfirmDeleteAccountModalState extends State<ConfirmDeleteAccountModal> {
  bool _isDeleting = false;
  final TextEditingController _confirmController = TextEditingController();
  bool _inputMatches = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_checkInput);
  }

  void _checkInput() {
    setState(() {
      _inputMatches =
          _confirmController.text.trim().toLowerCase() == 'delete my account';
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final maxWidth = isTablet ? 400.0 : screenSize.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.islamicWhite,
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.errorRed,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isDeleting ? null : widget.onCancel,
                    icon: Icon(Icons.close, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed.',
                    style: TextStyle(
                      color: AppColors.islamicGreen800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We are sad to see you go. May Allah bless you on your journey.',
                    style: TextStyle(
                      color: AppColors.islamicGreen600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'To confirm, please type "delete my account" below:',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmController,
                    enabled: !_isDeleting,
                    decoration: InputDecoration(
                      hintText: 'Type: delete my account',
                      hintStyle: TextStyle(color: AppColors.grey400),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.errorRedLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.errorRed,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_inputMatches && _confirmController.text.isNotEmpty)
                    Text(
                      'You must type "delete my account" to enable deletion.',
                      style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isDeleting ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.islamicGreen600,
                      side: BorderSide(color: AppColors.islamicGreen400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        _isDeleting || !_inputMatches
                            ? null
                            : () async {
                              setState(() => _isDeleting = true);
                              await Future.delayed(
                                const Duration(milliseconds: 600),
                              );
                              if (widget.onConfirm != null) widget.onConfirm!();
                              if (mounted) Navigator.of(context).pop();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: AppColors.islamicWhite,
                      disabledBackgroundColor: AppColors.errorRedLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child:
                        _isDeleting
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.islamicWhite,
                                ),
                              ),
                            )
                            : const Text('Delete'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Meeting Requests Section Widget
class _MeetingRequestsSection extends StatefulWidget {
  final String userRole;

  const _MeetingRequestsSection({Key? key, required this.userRole})
    : super(key: key);

  @override
  State<_MeetingRequestsSection> createState() =>
      _MeetingRequestsSectionState();
}

class _MeetingRequestsSectionState extends State<_MeetingRequestsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _volunteerRequests = [];
  List<Map<String, dynamic>> _userRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeetingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetingRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      // Load volunteer requests if user is a certified volunteer
      if (widget.userRole.toLowerCase() == 'certified_volunteer') {
        final volunteerResult =
            await MeetingRequestService.getVolunteerMeetingRequests(
              token: token,
            );
        if (volunteerResult['success']) {
          _volunteerRequests = List<Map<String, dynamic>>.from(
            volunteerResult['data'] ?? [],
          );
        }
      }

      // Load user requests (requests created by the current user)
      final userResult = await MeetingRequestService.getUserMeetingRequests(
        token: token,
      );
      if (userResult['success']) {
        _userRequests = List<Map<String, dynamic>>.from(
          userResult['data'] ?? [],
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meeting requests: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.islamicGreen200),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.islamicGreen800,
              ),
            ),
            SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.islamicGreen100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.islamicGreen800,
                unselectedLabelColor: AppColors.islamicGreen600,
                indicator: BoxDecoration(
                  color: AppColors.islamicGreen200,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(icon: Icon(Icons.person), text: 'My Requests'),
                  if (widget.userRole.toLowerCase() == 'certified_volunteer')
                    Tab(
                      icon: Icon(Icons.volunteer_activism),
                      text: 'Volunteer Requests',
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Tab Content
            Container(
              height: 300, // Fixed height for the content area
              child: TabBarView(
                controller: _tabController,
                children: [
                  // My Requests Tab
                  _buildRequestsList(_userRequests, isUserRequests: true),

                  // Volunteer Requests Tab (only for certified volunteers)
                  if (widget.userRole.toLowerCase() == 'certified_volunteer')
                    _buildRequestsList(
                      _volunteerRequests,
                      isUserRequests: false,
                    )
                  else
                    Center(
                      child: Text(
                        'Only certified volunteers can see volunteer requests',
                        style: TextStyle(color: AppColors.islamicGreen600),
                      ),
                    ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],

            // Refresh button
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadMeetingRequests,
                icon:
                    _isLoading
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(Icons.refresh),
                label: Text(_isLoading ? 'Loading...' : 'Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen500,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    List<Map<String, dynamic>> requests, {
    required bool isUserRequests,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.islamicGreen600),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 48,
              color: AppColors.islamicGreen300,
            ),
            SizedBox(height: 16),
            Text(
              isUserRequests
                  ? 'No meeting requests yet'
                  : 'No volunteer requests yet',
              style: TextStyle(fontSize: 16, color: AppColors.islamicGreen600),
            ),
            SizedBox(height: 8),
            Text(
              isUserRequests
                  ? 'Create a meeting request to get started'
                  : 'Users will appear here when they request meetings',
              style: TextStyle(color: AppColors.islamicGreen500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _MeetingRequestCard(
          request: request,
          isUserRequest: isUserRequests,
          onRefresh: _loadMeetingRequests,
        );
      },
    );
  }
}

// Individual Meeting Request Card for ProfilePage
class _MeetingRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isUserRequest;
  final VoidCallback onRefresh;

  const _MeetingRequestCard({
    Key? key,
    required this.request,
    required this.isUserRequest,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<_MeetingRequestCard> createState() => _MeetingRequestCardState();
}

class _MeetingRequestCardState extends State<_MeetingRequestCard> {
  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'accepted':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'completed':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status']?.toString() ?? 'pending';
    final createdAt = _formatDate(widget.request['createdAt']);
    final selectedSlot = widget.request['selectedSlot'];
    final zoomLink = widget.request['zoomLink'];
    final rejectReason = widget.request['rejectReason'];

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        _getStatusColor(status).replaceAll('#', '0xFF'),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'Created: $createdAt',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.islamicGreen600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Meeting details
            if (selectedSlot != null) ...[
              Text(
                'Selected Time:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '${_formatDate(selectedSlot['start'])} - ${_formatDate(selectedSlot['end'])}',
                style: TextStyle(
                  color: AppColors.islamicGreen700,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 8),
            ],

            // Zoom link
            if (zoomLink != null && zoomLink.isNotEmpty) ...[
              Text(
                'Zoom Meeting:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              InkWell(
                onTap: () {
                  // Open zoom link
                  // You can use url_launcher package here
                },
                child: GestureDetector(
                  onTap: () async {
                    // Open zoom link using url_launcher
                    if (await canLaunchUrl(Uri.parse(zoomLink))) {
                      await launchUrl(
                        Uri.parse(zoomLink),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    zoomLink,
                    style: TextStyle(
                      color: AppColors.islamicGreen600,
                      decoration: TextDecoration.underline,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],

            // Reject reason
            if (rejectReason != null && rejectReason.isNotEmpty) ...[
              Text(
                'Rejection Reason:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.islamicGreen800,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                rejectReason,
                style: TextStyle(color: Colors.red.shade700, fontSize: 11),
              ),
              SizedBox(height: 8),
            ],

            // Action buttons for volunteers
            if (!widget.isUserRequest && status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTimeSlotSelection(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.islamicGreen600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Select Time',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade600),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTimeSlotSelection(BuildContext context) {
    // Get the meeting request data
    final meetingId = widget.request['meetingId'];
    final preferredSlots = widget.request['preferredSlots'] as List<dynamic>?;

    if (preferredSlots == null || preferredSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No preferred time slots available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _TimeSlotSelectionDialog(
            meetingId: meetingId,
            preferredSlots: preferredSlots,
            onTimeSelected: (selectedIndex) async {
              Navigator.of(context).pop();
              await _selectTimeSlot(meetingId, selectedIndex);
            },
          ),
    );
  }

  Future<void> _selectTimeSlot(String meetingId, int selectedSlotIndex) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final result = await MeetingRequestService.selectTimeSlot(
        meetingId: meetingId,
        selectedSlotIndex: selectedSlotIndex,
        token: token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Time slot selected successfully! Zoom meeting created.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the meeting requests
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to select time slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(BuildContext context) {
    final meetingId = widget.request['meetingId'];
    final rejectController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reject Meeting Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please provide a reason for rejecting this meeting request:',
                ),
                SizedBox(height: 16),
                TextField(
                  controller: rejectController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter rejection reason...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reason = rejectController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please provide a rejection reason'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  await _rejectMeetingRequest(meetingId, reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectMeetingRequest(
    String meetingId,
    String rejectReason,
  ) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return;

      final result = await MeetingRequestService.rejectMeetingRequest(
        meetingId: meetingId,
        rejectReason: rejectReason,
        token: token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting request rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        // Refresh the meeting requests
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to reject meeting request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Time Slot Selection Dialog
class _TimeSlotSelectionDialog extends StatefulWidget {
  final String meetingId;
  final List<dynamic> preferredSlots;
  final Function(int) onTimeSelected;

  const _TimeSlotSelectionDialog({
    Key? key,
    required this.meetingId,
    required this.preferredSlots,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<_TimeSlotSelectionDialog> createState() =>
      _TimeSlotSelectionDialogState();
}

class _TimeSlotSelectionDialogState extends State<_TimeSlotSelectionDialog> {
  int? _selectedSlotIndex;

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Time Slot'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose one of the preferred time slots:',
              style: TextStyle(color: AppColors.islamicGreen700),
            ),
            SizedBox(height: 16),
            ...widget.preferredSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              final isSelected = _selectedSlotIndex == index;

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                color: isSelected ? AppColors.islamicGreen100 : Colors.white,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSlotIndex = index;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _selectedSlotIndex,
                          onChanged: (value) {
                            setState(() {
                              _selectedSlotIndex = value;
                            });
                          },
                          activeColor: AppColors.islamicGreen600,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slot ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.islamicGreen800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatDate(slot['start'])} - ${_formatDate(slot['end'])}',
                                style: TextStyle(
                                  color: AppColors.islamicGreen700,
                                  fontSize: 12,
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
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedSlotIndex != null
                  ? () => widget.onTimeSelected(_selectedSlotIndex!)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.islamicGreen600,
            foregroundColor: Colors.white,
          ),
          child: Text('Select Time'),
        ),
      ],
    );
  }
}

// Add the missing method to ProfilePage class
extension ProfilePageExtension on _ProfilePageState {
  Widget _buildMeetingRequestsSection() {
    return _MeetingRequestsSection(userRole: userObj['role'] ?? 'user');
  }
}
