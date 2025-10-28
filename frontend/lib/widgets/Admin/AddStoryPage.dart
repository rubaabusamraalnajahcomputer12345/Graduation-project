import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config.dart';
import '../../constants/colors.dart';

// Islamic Theme Colors
class IslamicColors {}

class AddStoryPage extends StatefulWidget {
  final VoidCallback? onBackToStories;

  const AddStoryPage({Key? key, this.onBackToStories}) : super(key: key);

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _journeyController = TextEditingController();
  final _afterIslamController = TextEditingController();
  final _quoteController = TextEditingController();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form state
  String _selectedType = 'image';
  // String _selectedLanguage = 'English';
  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _backgroundController.dispose();
    _journeyController.dispose();
    _afterIslamController.dispose();
    _quoteController.dispose();
    _nameController.dispose();
    _countryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Story',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPanelGreen800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a new revert story to inspire others',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.adminPanelGreen600,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed:
                    widget.onBackToStories ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPanelGreen600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 8),
                    Text('Back to Stories'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.adminPanelGreen100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Story Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPanelGreen800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title and Type Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          'Story Title',
                          'Enter a compelling title',
                          _titleController,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          'Media Type',
                          ['image', 'video'],
                          _selectedType,
                          (value) => setState(() => _selectedType = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    'Description',
                    'Brief description of the story...',
                    _descriptionController,
                    maxLines: 2,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Author Information Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Author Name',
                          'Enter author name',
                          _nameController,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Country',
                          'Enter author country',
                          _countryController,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Background
                  _buildTextField(
                    'Background',
                    'Author\'s background before Islam...',
                    _backgroundController,
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Journey to Islam
                  _buildTextField(
                    'Journey to Islam',
                    'How they discovered and embraced Islam...',
                    _journeyController,
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // After Islam
                  _buildTextField(
                    'After Islam',
                    'Life after accepting Islam...',
                    _afterIslamController,
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Quote and Tags Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          'Inspirational Quote',
                          'A meaningful quote from the story',
                          _quoteController,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Tags',
                          'e.g. conversion, faith, journey',
                          _tagsController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Media Upload Section
                  _buildMediaUploadSection(),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            widget.onBackToStories ??
                            () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.adminPanelGreen700,
                          side: const BorderSide(
                            color: AppColors.adminPanelGreen300,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSaveStory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminPanelGreen600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Create Story'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.adminPanelGreen700,
            ),
            children:
                required
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen500),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator:
              required
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.adminPanelGreen700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.adminPanelGreen500),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items:
              options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.toUpperCase()),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildMediaUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Upload Media',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.adminPanelGreen700,
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  _selectedFile = result.files.single;
                });
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading)
                    const CircularProgressIndicator()
                  else
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  const SizedBox(height: 8),
                  if (_selectedFile != null) ...[
                    Text(
                      'Selected: ${_selectedFile!.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.adminPanelGreen600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          _isUploading
                              ? null
                              : () async {
                                setState(() {
                                  _isUploading = true;
                                });
                                final url = await _uploadFile(_selectedFile!);
                                setState(() {
                                  _isUploading = false;
                                  if (url.isNotEmpty) {
                                    _uploadedFileUrl = url;
                                    _showSnackbar(
                                      'File uploaded successfully!',
                                    );
                                  } else {
                                    _showSnackbar('Failed to upload file');
                                  }
                                });
                              },
                      child: Text(
                        _isUploading ? 'Uploading...' : 'Upload File',
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Click to upload or drag and drop your ${_selectedType} file',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Media upload is required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_uploadedFileUrl != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'File uploaded successfully!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _uploadFile(PlatformFile file) async {
    Uint8List? fileBytes;
    final fileName = file.name;

    if (file.bytes != null) {
      fileBytes = file.bytes;
    } else if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
    }

    if (fileBytes == null) {
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
        final publicUrl = Supabase.instance.client.storage
            .from('story')
            .getPublicUrl(fileName);
        return publicUrl;
      }
    } catch (e) {
      print('Exception during upload: $e');
    }

    return '';
  }

  void _handleSaveStory() async {
    if (_formKey.currentState!.validate()) {
      // Check if media is uploaded
      if (_uploadedFileUrl == null || _uploadedFileUrl!.isEmpty) {
        _showSnackbar(
          'Please upload a media file (image or video) before creating the story',
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final response = await http.post(
          Uri.parse(addStoryUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'background': _backgroundController.text.trim(),
            'journeyToIslam': _journeyController.text.trim(),
            'afterIslam': _afterIslamController.text.trim(),
            'type': _selectedType,
            'mediaUrl': _uploadedFileUrl,
            'quote': _quoteController.text.trim(),
            'name': _nameController.text.trim(),
            'country': _countryController.text.trim(),
            'tags':
                _tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
          }),
        );

        if (response.statusCode == 200) {
          _showSnackbar('Story created successfully!');
          if (widget.onBackToStories != null) {
            widget.onBackToStories!();
          } else {
            Navigator.pop(context);
          }
        } else {
          final errorData = json.decode(response.body);
          _showSnackbar(
            'Failed to create story: ${errorData['message'] ?? 'Unknown error'}',
          );
        }
      } catch (e) {
        _showSnackbar('Error creating story: ${e.toString()}');
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.adminPanelGreen600,
      ),
    );
  }
}
