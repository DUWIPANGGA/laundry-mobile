import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  File? _imageFile;
  bool _loading = false;
  bool _loadingProfile = true;
  String? _message;
  Map<String, dynamic>? _userData;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    ApiService.debugPrint('🎯 USER SCREEN INIT');
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    ApiService.debugPrint('🔄 INITIALIZING PROFILE...');
    
    // Cek apakah user sudah login
    final isLoggedIn = await ApiService.isLoggedIn();
    if (!isLoggedIn) {
      ApiService.debugPrint('❌ USER NOT LOGGED IN');
      setState(() {
        _loadingProfile = false;
        _hasError = true;
        _message = 'Silakan login terlebih dahulu';
      });
      return;
    }

    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    ApiService.debugPrint('📥 LOADING USER PROFILE...');
    
    try {
      setState(() {
        _loadingProfile = true;
        _hasError = false;
        _message = null;
      });

      // Coba ambil dari API terlebih dahulu
      final response = await ApiService.getProfile();
      ApiService.debugPrint('📊 PROFILE RESPONSE: ${response['success']}');
      
      if (response['success'] == true) {
        ApiService.debugPrint('✅ PROFILE LOADED FROM API');
        setState(() {
          _userData = response['data'];
          _updateControllers();
          _hasError = false;
        });
      } else {
        // Fallback ke data yang tersimpan di SharedPreferences
        ApiService.debugPrint('🔄 FALLBACK TO STORED DATA');
        final storedUser = await ApiService.getStoredUser();
        if (storedUser != null) {
          ApiService.debugPrint('✅ USING STORED USER DATA');
          setState(() {
            _userData = storedUser;
            _updateControllers();
            _hasError = false;
          });
        } else {
          ApiService.debugPrint('❌ NO STORED USER DATA');
          setState(() {
            _hasError = true;
            _message = response['message'] ?? 'Gagal memuat profil';
          });
        }
      }
    } catch (e) {
      ApiService.debugPrint('💥 ERROR IN _loadUserProfile: $e');
      setState(() {
        _hasError = true;
        _message = 'Terjadi kesalahan: $e';
      });
    } finally {
      ApiService.debugPrint('🏁 LOADING COMPLETE');
      setState(() => _loadingProfile = false);
    }
  }

  void _updateControllers() {
    if (_userData != null) {
      _emailController.text = _userData!['email'] ?? '';
      _addressController.text = _userData!['address'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final profileData = {
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
      };

      // Jika password diisi, tambahkan ke data
      if (_passwordController.text.isNotEmpty) {
        profileData['password'] = _passwordController.text;
        profileData['password_confirmation'] = _confirmPasswordController.text;
      }

      ApiService.debugPrint('📤 UPDATING PROFILE: $profileData');
      final response = await ApiService.updateProfile(profileData);

      if (response['success'] == true) {
        ApiService.debugPrint('✅ PROFILE UPDATED SUCCESSFULLY');
        setState(() {
          _message = "✅ Profil berhasil diperbarui!";
          _userData = response['data'];
        });
        
        // Clear password fields
        _passwordController.clear();
        _confirmPasswordController.clear();
        
        // Tutup modal jika terbuka
        Navigator.pop(context);
        
        // Refresh data
        _loadUserProfile();
      } else {
        ApiService.debugPrint('❌ PROFILE UPDATE FAILED: ${response['message']}');
        setState(() {
          _message = "❌ Gagal: ${response['message'] ?? 'Terjadi kesalahan'}";
        });
      }
    } catch (e) {
      ApiService.debugPrint('💥 UPDATE PROFILE ERROR: $e');
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditProfileModal(),
    );
  }

  Widget _buildEditProfileModal() {
    const primaryColor = Color(0xFF3498db);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form Edit Profil
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
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

                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Alamat",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password Baru (opsional)",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Konfirmasi Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty && 
                          value != _passwordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Message
                  if (_message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _message!.startsWith('✅') 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _message!.startsWith('✅') 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.startsWith('✅') 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final username = _userData?['username'] ?? 'User';
    final email = _userData?['email'] ?? '-';
    final address = _userData?['address'] ?? '-';
    final role = _userData?['role'] ?? 'user';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () {
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur upload foto akan segera tersedia'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: _userData != null 
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Color(0xFF3498db),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Info
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (address.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3498db).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3498db)),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gagal Memuat Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _message ?? 'Terjadi kesalahan saat memuat data',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498db),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ApiService.debugPrint('🏗️ BUILDING USER SCREEN - Loading: $_loadingProfile, Error: $_hasError');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      appBar: AppBar(
        title: const Text(
          "Profil Saya",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3498db),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _userData != null ? _showEditProfileModal : null,
            tooltip: 'Edit Profil',
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498db)),
                  ),
                  SizedBox(height: 16),
                  Text('Memuat profil...'),
                ],
              ),
            )
          : _hasError
              ? _buildErrorState()
              : _userData == null
                  ? _buildErrorState()
                  : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // User Information Cards
          _buildInfoCard(
            'Username',
            _userData!['username'] ?? '-',
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Email',
            _userData!['email'] ?? '-',
            Icons.email,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Alamat',
            _userData!['address'] ?? 'Belum diisi',
            Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Role',
            (_userData!['role'] ?? 'user').toUpperCase(),
            Icons.verified_user,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Terdaftar Sejak',
            _userData!['created_at'] != null 
                ? _formatDate(_userData!['created_at'])
                : '-',
            Icons.calendar_today,
          ),

          const SizedBox(height: 32),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditProfileModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498db),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: const Text(
                'Edit Profil',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ApiService.clearAuthData();
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}