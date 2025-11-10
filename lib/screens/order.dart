import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreen extends StatefulWidget {
  final String username;
  const OrderScreen({super.key, required this.username});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  String? selectedLayanan;
  Map<String, dynamic>? pesananData;
  bool isConfirming = false;
  bool loading = false;

  Future<void> pilihTanggal(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> buatPesanan() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tanggal terlebih dahulu")),
      );
      return;
    }

    setState(() => loading = true);

    final tanggalFormatted =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan. Silakan login ulang."),
          ),
        );
        setState(() => loading = false);
        return;
      }

      // Ambil data user login (supaya dapat alamat dan user_id)
      final userResponse = await http.get(
        Uri.parse("http://192.168.1.2:8000/api/user/profile"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('User profile status: ${userResponse.statusCode}');
      debugPrint('User profile body: ${userResponse.body}');

      if (userResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil profil: ${userResponse.statusCode}"),
          ),
        );
        setState(() => loading = false);
        return;
      }

      final userData = json.decode(userResponse.body);
      final int userId = userData['id'];
      final String namaPelanggan = userData['username'] ?? widget.username;
      final String? alamat = (userData['address'] as String?)?.trim();

      // Backend butuh 'alamat' -> kalau belum ada, minta user isi dulu
      if (alamat == null || alamat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Alamat belum diisi di profil. Silakan isi alamat sebelum membuat pesanan.",
            ),
          ),
        );
        setState(() => loading = false);
        return;
      }

      const String baseUrl = "http://192.168.1.2:8000/api/pesanan";

      // Backend validasi 'jumlah' required|integer -> kirim placeholder 0 (admin nanti update)
      final body = {
        'user_id': userId.toString(),
        'nama_pelanggan': namaPelanggan,
        'layanan': selectedLayanan!,
        'jumlah': '0', // placeholder agar validasi backend terpenuhi
        'tanggal': tanggalFormatted,
        'status': 'pending',
        'alamat': alamat, // kirim sebagai 'alamat' (sesuai validasi backend)
      };

      debugPrint('POST $baseUrl body: $body');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
          // jika backend butuh form urlencoded, header content-type tidak perlu di-set (http package meng-encode Map jadi form by default)
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('Pesanan POST status: ${response.statusCode}');
      debugPrint('Pesanan POST body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          pesananData = data;
          isConfirming = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil dikirim!")),
        );
      } else {
        // tampilkan pesan error yang dikembalikan backend (jika ada)
        final msg = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Status ${response.statusCode}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal kirim pesanan: $msg")));
      }
    } catch (e) {
      debugPrint('Exception buatPesanan: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buat Pesanan (${widget.username})')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedLayanan,
                hint: const Text('Pilih Layanan'),
                onChanged: (value) {
                  setState(() => selectedLayanan = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Cuci Kering',
                    child: Text('Cuci Kering'),
                  ),
                  DropdownMenuItem(
                    value: 'Cuci Setrika',
                    child: Text('Cuci Setrika'),
                  ),
                  DropdownMenuItem(value: 'Setrika', child: Text('Setrika')),
                ],
                validator: (value) =>
                    value == null ? 'Layanan harus dipilih' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'Belum pilih tanggal'
                          : 'Tanggal: ${selectedDate!.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => pilihTanggal(context),
                    child: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: loading ? null : buatPesanan,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Buat Pesanan'),
                ),
              ),
              const SizedBox(height: 20),
              if (isConfirming && pesananData != null)
                Card(
                  child: ListTile(
                    title: Text(
                      "Pesanan: ${pesananData!['layanan'] ?? selectedLayanan}",
                    ),
                    subtitle: Text(
                      "Status: ${pesananData!['status'] ?? 'pending'}\nTanggal: ${pesananData!['tanggal'] ?? selectedDate}",
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
