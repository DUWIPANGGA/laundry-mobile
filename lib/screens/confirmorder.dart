// lib/screens/confirmorder.dart
import 'package:flutter/material.dart';

class ConfirmOrderScreen extends StatelessWidget {
  const ConfirmOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan"),
        backgroundColor: const Color(0xFF1c92d2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/backgroudlandry.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: args != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Konfirmasi Pesanan",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Pesanan Anda berhasil dibuat! Berikut rincian pesanan:",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text("Nama Pelanggan: ${args['nama']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_laundry_service),
                        title: Text("Layanan: ${args['layanan']}"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text("Tanggal: ${args['tanggal']}"),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Status: Pending Pembayaran",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/orders'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF28a745),
                        ),
                        child: const Text("Daftar Pesanan Kamu"),
                      ),
                    ],
                  )
                : const Text("Pesanan tidak ditemukan!"),
          ),
        ),
      ),
    );
  }
}
