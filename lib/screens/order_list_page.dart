import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<dynamic> pesananList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPesananUser();
  }

  Future<void> fetchPesananUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        debugPrint("Token tidak ditemukan, user belum login.");
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.2:8000/api/pesanan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          pesananList = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("Gagal memuat data pesanan");
      }
    } catch (e) {
      debugPrint("Error fetch pesanan: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Fungsi formatRupiah diperbaiki agar bisa handle string, double, dan null
  String formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    double? value = double.tryParse(number.toString()) ?? 0.0;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pesanan"),
        backgroundColor: const Color(0xFF1c92d2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pesananList.isEmpty
          ? const Center(child: Text("Belum ada pesanan."))
          : RefreshIndicator(
              onRefresh: fetchPesananUser,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pesananList.length,
                itemBuilder: (context, index) {
                  final p = pesananList[index];
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_laundry_service,
                                color: Color(0xFF1c92d2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Pesanan ID: ${p['id'] ?? '-'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildItem("Layanan", p['layanan'] ?? '-'),
                          _buildItem("Jumlah", "${p['jumlah'] ?? 0} kg"),
                          _buildItem(
                            "Total Harga",
                            formatRupiah(p['total_harga']),
                          ),
                          _buildItem(
                            "Tanggal",
                            (p['tanggal'] != null)
                                ? DateFormat(
                                    'dd-MM-yyyy',
                                  ).format(DateTime.parse(p['tanggal']))
                                : "-",
                          ),
                          _buildItem("Status", p['status'] ?? '-'),
                          const SizedBox(height: 10),
                          if (p['status_pembayaran'] == 'pending')
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentPage(pesananId: p['id']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: const Text("Bayar Sekarang"),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
