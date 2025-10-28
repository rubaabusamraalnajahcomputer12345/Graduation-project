// lib/pages/admin/add_lesson_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config.dart';

class AddLessonPage extends StatefulWidget {
  @override
  _AddLessonPageState createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _uploadingStep;

  // Form data
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final _estimatedTimeController = TextEditingController();

  String _selectedCategory = '';
  String _selectedLevel = '';
  List<LessonStep> _steps = [];

  // Controllers for step fields
  final Map<String, Map<String, TextEditingController>> _stepControllers = {};

  // Validation errors
  Map<String, String> _errors = {};

  final List<Category> _categories = [
    Category(value: 'spiritual', label: 'Spiritual'),
    Category(value: 'psychological', label: 'Psychological'),
    Category(value: 'physical', label: 'Physical'),
    Category(value: 'social', label: 'Social'),
  ];

  final List<Level> _levels = [
    Level(value: 'beginner', label: 'Beginner'),
    Level(value: 'intermediate', label: 'Intermediate'),
    Level(value: 'advanced', label: 'Advanced'),
  ];

  String _generateStepId() {
    return 'step-${DateTime.now().millisecondsSinceEpoch}-${(100 + (900 * (DateTime.now().microsecond / 1000000))).round()}';
  }

  void _addStep() {
    setState(() {
      final stepId = _generateStepId();
      _steps.add(
        LessonStep(
          id: stepId,
          stepNumber: _steps.length + 1,
          title: '',
          description: '',
          mediaType: 'image',
          mediaFile: null,
          mediaUrl: '',
          mediaPreview: '',
        ),
      );

      // Initialize controllers for the new step
      _stepControllers[stepId] = {
        'stepNumber': TextEditingController(text: (_steps.length).toString()),
        'title': TextEditingController(),
        'description': TextEditingController(),
      };
    });
  }

  // Initialize controllers for existing steps if they don't have them
  void _ensureStepControllers(String stepId) {
    if (!_stepControllers.containsKey(stepId)) {
      final step = _steps.firstWhere((s) => s.id == stepId);
      _stepControllers[stepId] = {
        'stepNumber': TextEditingController(text: step.stepNumber.toString()),
        'title': TextEditingController(text: step.title),
        'description': TextEditingController(text: step.description),
      };
    }
  }

  void _removeStep(String stepId) {
    setState(() {
      _steps.removeWhere((step) => step.id == stepId);
      // Reorder step numbers
      for (int i = 0; i < _steps.length; i++) {
        _steps[i].stepNumber = i + 1;
        // Update the controller text for the reordered step
        if (_stepControllers.containsKey(_steps[i].id)) {
          _stepControllers[_steps[i].id]!['stepNumber']!.text =
              (i + 1).toString();
        }
      }

      // Dispose controllers for the removed step
      if (_stepControllers.containsKey(stepId)) {
        _stepControllers[stepId]!.values.forEach(
          (controller) => controller.dispose(),
        );
        _stepControllers.remove(stepId);
      }
    });
  }

  void _updateStep(String stepId, String field, dynamic value) {
    setState(() {
      final stepIndex = _steps.indexWhere((step) => step.id == stepId);
      if (stepIndex != -1) {
        final step = _steps[stepIndex];
        switch (field) {
          case 'stepNumber':
            step.stepNumber = value;
            break;
          case 'title':
            step.title = value;
            break;
          case 'description':
            step.description = value;
            break;
          case 'mediaFile':
            step.mediaFile = value;
            break;
          case 'mediaBytes':
            step.mediaBytes = value;
            break;
          case 'mediaUrl':
            step.mediaUrl = value;
            break;
          case 'mediaPreview':
            step.mediaPreview = value;
            break;
          case 'mediaFileName':
            step.mediaFileName = value;
            break;
          case 'mediaType':
            step.mediaType = value;
            // Clear media data when switching types
            if (value == 'video') {
              step.mediaFile = null;
              step.mediaBytes = null;
              step.mediaFileName = null;
              step.mediaPreview = '';
            }
            break;
        }
      }
    });
  }

  Future<void> _handleFileUpload(String stepId) async {
    print('[DEBUG] _handleFileUpload called for stepId: $stepId');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        print('[DEBUG] No file selected or result.files is empty');
        return;
      }

      final picked = result.files.first;
      print('[DEBUG] Picked file: ${picked.name}');

