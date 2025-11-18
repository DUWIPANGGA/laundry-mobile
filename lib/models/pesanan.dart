import 'user.dart';

class Pesanan {
  int id;
  int userId;
  String namaPelanggan;
  String layanan;
  double jumlah;
  double totalHarga;
  String tanggal;
  String status;
  String statusPembayaran;
  String? metodePengambilan;
  String? address;
  String? invoiceUrl;
  String orderId;
  User? user;

  Pesanan({
    required this.id,
    required this.userId,
    required this.namaPelanggan,
    required this.layanan,
    required this.jumlah,
    required this.totalHarga,
    required this.tanggal,
    required this.status,
    required this.statusPembayaran,
    this.metodePengambilan,
    this.address,
    this.invoiceUrl,
    required this.orderId,
    this.user,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      id: json['id'],
      userId: json['user_id'],
      namaPelanggan: json['nama_pelanggan'],
      layanan: json['layanan'],
      jumlah: json['jumlah']?.toDouble() ?? 0.0,
      totalHarga: json['total_harga']?.toDouble() ?? 0.0,
      tanggal: json['tanggal'],
      status: json['status'],
      statusPembayaran: json['status_pembayaran'],
      metodePengambilan: json['metode_pengambilan'],
      address: json['address'],
      invoiceUrl: json['invoice_url'],
      orderId: json['order_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nama_pelanggan': namaPelanggan,
        'layanan': layanan,
        'jumlah': jumlah,
        'total_harga': totalHarga,
        'tanggal': tanggal,
        'status': status,
        'status_pembayaran': statusPembayaran,
        'metode_pengambilan': metodePengambilan,
        'address': address,
        'invoice_url': invoiceUrl,
        'order_id': orderId,
        'user': user?.toJson(),
      };
}