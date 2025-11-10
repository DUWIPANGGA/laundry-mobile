// 📁 lib/screens/user.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _otpController = TextEditingController();
  final _resetPassController = TextEditingController();
  final _resetConfirmController = TextEditingController();

  File? _imageFile;
  bool _loading = false;
  String? _message;
  Map<String, dynamic>? userData;

  final String apiBase =
      "http://192.168.1.2168.1.5:8000/api"; // Ganti dengan IP backend kamu

  // 🔹 Ambil profil user
  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBase/profile"),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data;
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      } else {
        setState(
          () => _message = "Gagal memuat profil (${response.statusCode})",
        );
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    }
  }

  // 🔹 Update profil
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final request =
        http.MultipartRequest('POST', Uri.parse("$apiBase/update-profile"))
          ..headers['Authorization'] = 'Bearer YOUR_TOKEN'
          ..fields['email'] = _emailController.text
          ..fields['address'] = _addressController.text;

    if (_passwordController.text.isNotEmpty) {
      request.fields['password'] = _passwordController.text;
      request.fields['password_confirmation'] = _confirmPasswordController.text;
    }

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', _imageFile!.path),
      );
    }

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);
      if (response.statusCode == 200) {
        setState(() => _message = "✅ Profil berhasil diperbarui!");
        _fetchProfile();
      } else {
        setState(
          () => _message = "❌ Gagal: ${data['message'] ?? 'Terjadi kesalahan'}",
        );
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 Kirim kode OTP ke email
  Future<void> _sendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse("$apiBase/forget/send"),
        body: {'email': email},
      );
      if (res.statusCode == 200) {
        setState(() => _message = "Kode OTP telah dikirim ke email kamu!");
      } else {
        setState(() => _message = "Email tidak ditemukan.");
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    }
  }

  // 🔹 Verifikasi OTP
  Future<void> _verifyOtp() async {
    try {
      final res = await http.post(
        Uri.parse("$apiBase/forget/verify"),
        body: {'kode': _otpController.text},
      );
      if (res.statusCode == 200) {
        setState(() => _message = "OTP benar! Silakan reset password.");
      } else {
        setState(() => _message = "Kode OTP salah.");
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    }
  }

  // 🔹 Reset Password
  Future<void> _resetPassword() async {
    try {
      final res = await http.post(
        Uri.parse("$apiBase/forget/reset"),
        body: {
          'password': _resetPassController.text,
          'password_confirmation': _resetConfirmController.text,
        },
      );
      if (res.statusCode == 200) {
        setState(() => _message = "✅ Password berhasil diubah!");
      } else {
        setState(() => _message = "❌ Gagal ubah password.");
      }
    } catch (e) {
      setState(() => _message = "Error: $e");
    }
  }

  // 🔹 Pilih gambar
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        userData ??
        {
          'username': 'Pajli Ler',
          'email': 'admin@example.com',
          'address': 'Indramayu',
          'profile_picture': '',
        };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Reset Password"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_message != null)
                    Text(
                      _message!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  const SizedBox(height: 20),

                  // FOTO PROFIL
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user['profile_picture']!.isNotEmpty
                                    ? NetworkImage(user['profile_picture']!)
                                    : null)
                                as ImageProvider?,
                      child:
                          _imageFile == null &&
                              (user['profile_picture'] == null ||
                                  user['profile_picture']!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 25),
                  Text(
                    user['username'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user['email'],
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Edit Profil",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Email wajib diisi" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: "Alamat",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password Baru (opsional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Konfirmasi Password",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Simpan Perubahan"),
                          onPressed: _updateProfile,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 40),
                  const Text(
                    "Lupa Password / Reset OTP",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _sendOtp(_emailController.text),
                    child: const Text("Kirim Kode OTP"),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: "Masukkan Kode",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text("Verifikasi OTP"),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _resetPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password Baru",
                    ),
                  ),
                  TextField(
                    controller: _resetConfirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Konfirmasi Password",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Ubah Password"),
                  ),
                ],
              ),
            ),
    );
  }
}
