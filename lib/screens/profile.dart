import 'package:flutter/material.dart';
import 'package:laundry_mobile/screens/edit_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String address = "";
  File? profileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // ===== Ambil token login =====
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ===== API: Ambil profil user =====
  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      print("Token: $token"); // cek token dulu

      final response = await http.get(
        Uri.parse("http://192.168.1.2:8000/api/user/profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          username = data["username"] ?? "";
          email = data["email"] ?? "";
          address = data["address"] ?? "";
          isLoading = false; // 🟢 matikan loading setelah data dapat
        });
      } else {
        print("Error fetch profile: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception fetch profile: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF74ebd5), Color(0xFFACB6E5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Profil Saya",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34495e),
                          ),
                        ),
                        const SizedBox(height: 20),

                        infoItem("👤 Username", username),
                        infoItem("📧 Email", email),
                        infoItem("🏠 Alamat", address),

                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2980b9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 35,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 6,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                  profileData: {
                                    "username": username,
                                    "email": email,
                                    "address": address,
                                    "profileImage": profileImage,
                                  },
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                username = result['username'];
                                email = result['email'];
                                address = result['address'];
                                profileImage = result['profileImage'];
                              });
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            "Edit Profil",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2980b9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