      File? file;
      int fileSize;
      if (kIsWeb) {
        if (picked.bytes == null) {
          print('[DEBUG] Picked bytes are null on web');
          _showErrorSnackBar('Failed to read selected file');
          return;
        }
        fileSize = picked.size;
        print('[DEBUG] Picked file size (web): $fileSize bytes');
        if (fileSize > 10 * 1024 * 1024) {
          print('[DEBUG] File too large: $fileSize bytes');
          _showErrorSnackBar(
            'File too large. Please upload an image smaller than 10MB.',
          );
          return;
        }
      } else {
        if (picked.path == null) {
          print('[DEBUG] Picked file path is null');
          _showErrorSnackBar(
            'Selected file path is unavailable on this platform.',
          );
          return;
        }
        print('[DEBUG] Picked file before file');
        file = File(picked.path!);
        print('[DEBUG] Picked file after file');
        fileSize = await file.length();
        print('[DEBUG] Picked file size: $fileSize bytes');
        if (fileSize > 10 * 1024 * 1024) {
          print('[DEBUG] File too large: $fileSize bytes');
          _showErrorSnackBar(
            'File too large. Please upload an image smaller than 10MB.',
          );
          return;
        }
      }

      setState(() {
        _uploadingStep = stepId;
      });
      print('[DEBUG] Set _uploadingStep to $stepId');

      // Update step with chosen media
      if (kIsWeb) {
        _updateStep(stepId, 'mediaBytes', picked.bytes);
        _updateStep(stepId, 'mediaFileName', picked.name);
        print('[DEBUG] Updated step $stepId with mediaBytes');
      } else {
        _updateStep(stepId, 'mediaFile', file);
        print('[DEBUG] Updated step $stepId with mediaFile');
        _updateStep(stepId, 'mediaPreview', file!.path);
        print('[DEBUG] Updated step $stepId with mediaPreview');
      }

