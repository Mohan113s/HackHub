import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class EditEventPage extends StatefulWidget {
  final String eventKey;
  final Map<String, dynamic> eventData;

  const EditEventPage({
    super.key,
    required this.eventKey,
    required this.eventData,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("hackathons");
  
  // Controllers - matching AddHackathonPage fields
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _endDateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _prizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;
  late TextEditingController _registrationLinkController;
  
  String? _currentPosterUrl;
  File? _selectedImage;
  bool _isLoading = false;
  // ignore: unused_field
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.eventData['title'] ?? '');
    _dateController = TextEditingController(text: widget.eventData['date'] ?? '');
    _endDateController = TextEditingController(text: widget.eventData['endDate'] ?? '');
    _timeController = TextEditingController(text: widget.eventData['time'] ?? '');
    _locationController = TextEditingController(text: widget.eventData['location'] ?? '');
    _prizeController = TextEditingController(text: widget.eventData['prize'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    _rulesController = TextEditingController(text: widget.eventData['rules'] ?? '');
    _registrationLinkController = TextEditingController(text: widget.eventData['registrationLink'] ?? '');
    
    _currentPosterUrl = widget.eventData['poster'] ?? 
                       widget.eventData['image'] ?? 
                       widget.eventData['posterUrl'] ?? 
                       widget.eventData['imageUrl'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _endDateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _prizeController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _registrationLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Image Source",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1E3A8A)),
                title: const Text("Camera"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1E3A8A)),
                title: const Text("Gallery"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _currentPosterUrl;

    setState(() => _isUploadingImage = true);

    try {
      // Create a unique filename
      final String fileName = 'event_posters/${widget.eventKey}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() => _isUploadingImage = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image upload failed: ${e.toString()}"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return _currentPosterUrl;
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload new image if selected
      String? posterUrl = await _uploadImage();

      // Prepare updated data - matching AddHackathonPage structure
      final Map<String, dynamic> updatedData = {
        'title': _titleController.text.trim(),
        'date': _dateController.text.trim(),
        'endDate': _endDateController.text.trim(),
        'time': _timeController.text.trim(),
        'location': _locationController.text.trim(),
        'prize': _prizeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rules': _rulesController.text.trim(),
        'registrationLink': _registrationLinkController.text.trim(),
        'imageUrl': posterUrl ?? '',
        'poster': posterUrl ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
        // Keep existing fields
        'hackathonId': widget.eventData['hackathonId'] ?? widget.eventKey,
        'collegeId': widget.eventData['collegeId'],
        'createdAt': widget.eventData['createdAt'],
      };

      // Update in Firebase Realtime Database
      await _dbRef.child(widget.eventKey).update(updatedData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Event updated successfully!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Go back after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Event",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _updateEvent,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
              label: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  SizedBox(height: 16),
                  Text(
                    "Updating event...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Event Poster Section
                  const Text(
                    "Event Poster",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPosterPicker(),
                  const SizedBox(height: 24),

                  // Form Fields - matching AddHackathonPage
                  _buildTextField(
                    controller: _titleController,
                    label: "Hackathon Title *",
                    hint: "Enter event title",
                    icon: Icons.event_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  // Event Registration Dates Section
                  const Text(
                    "Event Registration Dates",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _dateController,
                    label: "Start Date (DD-MM-YYYY) *",
                    hint: "Enter start date",
                    icon: Icons.calendar_today_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _endDateController,
                    label: "End Date (DD-MM-YYYY) *",
                    hint: "Enter end date",
                    icon: Icons.calendar_today_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _timeController,
                    label: "Time *",
                    hint: "Enter event time",
                    icon: Icons.access_time_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: "Location *",
                    hint: "Enter venue/platform",
                    icon: Icons.location_on_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _prizeController,
                    label: "Prize Pool",
                    hint: "e.g., ₹50,000",
                    icon: Icons.emoji_events_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: "Description",
                    hint: "Enter event description",
                    icon: Icons.description_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _rulesController,
                    label: "Rules & Guidelines",
                    hint: "Enter event rules",
                    icon: Icons.rule_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registrationLinkController,
                    label: "Registration Link *",
                    hint: "https://forms.google.com/...",
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    required: true,
                  ),
                  const SizedBox(height: 32),

                  // Update Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateEvent,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_isLoading ? "Updating..." : "Update Event"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildPosterPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              )
            : _currentPosterUrl != null && _currentPosterUrl!.isNotEmpty
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: _currentPosterUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                          ),
                          errorWidget: (context, url, error) => _buildPlaceholder(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 48,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Tap to upload event poster",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Recommended: 1920x1080px",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }
}