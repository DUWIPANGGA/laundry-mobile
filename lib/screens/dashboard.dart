import 'package:flutter/material.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile.dart';
import 'order.dart';
import 'order_list_page.dart';
import 'confirmorder.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Menggunakan ApiService untuk mendapatkan data user
      final userData = await ApiService.getStoredUser();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Tampilkan dialog konfirmasi
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await ApiService.clearAuthData(); // Clear data auth
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayUsername = _userData?['username'] ?? widget.username;
    final userEmail = _userData?['email'] ?? '';
    final userAddress = _userData?['address'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: _buildCustomDrawer(context, displayUsername, userEmail, userAddress),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeIn(
                delay: 200,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Text(
                              displayUsername.isNotEmpty 
                                  ? displayUsername[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Selamat Datang 👋",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "Hai $displayUsername!",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (userEmail.isNotEmpty)
                        _buildInfoRow(Icons.email, userEmail),
                      if (userAddress.isNotEmpty)
                        _buildInfoRow(Icons.location_on, userAddress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // User Info Card
              if (_userData != null)
                FadeIn(
                  delay: 300,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Informasi Akun",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow("Username", displayUsername),
                        if (userEmail.isNotEmpty)
                          _buildDetailRow("Email", userEmail),
                        if (userAddress.isNotEmpty)
                          _buildDetailRow("Alamat", userAddress),
                        _buildDetailRow("Role", _userData?['role'] ?? 'User'),
                        _buildDetailRow(
                          "Terdaftar Sejak", 
                          _formatDate(_userData?['created_at'])
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 30),
              FadeIn(
                delay: 400,
                child: _menuCard(
                  icon: Icons.local_laundry_service,
                  label: "Buat Pesanan Baru",
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderScreen(username: displayUsername),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              FadeIn(
                delay: 500,
                child: _menuCard(
                  icon: Icons.list_alt,
                  label: "Lihat Daftar Pesanan",
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderListPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              FadeIn(
                delay: 600,
                child: _menuCard(
                  icon: Icons.person,
                  label: "Kelola Profil",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '-';
    }
  }

  // --- Drawer Sidebar Custom ---
  Drawer _buildCustomDrawer(BuildContext context, String username, String email, String address) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70, 
                        fontSize: 14
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: const TextStyle(
                        color: Colors.white70, 
                        fontSize: 12
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  DrawerItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  DrawerItem(
                    icon: Icons.person,
                    label: 'Profil Saya',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.local_laundry_service,
                    label: 'Buat Pesanan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderScreen(username: username),
                        ),
                      );
                    },
                  ),
                  DrawerItem(
                    icon: Icons.list_alt,
                    label: 'Daftar Pesanan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderListPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card Menu ---
  Widget _menuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.2),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, 
                color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}

// --- Animasi Fade ---
class FadeIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const FadeIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, opacity, _) => Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, (1 - opacity) * 20),
          child: child,
        ),
      ),
    );
  }
}