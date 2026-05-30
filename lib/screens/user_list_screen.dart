import 'package:cloud_contacts/database_helper/database_helper.dart';
import 'dart:convert';
import 'package:cloud_contacts/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:cloud_contacts/screens/add_user_screen.dart';
import 'package:cloud_contacts/screens/edit_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final fetchedUsers = await OfflineSyncManager.instance.getContacts();

    if (!mounted) return;
    setState(() {
      users = fetchedUsers;
      _filterUsers(_searchController.text);
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = users;
      } else {
        _filteredUsers = users.where((user) {
          final nameLower = user.name.toLowerCase();
          final emailLower = user.email.toLowerCase();
          final searchLower = query.toLowerCase();

          return nameLower.contains(searchLower) || emailLower.contains(searchLower);
        }).toList();
      }
    });
  }

  void deleteUser(User user) async {
    setState(() => _isLoading = true);

    await OfflineSyncManager.instance.deleteContact(user);

    loadUser();
  }

  ImageProvider _getContactAvatar(String avatarStr) {
    if (avatarStr.startsWith('http') || avatarStr.isEmpty) {
      return NetworkImage(
        avatarStr.isNotEmpty ? avatarStr : "https://w3schools.com",
      );
    }

    try {
      String cleanBase64 = avatarStr;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',')[1];
      }
      return MemoryImage(base64Decode(cleanBase64.trim()));
    } catch (e) {
      return const NetworkImage("https://w3schools.com");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: "Search contacts...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white60),
          ),
          onChanged: (value) => _filterUsers(value),
        )
            : const Text(
            "Cloud Contacts API",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filterUsers('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadUser,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddUserScreen(apiService: apiService),
            ),
          ).then((_) => loadUser());
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _filteredUsers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 70, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("No contacts found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const Text("Click + to add your first sync contact!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                backgroundImage: _getContactAvatar(user.avatar ?? ""),
              ),
              title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(user.email, style: const TextStyle(color: Colors.grey)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => EditUserScreen(user: user, apiService: apiService),
                      ).then((_) => loadUser());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => deleteUser(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
