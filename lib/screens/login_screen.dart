import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'register.dart'; // 🟢 Tambah ini

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _loginApi() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.2:8000/api/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(username: data["user"]["username"] ?? "User"),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Login gagal.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal terhubung ke server: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF3498db);
    const waveColor = Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Waves
            Positioned(
              top: -100,
              child: CustomPaint(
                size: Size(size.width * 1.5, 200),
                painter: WavePainter(waveColor: waveColor, isTop: true),
              ),
            ),
            Positioned(
              bottom: -100,
              child: CustomPaint(
                size: Size(size.width * 1.5, 200),
                painter: WavePainter(waveColor: waveColor, isTop: false),
              ),
            ),

            // Content
            Container(
              constraints: BoxConstraints(minHeight: size.height),
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _usernameController,
                          hint: "Masukkan username",
                          icon: Icons.person_outline,
                        ),
                        _buildInputField(
                          controller: _passwordController,
                          hint: "Masukkan password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginApi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Belum punya akun? Daftar di sini",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    const primaryColor = Color(0xFF3498db);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}

// 🟢 WavePainter dipakai bersama Register
class WavePainter extends CustomPainter {
  final Color waveColor;
  final bool isTop;

  WavePainter({required this.waveColor, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor;
    final path = Path();

    path.moveTo(0, isTop ? size.height : 0);
    double midX = size.width / 2;
    double endX = size.width;

    if (isTop) {
      path.quadraticBezierTo(midX, 0, endX, size.height);
      path.lineTo(endX, 0);
      path.lineTo(0, 0);
    } else {
      path.quadraticBezierTo(midX, size.height, endX, 0);
      path.lineTo(endX, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
