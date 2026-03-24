import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;

class AddHackathonPage extends StatefulWidget {
  final Function()? onPosted;

  const AddHackathonPage({super.key, this.onPosted});

  @override
  State<AddHackathonPage> createState() => _AddHackathonPageState();
}

class _AddHackathonPageState extends State<AddHackathonPage> {

  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final endDateController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();
  final prizeController = TextEditingController();
  final descriptionController = TextEditingController();
  final rulesController = TextEditingController();
  final linkController = TextEditingController();

  bool isLoading = false;

  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  final DatabaseReference db = FirebaseDatabase.instance.ref();

  static const String imgbbApiKey = "db299c9cb584c2748df2222080655594";

  // ================= IMAGE PICK =================

  Future<void> pickImage() async {
    try {

      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Poster',
            toolbarColor: const Color(0xFF1E3A8A),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Adjust Poster',
          ),
        ],
      );

      if (croppedFile == null) return;

      if (!mounted) return;

      setState(() {
        selectedImage = File(croppedFile.path);
      });

    } catch (e) {

      debugPrint("Image pick error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image selection failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= IMAGE UPLOAD =================

  Future<String> uploadImageToImgBB(File image) async {

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey"),
      body: {"image": base64Image},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true &&
        data["data"] != null) {

      return data["data"]["url"];

    } else {
      throw Exception("Image upload failed");
    }
  }

  // ================= POST EVENT =================

  Future<void> postHackathon() async {

    if (!_formKey.currentState!.validate()) return;

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload poster image"),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      final imageUrl = await uploadImageToImgBB(selectedImage!);

      final hackathonId = db.child("hackathons").push().key;

      await db.child("hackathons/$hackathonId").set({

        "hackathonId": hackathonId,
        "collegeId": uid,
        "title": titleController.text.trim(),
        "date": dateController.text.trim(),
        "endDate": endDateController.text.trim(),
        "time": timeController.text.trim(),
        "location": locationController.text.trim(),
        "prize": prizeController.text.trim(),
        "description": descriptionController.text.trim(),
        "rules": rulesController.text.trim(),
        "registrationLink": linkController.text.trim(),
        "imageUrl": imageUrl,
        "poster": imageUrl,
        "createdAt": ServerValue.timestamp,

      });

      _clearForm();

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Event posted successfully!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      widget.onPosted?.call();

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      if (mounted) {

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {

    titleController.clear();
    dateController.clear();
    endDateController.clear();
    timeController.clear();
    locationController.clear();
    prizeController.clear();
    descriptionController.clear();
    rulesController.clear();
    linkController.clear();

    setState(() {
      selectedImage = null;
    });
  }

  @override
  void dispose() {

    titleController.dispose();
    dateController.dispose();
    endDateController.dispose();
    timeController.dispose();
    locationController.dispose();
    prizeController.dispose();
    descriptionController.dispose();
    rulesController.dispose();
    linkController.dispose();

    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Post Hackathon / Event",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
      ),

      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Event Poster",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: pickImage,

                    child: Container(

                      height: 200,
                      width: double.infinity,

                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: selectedImage == null

                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 60,
                                  color: Color(0xFF3B82F6),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Tap to upload poster",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )

                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _field("Hackathon Title *", titleController),
                  _field("Start Date *", dateController),
                  _field("End Date *", endDateController),
                  _field("Time *", timeController),
                  _field("Location *", locationController),
                  _field("Prize Pool", prizeController),
                  _field("Description", descriptionController, maxLines: 4),
                  _field("Rules", rulesController, maxLines: 3),
                  _field("Registration Link *", linkController),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(

                      onPressed: isLoading ? null : postHackathon,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                      ),

                      child: const Text(
                        "Post Event",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)

            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 16),

      child: TextFormField(

        controller: controller,
        maxLines: maxLines,

        validator: (v) {

          if (label.contains('*') && (v == null || v.isEmpty)) {
            return "Required field";
          }

          return null;
        },

        decoration: InputDecoration(

          labelText: label,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}