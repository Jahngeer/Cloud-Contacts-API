import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {

  // 🌐 MockAPI URL
  final String apiUrl =
      "https://6a127f7978d0434e0d5d4027.mockapi.io/api/v1/contacts";

  // ==============================
  // 🟢 CREATE USER (POST)
  // ==============================
  Future<bool> createUser(User user) async {
    try {

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {

        print("✅ User Created Successfully!");
        print(response.body);

        return true;

      } else {

        print("❌ Failed To Create User");
        print("Status Code: ${response.statusCode}");

        return false;
      }

    } catch (e) {

      print("🔥 CREATE ERROR: $e");

      return false;
    }
  }

  // ==============================
  // 🔵 READ USERS (GET)
  // ==============================
  Future<List<User>> getUsers() async {

    try {

      final response = await http.get(
        Uri.parse(apiUrl),
      );

      if (response.statusCode == 200) {

        List data = jsonDecode(response.body);

        print("✅ Users Fetched: ${data.length}");

        return data
            .map((json) => User.fromJson(json))
            .toList();

      } else {

        print("❌ Failed To Fetch Users");
        print("Status Code: ${response.statusCode}");

        return [];
      }

    } catch (e) {

      print("🔥 FETCH ERROR: $e");

      return [];
    }
  }

  // ==============================
  // 🟡 UPDATE USER (PUT)
  // ==============================
  Future<bool> updateUser(User user) async {

    try {

      final response = await http.put(

        Uri.parse("$apiUrl/${user.id}"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {

        print("✅ User Updated Successfully!");
        print(response.body);

        return true;

      } else {

        print("❌ Failed To Update User");
        print("Status Code: ${response.statusCode}");

        return false;
      }

    } catch (e) {

      print("🔥 UPDATE ERROR: $e");

      return false;
    }
  }

  // ==============================
  // 🔴 DELETE USER (DELETE)
  // ==============================
  Future<bool> deleteUser(String id) async {

    try {

      final response = await http.delete(
        Uri.parse("$apiUrl/$id"),
      );

      if (response.statusCode == 200) {

        print("✅ User Deleted Successfully!");

        return true;

      } else {

        print("❌ Failed To Delete User");
        print("Status Code: ${response.statusCode}");

        return false;
      }

    } catch (e) {

      print("🔥 DELETE ERROR: $e");

      return false;
    }
  }
}