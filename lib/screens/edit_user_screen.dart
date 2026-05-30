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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
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

  ImageProvider _getAvatarImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_currentAvatar.startsWith('http') || _currentAvatar.isEmpty) {
      return NetworkImage(
        _currentAvatar.isNotEmpty ? _currentAvatar : "https://w3schools.com",
      );
    }

    try {
      String cleanBase64 = _currentAvatar;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',')[1];
      }
      return MemoryImage(base64Decode(cleanBase64.trim()));
    } catch (e) {
      return const NetworkImage("https://w3schools.com");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Edit Contact",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        textAlign: TextAlign.center,),
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
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      backgroundImage: _getAvatarImage(),
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
