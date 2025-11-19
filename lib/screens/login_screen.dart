import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:laundry_mobile/screens/email_verification.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:laundry_mobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'register.dart';

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
  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    setState(() {
      _errorMessage = "Username dan password harus diisi";
    });
    return;
  }

  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  try {
    // GUNAKAN AuthService untuk login
    final response = await AuthService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (response['success'] == true) {
      // Navigate ke dashboard
      final userData = response['data']['user'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            username: userData['username'] ?? "User",
          ),
        ),
      );
    } else if (response['needs_verification'] == true) {
      // Redirect ke screen verifikasi email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: response['email'],
            fromRegistration: false,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = response['message'] ?? "Login gagal. Periksa username dan password.";
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Login gagal: $e";
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
                  
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_laundry_service,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Laundry Express',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  const Text(
                    'Login ke Akun Anda',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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
                        
                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginApi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Register Link
                        Center(
                          child: GestureDetector(
                            onTap: _loading
                                ? null
                                : () {
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

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