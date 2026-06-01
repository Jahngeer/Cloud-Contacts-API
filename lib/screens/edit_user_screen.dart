import 'package:cloud_contacts/database_helper/database_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class EditUserScreen extends StatefulWidget {
  final User user;
  final ApiService apiService;

  const EditUserScreen({super.key, required this.user, required this.apiService});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  File? _selectedImage;
  late String _currentAvatar;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _currentAvatar = widget.user.avatar ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
      imageQuality: 80,   // 🔥 High performance compression matching Add Screen
      maxWidth: 512,      // 🔥 1:1 Aspect ratio configuration
      maxHeight: 512,
    );

    if (image != null) {
      final File imageFile = File(image.path);
      final List<int> imageBytes = await imageFile.readAsBytes();

      setState(() {
        _selectedImage = imageFile;
        _currentAvatar = "data:image/png;base64,${base64Encode(imageBytes)}";
      });
    }
  }

  void _updateContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    User updatedContact = User(
      id: widget.user.id,
      localId: widget.user.localId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatar: _currentAvatar,
    );

    await OfflineSyncManager.instance.updateContact(updatedContact);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.green, content: Text("⚡ Contact Updated Successfully!")),
    );
    Navigator.pop(context);
  }

  // 🔥 Is Render Helper ko Widget base kiya taake error safe image load ho sake
  Widget _buildAvatarWidget() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, width: 100, height: 100, fit: BoxFit.cover);
    }

    if (_currentAvatar.startsWith('http') || _currentAvatar.isEmpty) {
      return Image.network(
        _currentAvatar.isNotEmpty ? _currentAvatar : "https://w3schools.com",
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.blueAccent),
      );
    }

    try {
      String cleanBase64 = _currentAvatar;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',')[1];
      }
      return Image.memory(
        base64Decode(cleanBase64.trim()),
        width: 100,
        height: 100,
        fit: BoxFit.cover, // 👈 Perfect native cropping inside SQLite rendering pipeline
      );
    } catch (e) {
      return const Icon(Icons.person, size: 50, color: Colors.blueAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Edit Contact",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        textAlign: TextAlign.center,
      ),
      content: _isUpdating
          ? const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      )
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showImageSourcePicker, // 🔥 Bottom sheet callback activated
                child: Stack(
                  children: [
                    // 🔥 Fixed: ClipOval framework handles dynamic image sources with cover ratio
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
                      ),
                      child: ClipOval(
                        child: _buildAvatarWidget(),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 4,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.edit, size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 15),
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
            ],
          ),
        ),
      ),
      actions: _isUpdating
          ? null
          : [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _updateContact,
          child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
