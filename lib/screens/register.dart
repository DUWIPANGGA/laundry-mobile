import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _verifikasiKode = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final Color primaryColor = const Color(0xFF3498db);
  final Color waveColor = Colors.white;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:8000/api/register'),
        headers: {'Accept': 'application/json'},
        body: {
          'username': _username.text,
          'email': _email.text,
          'password': _password.text,
          'confirm_password': _confirmPassword.text,
          'address': _address.text,
          'verifikasi_kode': _verifikasiKode.text,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registrasi berhasil!')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage =
              data['message'] ?? 'Registrasi gagal, periksa kembali data kamu.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _address.dispose();
    _verifikasiKode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            Container(
              constraints: BoxConstraints(minHeight: size.height),
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      'assets/washing_machine.png',
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.local_laundry_service,
                        size: 80,
                        color: waveColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: waveColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _username,
                            label: "Username",
                            icon: Icons.person_outline,
                          ),
                          _buildTextField(
                            controller: _email,
                            label: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildTextField(
                            controller: _password,
                            label: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          _buildTextField(
                            controller: _confirmPassword,
                            label: "Konfirmasi Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          _buildTextField(
                            controller: _address,
                            label: "Alamat",
                            icon: Icons.home_outlined,
                          ),
                          _buildTextField(
                            controller: _verifikasiKode,
                            label: "Kode Verifikasi",
                            icon: Icons.verified_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? CircularProgressIndicator(color: primaryColor)
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 80,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? '$label wajib diisi' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 2),
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
    } else {
      path.quadraticBezierTo(midX, size.height, endX, 0);
    }

    if (isTop) {
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
