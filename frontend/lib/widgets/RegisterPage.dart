// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/SignInPage.dart';
import 'package:frontend/widgets/CustomTextField.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config.dart';
import 'package:frontend/widgets/HomePage.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _accountType = 'User';
  String? _gender;
  String? _country;
  String? _language;

  TextEditingController _countrySearchController = TextEditingController();
  List<String> _searchedCountries = [];
  bool _isSearchingCountry = false;
  bool _obscurePassword = true;

  TextEditingController _languageSearchController = TextEditingController();
  List<String> _searchedLanguages = [];
  bool _isSearchingLanguage = false;

  // Controllers for required fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // New controllers for volunteer extra fields
  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _certTitleController = TextEditingController();
  final TextEditingController _certInstitutionController =
      TextEditingController();

  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;

  Future<void> searchCountries(String query) async {
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

  Future<void> searchLanguages(String query) async {
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

  List<String> _selectedSpokenLanguages = [];
  TextEditingController _spokenLanguagesController = TextEditingController();
  List<String> _searchedSpokenLanguages = [];
  bool _isSearchingSpokenLanguages = false;

  Future<void> searchSpokenLanguages(String query) async {
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
          .from('story')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isNotEmpty) {
        print('Upload successful');

        final publicUrl = Supabase.instance.client.storage
            .from('story')
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

  Future<void> submitForm() async {
    String certUrl = '';
    if (_accountType == 'Volunteer' && _selectedFile != null) {
      certUrl = await uploadFile(_selectedFile!);
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your country'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_language == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your language'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional validation for volunteer-specific fields
    if (_accountType == 'Volunteer') {
      if (_selectedSpokenLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one spoken language'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    var accountType = '';
    // If all validations pass, proceed with form submission
    if (_accountType == 'Volunteer' && _selectedFile != null) {
      final url = await uploadFile(_selectedFile!);
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload certification'),
            backgroundColor: Colors.red,
          ),
        );
      } else {}
    }
    accountType = switch (_accountType) {
      'Volunteer' => 'volunteer_pending',
      'User' => 'user',
      _ => 'user',
    };
    print('accountType being sent: $accountType');

    var requestbody = {};
    if (accountType == 'volunteer_pending') {
      requestbody = {
        'displayName': _usernameController.text,
        'gender': _gender,
        'role': accountType,
        'email': _emailController.text,
        'password': _passwordController.text,
        'country': _country,
        'language': _language,
        'certification_url': certUrl,
        'certification_title': _certTitleController.text,
        'certification_institution': _certInstitutionController.text,
        'bio': _bioController.text,
        'spoken_languages': _selectedSpokenLanguages,
      };
    } else {
      requestbody = {
        'displayName': _usernameController.text,
        'gender': _gender,
        'email': _emailController.text,
        'password': _passwordController.text,
        'country': _country,
        'language': _language,
        'role': accountType,
        'savedQuestions': [],
        'savedLessons': [],
      };
    }

    print('Request Body: ${jsonEncode(requestbody)}');

    var response = await http.post(
      Uri.parse(registeration),
      headers: {"Content-Type": "application/json"},

      body: jsonEncode(requestbody),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['status'] == true) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Successful'),
              content: const Text(
                'A verification email has been sent to your email address. Please check your inbox to complete the registration.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.islamicGreen50,
              AppColors.signInBackground,
              AppColors.islamicGold500.withAlpha((255 * 0.2).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.85).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.islamicGreen200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.islamicGreen500.withAlpha(
                          (255 * 0.3).toInt(),
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with icon and text
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.islamicGreen500,
                                    AppColors.islamicGreen600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.islamicGreen600.withAlpha(
                                      128,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.nights_stay_outlined,
                                color: Colors.white,
                                size: 40,
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
                            const SizedBox(height: 4),
                            Text(
                              'هداية - Guidance in Faith',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.islamicGreen600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Account type selector (DropdownButton)
                        const Text(
                          'Account Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.islamicGreen700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
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
                          ),
                          value: _accountType,
                          items: const [
                            DropdownMenuItem(
                              value: 'Volunteer',
                              child: Text('Volunteer'),
                            ),
                            DropdownMenuItem(
                              value: 'User',
                              child: Text('User'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _accountType = value;
                              });
                            }
                          },
                          style: TextStyle(
                            color: AppColors.islamicGreen800,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 24),

                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'Enter your username',
                          required: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender input
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
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
                          ),
                          value: _gender,
                          hint: const Text('Select your gender'),
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

                        const SizedBox(height: 16),

                        // Country input (async, searchable)
                        TextFormField(
                          controller: _countrySearchController,
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
                            searchCountries(value);
                          },
                        ),
                        const SizedBox(height: 8),

                        if (_searchedCountries.isNotEmpty)
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
                                      _countrySearchController.text = country;
                                      _country = country;
                                      _searchedCountries = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Language input (async, searchable)
                        TextFormField(
                          controller: _languageSearchController,
                          decoration: InputDecoration(
                            labelText: 'Language *',
                            labelStyle: TextStyle(
                              color: AppColors.islamicGreen700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppColors.islamicGreen500,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: 'Search for your language',
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
                                _isSearchingLanguage
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
                            searchLanguages(value);
                          },
                        ),
                        const SizedBox(height: 8),

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
                                      _languageSearchController.text = language;
                                      _language = language;
                                      _searchedLanguages = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 16),
                        // Extra fields for Volunteer
                        if (_accountType == 'Volunteer') ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  hintText:
                                      'Type to search and select languages',
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
                                  searchSpokenLanguages(value);
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_searchedSpokenLanguages.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: AppColors.islamicGreen200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.islamicGreen500
                                            .withAlpha(30),
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
                                                  color:
                                                      AppColors.islamicGreen400,
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
                                                    _selectedSpokenLanguages
                                                        .remove(lang);
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _bioController,
                            label: 'Short Bio',
                            hint: 'Tell us about yourself',
                            keyboardType: TextInputType.multiline,
                            required: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your bio';
                              }
                              if (value.length < 10) {
                                return 'Bio must be at least 10 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _certTitleController,
                            label: 'Certification Title',
                            hint: 'e.g., Quran Recitation Level 1',
                            required: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter certification title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _certInstitutionController,
                            label: 'Certification Institution / Sheikh',
                            hint: 'e.g., Sheikh Ahmad Al-Mansour',
                            required: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter certification institution';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                                        : 'Upload Certification',
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
                          const SizedBox(height: 16),
                        ],

                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          required: true,
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
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          required: true,
                          suffixIcon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.islamicGreen600,
                          ),
                          onSuffixIconPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppColors.islamicGreen500,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            shadowColor: AppColors.islamicGreen600.withAlpha(
                              (255 * 0.7).toInt(),
                            ),
                            elevation: 8,
                          ),
                          onPressed: () {
                            submitForm();
                          },
                          child: Text(
                            _accountType == 'Volunteer'
                                ? 'Create Volunteer Account'
                                : 'Create User Account',
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                              color: AppColors.islamicGreen600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Footer Quran quote
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
