import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laundry_mobile/services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
  bool _isDateFormatInitialized = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeDateFormatting().then((_) {
      _fetchPesananUser();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getStoredUser();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _isDateFormatInitialized = true;
      });
    } catch (e) {
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
    }
  }

  // TAMPILKAN MODAL NOTA
  void _showNotaModal(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotaModal(
        pesananData: order,
        userData: _userData!,
        onDownloadPDF: _generatePDF,
      ),
    );
  }
// Minta Permission Storage
Future<bool> _requestPermission() async {
  try {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } catch (e) {
    print('Permission error: $e');
    return false;
  }
}

// Dapatkan path folder Download
Future<String?> _getDownloadsDirectory() async {
  if (Platform.isAndroid) {
    // Untuk Android, gunakan external storage
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final downloadsPath = '${directory.path}/Download';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return downloadsPath;
    }
  } else if (Platform.isIOS) {
    // Untuk iOS, gunakan documents directory
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  return null;
}

// Buka folder Download (Android saja)
void _openDownloadsFolder() async {
  if (Platform.isAndroid) {
    try {
      const url = 'content://com.android.externalstorage.documents/document/primary:Download';
      // Atau gunakan package: https://pub.dev/packages/open_file
      // await OpenFile.open(url);
    } catch (e) {
      print('Error opening folder: $e');
    }
  }
}
  // GENERATE PDF
  Future<void> _generatePDF(Map<String, dynamic> pesananData) async {
    try {
      // Minta permission storage dulu
      if (await _requestPermission()) {
        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Text(
                      'NOTA LAUNDRY EXPRESS',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 20),

                  // Informasi Perusahaan
                  pw.Center(
                    child: pw.Text(
                      'LAUNDRY EXPRESS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Jl. Contoh No. 123, Jakarta',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Telp: 0812-3456-7890',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 20),

                  // Informasi Pesanan
                  _buildPDFRow(
                    'ID Pesanan',
                    pesananData['order_id'] ?? pesananData['id'].toString(),
                  ),
                  _buildPDFRow(
                    'Tanggal',
                    _formatDateForPDF(pesananData['tanggal']),
                  ),
                  _buildPDFRow(
                    'Pelanggan',
                    _userData?['username'] ?? 'Pelanggan',
                  ),
                  _buildPDFRow('Layanan', pesananData['layanan'] ?? 'N/A'),
                  _buildPDFRow('Status', pesananData['status'] ?? 'pending'),
                  _buildPDFRow(
                    'Status Pembayaran',
                    pesananData['status_pembayaran'] ?? 'pending',
                  ),
                  _buildPDFRow('Jumlah', '${pesananData['jumlah'] ?? 0} kg'),
                  _buildPDFRow(
                    'Total Harga',
                    _formatRupiahForPDF(pesananData['total_harga']),
                  ),
                  _buildPDFRow(
                    'Metode',
                    pesananData['metode_pengambilan'] ?? 'ambil',
                  ),

                  if (pesananData['alamat_pengambilan'] != null)
                    _buildPDFRow(
                      'Alamat',
                      pesananData['alamat_pengambilan'] ?? '-',
                    ),

                  pw.SizedBox(height: 30),
                  pw.Divider(),
                  pw.SizedBox(height: 20),

                  // Catatan
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Catatan:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '• Simpan nota ini sebagai bukti transaksi\n'
                          '• Admin akan menghubungi untuk konfirmasi\n'
                          '• Pembayaran dapat dilakukan via transfer atau tunai',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Terima kasih atas kepercayaan Anda!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        // Simpan di folder Download
        final String? downloadsPath = await _getDownloadsDirectory();

        if (downloadsPath != null) {
          final fileName =
              'Nota_${pesananData['order_id'] ?? pesananData['id']}.pdf';
          final file = File('$downloadsPath/$fileName');
          await file.writeAsBytes(await pdf.save());

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF berhasil disimpan di Folder Download\n$fileName',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Buka Folder',
                onPressed: () {
                  // Buka folder download
                  _openDownloadsFolder();
                },
              ),
            ),
          );

          print('PDF saved to: ${file.path}');
        } else {
          throw Exception('Tidak bisa mengakses folder Download');
        }

        // Close modal
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin storage dibutuhkan untuk menyimpan PDF'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // LOAD FONT YANG SUPPORT UNICODE
  Future<pw.Font> _loadPdfFont() async {
    // Gunakan font default yang support Unicode
    return pw.Font.courier(); // atau pw.Font.helvetica()
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  String _formatDateForPDF(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatRupiahForPDF(dynamic number) {
    if (number == null) return 'Rp 0';
    double? value = double.tryParse(number.toString()) ?? 0.0;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(value);
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

  String _formatTanggal(String? dateString) {
    if (dateString == null) return '-';

    try {
      final date = DateTime.parse(dateString);

      if (!_isDateFormatInitialized) {
        return DateFormat('dd/MM/yyyy').format(date);
      }

      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
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
            style: TextStyle(color: Colors.grey),
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
            child: const Icon(Icons.error_outline, size: 50, color: Colors.red),
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

  return GestureDetector(
    onTap: () => _showNotaModal(order),
    child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16), // Kurangi padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan ID dan Status - FIX OVERFLOW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Text(
                              'ORDER #${order['order_id'] ?? order['id'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Perkecil font
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Perkecil padding
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order['status'] ?? 'pending'),
                            color: statusColor,
                            size: 12, // Perkecil icon
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getShortStatus(order['status'] ?? 'pending'),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10, // Perkecil font
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Informasi Pesanan
                _buildOrderDetailRow('Layanan', order['layanan'] ?? '-'),
                _buildOrderDetailRow('Berat', '${order['jumlah'] ?? 0} kg'),
                _buildOrderDetailRow('Total', _formatRupiah(order['total_harga'])),
                
                // Tanggal
                if (order['tanggal'] != null)
                  _buildOrderDetailRow(
                    'Tanggal',
                    _formatTanggal(order['tanggal']),
                  ),

                // Status Pembayaran
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: paymentStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order['status_pembayaran'] == 'selesai' 
                            ? Icons.payment 
                            : Icons.pending_actions,
                        color: paymentStatusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Pembayaran: ${_getShortPaymentStatus(order['status_pembayaran'] ?? 'pending')}',
                          style: TextStyle(
                            color: paymentStatusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Aksi
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Tombol Lihat Nota
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showNotaModal(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.receipt, size: 14),
                        label: const Text(
                          'Nota',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Tombol Bayar (jika pending)
                    if (order['status_pembayaran'] == 'pending' && order['status'] != 'batal')
                      Expanded(
                        child: ElevatedButton.icon(
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.payment, size: 14),
                          label: const Text(
                            'Bayar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Helper methods untuk text pendek
String _getShortStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return 'PENDING';
    case 'proses': return 'PROSES';
    case 'selesai': return 'SELESAI';
    case 'batal': return 'BATAL';
    default: return status.toUpperCase();
  }
}

String _getShortPaymentStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return 'PENDING';
    case 'selesai': return 'LUNAS';
    case 'gagal': return 'GAGAL';
    default: return status.toUpperCase();
  }
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isDateFormatInitialized) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      appBar: AppBar(
        title: const Text(
          'Daftar Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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

// WIDGET MODAL NOTA (SAMA DENGAN YANG DI ORDERSCREEN)
class NotaModal extends StatelessWidget {
  final Map<String, dynamic> pesananData;
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onDownloadPDF;

  const NotaModal({
    super.key,
    required this.pesananData,
    required this.userData,
    required this.onDownloadPDF,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Center(
            child: Text(
              'NOTA PESANAN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3498db),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info Pesanan
          _buildNotaItem(
            'ID Pesanan',
            pesananData['order_id'] ?? pesananData['id'].toString(),
          ),
          _buildNotaItem('Tanggal', _formatDate(pesananData['tanggal'])),
          _buildNotaItem('Pelanggan', userData['username'] ?? 'N/A'),
          _buildNotaItem('Layanan', pesananData['layanan'] ?? 'N/A'),
          _buildNotaItem('Status', pesananData['status'] ?? 'pending'),
          _buildNotaItem(
            'Status Pembayaran',
            pesananData['status_pembayaran'] ?? 'pending',
          ),
          _buildNotaItem('Jumlah', '${pesananData['jumlah'] ?? 0} kg'),
          _buildNotaItem(
            'Total Harga',
            _formatRupiah(pesananData['total_harga']),
          ),
          _buildNotaItem(
            'Metode Pengambilan',
            pesananData['metode_pengambilan'] ?? 'ambil',
          ),

          if (pesananData['alamat_pengambilan'] != null)
            _buildNotaItem('Alamat', pesananData['alamat_pengambilan'] ?? '-'),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Informasi Tambahan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3498db).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '📝 Informasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3498db),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nota ini dapat didownload dalam format PDF untuk keperluan dokumentasi.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol Aksi
          Row(
            children: [
              // Tombol Tutup
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3498db),
                    side: const BorderSide(color: Color(0xFF3498db)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
              const SizedBox(width: 12),

              // Tombol Download PDF
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onDownloadPDF(pesananData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498db),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Download PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
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
}
