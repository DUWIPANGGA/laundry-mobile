import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String step = 'email'; // email -> otp -> reset
  String? errorMessage;
  String? successMessage;
  bool _isLoading = false;

  // URL API Laravel
  final String baseUrl =
      'http://192.168.1.2:8000/api'; // ganti sesuai IP/URL Laravel

  // --- Step 1: Kirim kode OTP ---
  Future<void> kirimKode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => errorMessage = 'Email wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forget/send-otp'),
        body: {'email': email},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          step = 'otp';
          successMessage = data['message'] ?? 'Kode OTP dikirim ke email';
        });
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Terjadi kesalahan';
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Step 2: Verifikasi OTP ---
  Future<void> verifikasiKode() async {
    final kode = _otpController.text.trim();
    if (kode.isEmpty) {
      setState(() => errorMessage = 'Kode OTP wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forget/verify-otp'),
        body: {'kode': kode},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          step = 'reset';
          successMessage = 'OTP terverifikasi, silakan ganti password';
        });
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Kode salah, coba lagi';
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Step 3: Reset Password ---
  Future<void> resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = 'Password dan konfirmasi wajib diisi');
      return;
    }

    if (password != confirm) {
      setState(() => errorMessage = 'Password dan konfirmasi tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forget/reset-password'),
        body: {'password': password, 'password_confirmation': confirm},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          successMessage = data['message'] ?? 'Password berhasil diubah';
          step = 'email';
          _emailController.clear();
          _otpController.clear();
          _passwordController.clear();
          _confirmController.clear();
        });
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Gagal reset password';
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Build step form ---
  Widget _buildStepForm() {
    switch (step) {
      case 'email':
        return Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : kirimKode,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim OTP'),
            ),
          ],
        );
      case 'otp':
        return Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : verifikasiKode,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verifikasi OTP'),
            ),
          ],
        );
      case 'reset':
        return Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : resetPassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan Password'),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.red[300],
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            if (successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.green[300],
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        successMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            _buildStepForm(),
          ],
        ),
      ),
    );
  }
}
