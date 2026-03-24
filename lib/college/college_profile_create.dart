import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class CollegeProfileCreate extends StatefulWidget {
  const CollegeProfileCreate({super.key});

  @override
  State<CollegeProfileCreate> createState() => _CollegeProfileCreateState();
}

class _CollegeProfileCreateState extends State<CollegeProfileCreate> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();

  File? selectedImage;
  String? uploadedImageUrl;
  bool loading = false;

  final user = FirebaseAuth.instance.currentUser!;
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  final ImagePicker picker = ImagePicker();

  // 🔑 ImgBB API KEY
  static const String imgbbKey = "db299c9cb584c2748df2222080655594";

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked != null) {
        setState(() {
          selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image pick failed: $e"),
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

  // ---------------- SAVE PROFILE ----------------
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload college image"),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      uploadedImageUrl = await uploadImageToImgBB(selectedImage!);

      await db.child("users/${user.uid}").update({
        "profileCompleted": true,
      });

      await db.child("collegeProfiles/${user.uid}").set({
        "collegeName": name.text.trim(),
        "email": user.email,
        "location": location.text.trim(),
        "description": description.text.trim(),
        "profileImage": uploadedImageUrl,
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile created successfully!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
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
      setState(() => loading = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Create College Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // IMAGE PICKER
              GestureDetector(
                onTap: loading ? null : pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 2,
                    ),
                    image: selectedImage != null
                        ? DecorationImage(
                            image: FileImage(selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: selectedImage == null
                        ? Colors.white
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 60,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Tap to upload college logo/banner",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF1E3A8A),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
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
                  onPressed: loading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Create Profile",
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