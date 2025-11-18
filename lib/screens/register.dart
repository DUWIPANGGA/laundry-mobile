import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryColor = const Color(0xFF3498db);
  final Color backgroundColor = const Color(0xFFF2F7FA);
  final Color waveColor = const Color(0xFFE3F2FD);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tambahan
    if (_password.text != _confirmPassword.text) {
      setState(() {
        _errorMessage = 'Password dan konfirmasi password tidak cocok';
      });
      return;
    }

    if (_verifikasiKode.text != '12345') {
      setState(() {
        _errorMessage = 'Kode verifikasi salah. Silakan masukkan 12345';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    ApiService.debugPrint('📤 REGISTER REQUEST:');
    ApiService.debugPrint('   Username: ${_username.text}');
    ApiService.debugPrint('   Email: ${_email.text}');
    ApiService.debugPrint('   Address: ${_address.text}');

    try {
      final response = await ApiService.register(
        _username.text.trim(),
        _email.text.trim(),
        _password.text.trim(),
        _address.text.trim(),
      );

      ApiService.debugPrint('📥 REGISTER RESPONSE: ${response['success']}');

      if (response['success'] == true) {
        // Auto login setelah registrasi berhasil
        final loginResponse = await ApiService.login(
          _username.text.trim(),
          _password.text.trim(),
        );

        if (loginResponse['success'] == true) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/dashboard', 
            (route) => false
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Registrasi gagal. Silakan coba lagi.';
        });
      }
    } catch (e) {
      ApiService.debugPrint('💥 REGISTER ERROR: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
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
            // Background Waves
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

            // Main Content
            Container(
              constraints: BoxConstraints(minHeight: size.height),
              width: size.width,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Logo/Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_laundry_service,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'Laundry Express',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  const Text(
                    'Buat Akun Baru',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _username,
                            label: "Username",
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username wajib diisi';
                              }
                              if (value.length < 3) {
                                return 'Username minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _email,
                            label: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPasswordField(
                            controller: _password,
                            label: "Password",
                            obscureText: _obscurePassword,
                            onToggle: _togglePasswordVisibility,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 5) {
                                return 'Password minimal 5 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPasswordField(
                            controller: _confirmPassword,
                            label: "Konfirmasi Password",
                            obscureText: _obscureConfirmPassword,
                            onToggle: _toggleConfirmPasswordVisibility,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _address,
                            label: "Alamat",
                            icon: Icons.home_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Alamat wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _verifikasiKode,
                            label: "Kode Verifikasi",
                            icon: Icons.verified_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kode verifikasi wajib diisi';
                              }
                              return null;
                            },
                          ),
                          
                          // Verification Code Hint
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8, bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Gunakan kode verifikasi: 12345',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error Message
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
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
                            const SizedBox(height: 16),
                          ],

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Daftar Sekarang',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun?',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _isLoading ? null : () => Navigator.pop(context),
                                child: Text(
                                  'Login di sini',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
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