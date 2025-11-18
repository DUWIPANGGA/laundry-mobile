import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreen extends StatefulWidget {
  final String username;
  const OrderScreen({super.key, required this.username});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedLayanan;
  Map<String, dynamic>? _pesananData;
  bool _isConfirming = false;
  bool _loading = false;
  bool _loadingHarga = false;
  List<dynamic> _hargaList = [];
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHarga();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getStoredUser();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      // ApiService._debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadHarga() async {
    setState(() => _loadingHarga = true);
    try {
      final response = await ApiService.getHarga();
      if (response['success'] == true) {
        setState(() {
          _hargaList = response['data'];
        });
      }
    } catch (e) {
      // ApiService._debugPrint('Error loading harga: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data layanan: $e')),
      );
    } finally {
      setState(() => _loadingHarga = false);
    }
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3498db),
              onPrimary: Colors.white,
              onSurface: Color(0xFF3498db),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3498db),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _buatPesanan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih tanggal terlebih dahulu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLayanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih layanan terlebih dahulu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Cek apakah user sudah login
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Silakan login terlebih dahulu"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // Ambil data user terbaru
      final userResponse = await ApiService.getProfile();
      if (userResponse['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengambil data profil"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      final userData = userResponse['data'];
      final String alamat = userData['address'] ?? '';

      // Validasi alamat
      if (alamat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Alamat belum diisi. Silakan lengkapi profil Anda terlebih dahulu.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // Format tanggal
      final tanggalFormatted =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      // Data pesanan
      final pesananData = {
        'layanan': _selectedLayanan!,
        'tanggal': tanggalFormatted,
        'metode_pengambilan': 'ambil', // Default, bisa diubah nanti
        'alamat_pengambilan': alamat,
      };

      // Buat pesanan menggunakan ApiService
      final response = await ApiService.createPesanan(pesananData);

      if (response['success'] == true) {
        setState(() {
          _pesananData = response['data'];
          _isConfirming = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pesanan berhasil dibuat!"),
            backgroundColor: Colors.green,
          ),
        );

        // Delay sebentar sebelum navigasi (opsional)
        await Future.delayed(const Duration(seconds: 1));
        
        // Navigate to confirmation page or order list
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => OrderListPage(), // Ganti dengan halaman yang sesuai
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat pesanan: ${response['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getHargaText(String layanan) {
    try {
      final hargaItem = _hargaList.firstWhere(
        (item) => item['layanan'] == layanan,
        orElse: () => null,
      );
      return hargaItem != null ? 'Rp ${hargaItem['hargaPerKg']}/kg' : 'Rp 0/kg';
    } catch (e) {
      return 'Rp 0/kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF3498db);
    const backgroundColor = Color(0xFFF2F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Buat Pesanan Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(size, primaryColor),
            const SizedBox(height: 24),

            // Form Pesanan
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pilih Layanan
                      _buildLayananDropdown(primaryColor),
                      const SizedBox(height: 20),

                      // Pilih Tanggal
                      _buildTanggalPicker(primaryColor),
                      const SizedBox(height: 30),

                      // Tombol Buat Pesanan
                      _buildBuatPesananButton(primaryColor),
                    ],
                  ),
                ),
              ),
            ),

            // Konfirmasi Pesanan
            if (_isConfirming && _pesananData != null)
              _buildConfirmationCard(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Size size, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Buat Pesanan Laundry",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Hai ${widget.username}!",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_userData?['address'] != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _userData!['address'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLayananDropdown(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Layanan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _loadingHarga
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498db)),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedLayanan,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  hint: const Text('Pilih Jenis Layanan'),
                  onChanged: (value) {
                    setState(() => _selectedLayanan = value);
                  },
                  items: _hargaList.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item['layanan'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['layanan']),
                          Text(
                            _getHargaText(item['layanan']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null ? 'Layanan harus dipilih' : null,
                ),
        ),
      ],
    );
  }

  Widget _buildTanggalPicker(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Tanggal',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _selectedDate == null
                        ? 'Pilih tanggal pengambilan'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.calendar_today, color: primaryColor),
                  onPressed: () => _pilihTanggal(context),
                ),
              ),
            ],
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Pesanan akan diproses pada tanggal yang dipilih',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBuatPesananButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _buatPesanan,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_shopping_cart, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Buat Pesanan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildConfirmationCard(Color primaryColor) {
    return FadeIn(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pesanan Berhasil Dibuat!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Layanan', _pesananData!['layanan'] ?? '-'),
              _buildDetailRow('Tanggal', _pesananData!['tanggal'] ?? '-'),
              _buildDetailRow('Status', _pesananData!['status'] ?? 'pending'),
              _buildDetailRow('ID Pesanan', _pesananData!['id']?.toString() ?? '-'),
              const SizedBox(height: 16),
              Text(
                'Admin akan segera menghubungi Anda untuk konfirmasi jumlah dan total harga.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
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
            width: 100,
            child: Text(
              '$label:',
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
              value,
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
}

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