import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan ini
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<dynamic> _pesananList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDateFormatInitialized = false; // Tambahkan flag ini

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting().then((_) {
      _fetchPesananUser();
    });
  }

  // Tambahkan method untuk inisialisasi date formatting
  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _isDateFormatInitialized = true;
      });
    } catch (e) {
      // ApiService._debugPrint('Error initializing date formatting: $e');
      // Tetap lanjutkan meskipun ada error
      setState(() {
        _isDateFormatInitialized = true;
      });
    }
  }

  Future<void> _fetchPesananUser() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.getPesananUser();
      
      if (response['success'] == true) {
        setState(() {
          _pesananList = response['data'] ?? [];
          _isLoading = false;
        });
        // ApiService._debugPrint('✅ Loaded ${_pesananList.length} orders');
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response['message'] ?? 'Gagal memuat data pesanan';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      // ApiService._debugPrint('💥 Error fetching orders: $e');
    }
  }

  String _formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    double? value = double.tryParse(number.toString()) ?? 0.0;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(value);
  }

  // Method untuk format tanggal yang aman
  String _formatTanggal(String? dateString) {
    if (dateString == null) return '-';
    
    try {
      final date = DateTime.parse(dateString);
      
      // Gunakan format yang lebih sederhana jika locale belum siap
      if (!_isDateFormatInitialized) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
      
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // ApiService._debugPrint('Error formatting date: $e');
      return dateString; // Kembalikan string asli jika error
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'proses':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'gagal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Icons.check_circle;
      case 'proses':
        return Icons.autorenew;
      case 'pending':
        return Icons.pending;
      case 'batal':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF3498db).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_laundry_service,
              size: 60,
              color: Color(0xFF3498db),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yuk buat pesanan laundry pertama Anda!',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498db),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Buat Pesanan Baru'),
          ),
        ],
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
          Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchPesananUser,
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final primaryColor = const Color(0xFF3498db);
    final statusColor = _getStatusColor(order['status'] ?? 'pending');
    final paymentStatusColor = _getPaymentStatusColor(order['status_pembayaran'] ?? 'pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan ID dan Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_laundry_service,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ORDER #${order['id'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order['status'] ?? 'pending'),
                                color: statusColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (order['status'] ?? 'pending').toString().toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Informasi Pesanan
                    _buildOrderDetailRow('Layanan', order['layanan'] ?? '-'),
                    _buildOrderDetailRow('Berat', '${order['jumlah'] ?? 0} kg'),
                    _buildOrderDetailRow('Total', _formatRupiah(order['total_harga'])),
                    
                    // Tanggal - menggunakan method _formatTanggal yang aman
                    if (order['tanggal'] != null)
                      _buildOrderDetailRow(
                        'Tanggal',
                        _formatTanggal(order['tanggal']),
                      ),

                    // Status Pembayaran
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: paymentStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            order['status_pembayaran'] == 'selesai' 
                                ? Icons.payment 
                                : Icons.pending_actions,
                            color: paymentStatusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pembayaran: ${(order['status_pembayaran'] ?? 'pending').toString().toUpperCase()}',
                            style: TextStyle(
                              color: paymentStatusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Aksi
                    if (order['status_pembayaran'] == 'pending' && order['status'] != 'batal')
                      const SizedBox(height: 16),
                    if (order['status_pembayaran'] == 'pending' && order['status'] != 'batal')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(pesananId: order['id']),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Bayar Sekarang',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Invoice untuk pesanan selesai
                    if (order['status'] == 'selesai' && order['status_pembayaran'] == 'selesai')
                      const SizedBox(height: 16),
                    if (order['status'] == 'selesai' && order['status_pembayaran'] == 'selesai')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement download invoice
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur download invoice akan segera tersedia'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 8),
                              Text('Download Invoice'),
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
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading sampai date formatting siap
    if (_isLoading || !_isDateFormatInitialized) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      appBar: AppBar(
        title: const Text(
          'Daftar Pesanan Saya',
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
            onPressed: _fetchPesananUser,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _hasError
          ? _buildErrorState()
          : _pesananList.isEmpty
              ? _buildEmptyState()
              : _buildOrderList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498db)),
          ),
          const SizedBox(height: 16),
          // Text(
          //   _isDateFormatInitialized ? 'Memuat pesanan...' : 'Menyiapkan aplikasi...',
          //   style: TextStyle(
          //     color: Colors.grey[600],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _fetchPesananUser,
      backgroundColor: const Color(0xFF3498db),
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
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
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.list_alt,
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
                          'Total Pesanan',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_pesananList.length} Pesanan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List Pesanan
            ..._pesananList.map((order) => _buildOrderCard(order)).toList(),
          ],
        ),
      ),
    );
  }
}