import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDashboard extends StatefulWidget {
  final String token;
  const UserDashboard({super.key, required this.token});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  Map<String, dynamic>? userData;
  bool loading = true;

  Future<void> getUserData() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.2168.1.6:8000/api/user"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body)["user"];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1c92d2), Color(0xFF0066cc)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _menuItem(Icons.person, "Profil", () {}),
                _menuItem(Icons.shopping_bag, "Buat Pesanan", () {}),
                _menuItem(Icons.list_alt, "Daftar Pesanan", () {}),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),

          // Konten utama
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/backgroundlaundry.jpeg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: loading
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Selamat Datang 👋",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1c92d2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userData != null
                                  ? "Hai ${userData!['username']}! Kamu berhasil login ke aplikasi. Silakan gunakan menu di sidebar untuk mengelola akun atau pesananmu."
                                  : "Data pengguna tidak ditemukan.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
