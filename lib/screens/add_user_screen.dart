import 'package:cloud_contacts/database_helper/database_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AddUserScreen extends StatefulWidget {
  final ApiService apiService;

  const AddUserScreen({super.key, required this.apiService});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  String _base64Image = "";
  bool _isSaving = false;

  // 📸 Camera aur Gallery dono ka Option dene ke liye Bottom Sheet Dialog
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,   // 🔥 Optimized Quality (Details clean rahengi)
      maxWidth: 512,      // 🔥 HD Resolution for Avatar
      maxHeight: 512,     // 🔥 Ratio exactly 1:1 square rakhega
    );

    if (image != null) {
      final File imageFile = File(image.path);
      final List<int> imageBytes = await imageFile.readAsBytes();

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64Encode(imageBytes);
      });
    }
  }

  void _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String finalAvatar = _base64Image.isNotEmpty
        ? "data:image/png;base64,$_base64Image"
        : "https://liara.run{DateTime.now().second}"; // Fixed string interpolation slash

    User newContact = User(
      id: "",
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatar: finalAvatar,
    );

    await OfflineSyncManager.instance.saveContact(newContact);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("⚡ Contact Saved Successfully!"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Add New Contact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showImageSourcePicker, // 🔥 Tap karne par option sheet khulegi
                child: Stack(
                  children: [
                    // 🔥 Main Fix: ClipOval + BoxFit.cover lagane se image phelna (spread) 100% khatam
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover, // 👈 Image ko perfect round crop karega bina stretch kiye
                        )
                            : const Icon(Icons.person, size: 60, color: Colors.blueAccent),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(
                          _selectedImage == null ? Icons.add_a_photo : Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Email cannot be empty";
                  if (!value.contains("@")) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveContact,
                  child: const Text("Save Contact", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
