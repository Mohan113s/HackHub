import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class CollegeProfileEdit extends StatefulWidget {
  const CollegeProfileEdit({super.key});

  @override
  State<CollegeProfileEdit> createState() => _CollegeProfileEditState();
}

class _CollegeProfileEditState extends State<CollegeProfileEdit> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();

  File? selectedImage;
  String? imageUrl;

  bool loading = true;
  bool saving = false;

  final user = FirebaseAuth.instance.currentUser!;
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  final ImagePicker picker = ImagePicker();

  // 🔑 ImgBB API KEY
  static const String imgbbKey = "db299c9cb584c2748df2222080655594";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> loadProfile() async {
    try {
      final snapshot =
          await db.child("collegeProfiles/${user.uid}").get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        setState(() {
          name.text = data['collegeName'] ?? '';
          location.text = data['location'] ?? '';
          description.text = data['description'] ?? '';
          imageUrl = data['profileImage'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading profile: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (picked != null) {
        setState(() {
          selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ---------------- UPLOAD IMAGE (IMGBB) ----------------
  Future<String> uploadImageToImgBB(File image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbKey"),
      body: {"image": base64Image},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]["url"];
    } else {
      throw Exception("Image upload failed");
    }
  }

  // ---------------- UPDATE PROFILE ----------------
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      String? finalImageUrl = imageUrl;

      if (selectedImage != null) {
        finalImageUrl = await uploadImageToImgBB(selectedImage!);
      }

      await db.child("collegeProfiles/${user.uid}").update({
        "collegeName": name.text.trim(),
        "location": location.text.trim(),
        "description": description.text.trim(),
        "profileImage": finalImageUrl,
        "updatedAt": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E3A8A),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Edit College Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // PROFILE IMAGE
              Stack(
                children: [
                  GestureDetector(
                    onTap: saving ? null : pickImage,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : null,
                        child: selectedImage == null && imageUrl == null
                            ? const Icon(
                                Icons.school_rounded,
                                size: 60,
                                color: Color(0xFF64748B),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                "Tap to change profile image",
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              TextFormField(
                initialValue: user.email,
                enabled: false,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.email_rounded,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                ),
              ),

              const SizedBox(height: 16),

              // COLLEGE NAME
              TextFormField(
                controller: name,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: "College Name *",
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // LOCATION
              TextFormField(
                controller: location,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: "Location *",
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // DESCRIPTION
              TextFormField(
                controller: description,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: "About College (Optional)",
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Update Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}