      _showSuccessSnackBar('Image preview created successfully');
    } catch (error) {
      print('[DEBUG] File upload error: $error');
      _showErrorSnackBar('Failed to process the uploaded file');
    } finally {
      setState(() {
        _uploadingStep = null;
      });
      print('[DEBUG] Reset _uploadingStep to null');
    }
  }

  Future<String> _uploadMediaFile(File file) async {
    final fileName =
        'lesson_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final bytes = await file.readAsBytes();
    final response = await Supabase.instance.client.storage
        .from('Lessons')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    if (response.isEmpty) {
      throw Exception('Failed to upload media file');
    }
    final publicUrl = Supabase.instance.client.storage
        .from('Lessons')
        .getPublicUrl(fileName);
    return publicUrl;
  }

  Future<String> _uploadBytesToSupabase(
    Uint8List bytes,
    String originalName,
  ) async {
    final sanitizedName =
        originalName.trim().isEmpty
            ? 'lesson_${DateTime.now().millisecondsSinceEpoch}.png'
            : 'lesson_${DateTime.now().millisecondsSinceEpoch}_$originalName';
    final response = await Supabase.instance.client.storage
        .from('Lessons')
        .uploadBinary(
          sanitizedName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    if (response.isEmpty) {
      throw Exception('Failed to upload media file');
    }
    final publicUrl = Supabase.instance.client.storage
        .from('Lessons')
        .getPublicUrl(sanitizedName);
    return publicUrl;
  }

  bool _validateForm() {
    setState(() {
      _errors.clear();
    });

    // lessonId is generated on the backend

    if (_titleController.text.trim().isEmpty) {
      _errors['title'] = 'Title is required';
    }

    if (_descriptionController.text.trim().isEmpty) {
      _errors['description'] = 'Description is required';
    }

    if (_selectedCategory.isEmpty) {
      _errors['category'] = 'Category is required';
    }

    if (_selectedLevel.isEmpty) {
      _errors['level'] = 'Level is required';
    }

    final estimatedTime = int.tryParse(_estimatedTimeController.text) ?? 0;
    if (estimatedTime <= 0) {
      _errors['estimatedTime'] = 'Estimated time must be greater than 0';
    }

    if (_steps.isEmpty) {
      _errors['steps'] = 'At least one step is required';
    }

    // Validate each step
    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      if (step.title.trim().isEmpty) {
        _errors['step-${step.id}-title'] = 'Step ${i + 1} title is required';
      }
      if (step.description.trim().isEmpty) {
        _errors['step-${step.id}-description'] =
            'Step ${i + 1} description is required';
      }
    }

    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload media files for steps
      List<Map<String, dynamic>> stepsWithMedia = [];

      for (final step in _steps) {
        String mediaUrl = step.mediaUrl;

        // Only upload if it's an image type with actual file data
        if (step.mediaType == 'image' &&
            (step.mediaBytes != null || step.mediaFile != null)) {
          try {
            if (step.mediaBytes != null) {
              mediaUrl = await _uploadBytesToSupabase(
                step.mediaBytes!,
                step.mediaFileName ?? 'upload.png',
              );
            } else if (step.mediaFile != null) {
              mediaUrl = await _uploadMediaFile(step.mediaFile!);
            }
          } catch (error) {
            print('Failed to upload media for step: ${step.id}, $error');
            _showErrorSnackBar(
              'Failed to upload media for step ${step.stepNumber}',
            );
            return;
          }
        }
        // For video type, mediaUrl is already set from the text field

        stepsWithMedia.add({
          'stepNumber': step.stepNumber,
          'title': step.title,
          'description': step.description,
          'mediaUrl': mediaUrl,
          'mediaType': step.mediaType,
        });
      }

      // Prepare lesson data per backend schema
      final lessonData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'level': _selectedLevel,
        'icon': _iconController.text,
        'estimatedTime': int.parse(_estimatedTimeController.text),
        // createdAt is optional; backend defaults to now if omitted
        'steps': stepsWithMedia,
      };

      // Submit to backend
      final response = await http.post(
        Uri.parse(addLessonUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(lessonData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create lesson');
      }

      _showSuccessSnackBar(
        'Lesson "${_titleController.text}" has been created with ${_steps.length} steps',
      );
    } catch (error) {
      print('Submit error: $error');
      _showErrorSnackBar(
        'An error occurred while creating the lesson. Please try again.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    // Dispose all step controllers
    _stepControllers.values.forEach((controllers) {
      controllers.values.forEach((controller) => controller.dispose());
    });
    _stepControllers.clear();

    // Dispose main form controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _estimatedTimeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.islamicGreen50,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  /*  OutlinedButton.icon(
                    onPressed: _handleCancel,
                    icon: Icon(Icons.arrow_back, size: 16),
                    label: Text('Back to Lessons'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.lessonsTitle,
                      side: BorderSide(color: AppColors.lessonsBorder),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  SizedBox(width: 16), */
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Lesson',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lessonsTitle,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create a comprehensive educational lesson with steps and media',
                          style: TextStyle(
                            color: AppColors.lessonsSubtitle,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Lesson Info Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.lessonsBorder),
                ),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.lessonsTitle,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lesson Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lessonsTitle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Title *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lessonsTitle,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter lesson title',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('title')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('title')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.lessonsHumanBadge,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                if (_errors.containsKey('title'))
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      _errors['title']!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lessonsTitle,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter detailed lesson description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      _errors.containsKey('description')
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      _errors.containsKey('description')
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.lessonsHumanBadge,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          if (_errors.containsKey('description'))
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                _errors['description']!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Category, Level, and Estimated Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lessonsTitle,
                                  ),
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      _selectedCategory.isEmpty
                                          ? null
                                          : _selectedCategory,
                                  decoration: InputDecoration(
                                    hintText: 'Select category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('category')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('category')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.lessonsHumanBadge,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items:
                                      _categories.map((category) {
                                        return DropdownMenuItem(
                                          value: category.value,
                                          child: Text(category.label),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value ?? '';
                                    });
                                  },
                                ),
                                if (_errors.containsKey('category'))
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      _errors['category']!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lessonsTitle,
                                  ),
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      _selectedLevel.isEmpty
                                          ? null
                                          : _selectedLevel,
                                  decoration: InputDecoration(
                                    hintText: 'Select level',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('level')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('level')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.lessonsHumanBadge,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items:
                                      _levels.map((level) {
                                        return DropdownMenuItem(
                                          value: level.value,
                                          child: Text(level.label),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLevel = value ?? '';
                                    });
                                  },
                                ),
                                if (_errors.containsKey('level'))
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      _errors['level']!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Time (minutes) *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lessonsTitle,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _estimatedTimeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 30',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('estimatedTime')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            _errors.containsKey('estimatedTime')
                                                ? Colors.red
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.lessonsHumanBadge,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                if (_errors.containsKey('estimatedTime'))
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      _errors['estimatedTime']!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon (Emoji)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lessonsTitle,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _iconController,
                            style: TextStyle(fontSize: 24),
                            decoration: InputDecoration(
                              hintText: '🕌 (Enter an emoji)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.lessonsHumanBadge,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter an emoji to represent this lesson',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.lessonsSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Steps Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.lessonsBorder),
                ),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.lessonsTitle,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lesson Steps',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lessonsTitle,
                            ),
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addStep,
                            icon: Icon(Icons.add, size: 16),
                            label: Text('Add Step'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lessonsHumanBadge,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errors.containsKey('steps'))
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _errors['steps']!,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      SizedBox(height: 24),

                      // Steps List
                      if (_steps.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No steps added yet. Click "Add Step" to get started.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _steps.length,
                          separatorBuilder:
                              (context, index) => SizedBox(height: 24),
                          itemBuilder: (context, index) {
                            final step = _steps[index];
                            return _buildStepCard(step, index);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 16,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.lessonsTitle,
                      side: BorderSide(color: AppColors.lessonsBorder),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lessonsHumanBadge,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Creating...'),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 16),
                                  SizedBox(width: 8),
                                  Text('Create Lesson'),
                                ],
                              ),
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

  Widget _buildStepCard(LessonStep step, int index) {
    // Ensure controllers exist for this step
    _ensureStepControllers(step.id);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1,

      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Header
            Row(
              children: [
                Text(
                  'Step ${step.stepNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lessonsTitle,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => _removeStep(step.id),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Step',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Step Number and Title Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lessonsTitle,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        controller:
                            _stepControllers[step.id]?['stepNumber'] ??
                            TextEditingController(
                              text: step.stepNumber.toString(),
                            ),
                        onChanged: (value) {
                          _updateStep(
                            step.id,
                            'stepNumber',
                            int.tryParse(value) ?? 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lessonsTitle,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter step title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color:
                                  _errors.containsKey('step-${step.id}-title')
                                      ? Colors.red
                                      : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color:
                                  _errors.containsKey('step-${step.id}-title')
                                      ? Colors.red
                                      : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.lessonsHumanBadge,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        controller:
                            _stepControllers[step.id]?['title'] ??
                            TextEditingController(text: step.title),
                        onChanged: (value) {
                          _updateStep(step.id, 'title', value);
                        },
                      ),
                      if (_errors.containsKey('step-${step.id}-title'))
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            _errors['step-${step.id}-title']!,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lessonsTitle,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter step description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            _errors.containsKey('step-${step.id}-description')
                                ? Colors.red
                                : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            _errors.containsKey('step-${step.id}-description')
                                ? Colors.red
                                : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.lessonsHumanBadge,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  controller:
                      _stepControllers[step.id]?['description'] ??
                      TextEditingController(text: step.description),
                  onChanged: (value) {
                    _updateStep(step.id, 'description', value);
                  },
                ),
                if (_errors.containsKey('step-${step.id}-description'))
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      _errors['step-${step.id}-description']!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16),

            // Media Type and Upload
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lessonsTitle,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: step.mediaType,
                  decoration: InputDecoration(
                    hintText: 'Select media type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onChanged: (value) {
                    _updateStep(step.id, 'mediaType', value ?? 'image');
                  },
                ),
                SizedBox(height: 16),

                // Conditional Media Input based on type
                if (step.mediaType == 'image') ...[
                  Text(
                    'Image Upload',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lessonsTitle,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (step.mediaPreview.isEmpty)
                    GestureDetector(
                      onTap: () => _handleFileUpload(step.id),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              _uploadingStep == step.id
                                  ? 'Processing...'
                                  : 'Click to upload or drag and drop',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Supports PNG, JPG, GIF up to 10MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(step.mediaPreview),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleFileUpload(step.id),
                                icon: Icon(Icons.cloud_upload, size: 16),
                                label: Text('Change'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  _updateStep(step.id, 'mediaFile', null);
                                  _updateStep(step.id, 'mediaBytes', null);
                                  _updateStep(step.id, 'mediaFileName', null);
                                  _updateStep(step.id, 'mediaPreview', '');
                                  _updateStep(step.id, 'mediaUrl', '');
                                  _updateStep(step.id, 'mediaType', 'image');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.all(8),
                                  minimumSize: Size(40, 40),
                                ),
                                child: Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  Text(
                    'Video Link',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lessonsTitle,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter video URL (YouTube, Vimeo, etc.)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      _updateStep(step.id, 'mediaUrl', value);
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enter a valid video URL from supported platforms',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lessonsSubtitle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LessonStep {
  String id;
  int stepNumber;
  String title;
  String description;
  String mediaType; // "video" or "image"
  File? mediaFile;
  Uint8List? mediaBytes;
  String? mediaFileName;
  String mediaUrl;
  String mediaPreview;

  LessonStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.mediaType = 'image',
    this.mediaFile,
    this.mediaBytes,
    this.mediaFileName,
    required this.mediaUrl,
    required this.mediaPreview,
  });
}

class Category {
  final String value;
  final String label;

  Category({required this.value, required this.label});
}

class Level {
  final String value;
  final String label;

  Level({required this.value, required this.label});
}
