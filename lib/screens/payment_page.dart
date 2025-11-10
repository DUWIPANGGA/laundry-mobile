import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:midtrans_sdk/midtrans_sdk.dart';

class PaymentPage extends StatefulWidget {
  final int pesananId;
  const PaymentPage({super.key, required this.pesananId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late MidtransSDK _midtrans;
  bool _isLoading = true;
  String? _snapToken;
  String _status = "Menyiapkan transaksi...";

  @override
  void initState() {
    super.initState();
    _initMidtrans();
  }

  Future<void> _initMidtrans() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey:
            "SB-Mid-client-xxxxx", // Ganti dengan client key sandbox kamu
        merchantBaseUrl: "http://192.168.1.2:8000/api/",
      ),
    );

    _midtrans.setTransactionFinishedCallback((result) {
      final status = result.status?.toLowerCase() ?? '';

      print('DEBUG: Hasil transaksi -> $status'); // buat debugging di console

      if (status == 'settlement' || status == 'capture') {
        setState(() => _status = "Pembayaran berhasil ✅");
      } else if (status == 'pending') {
        setState(() => _status = "Menunggu pembayaran ⏳");
      } else if (status == 'cancel') {
        setState(() => _status = "Dibatalkan pengguna 🚫");
      } else if (status == 'failure') {
        setState(() => _status = "Pembayaran gagal ❌");
      } else {
        setState(() => _status = "Status tidak diketahui ⚠️ ($status)");
      }
    });

    await _createTransaction();
  }

  Future<void> _createTransaction() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:8000/api/create-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pesanan_id': widget.pesananId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['snap_token'];

        setState(() {
          _snapToken = token;
          _isLoading = false;
        });

        _startPayment(token);
      } else {
        setState(() => _status = 'Gagal membuat transaksi');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _startPayment(String token) async {
    await _midtrans.startPaymentUiFlow(token: token);
  }

  @override
  void dispose() {
    _midtrans.removeTransactionFinishedCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran Midtrans")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_status, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _snapToken == null
                        ? null
                        : () => _startPayment(_snapToken!),
                    child: const Text("Bayar Sekarang"),
                  ),
                ],
              ),
      ),
    );
  }
}
