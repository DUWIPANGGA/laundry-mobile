class Transaksi {
  int id;
  int pesananId;
  String metodePembayaran;
  String statusPembayaran;
  String? tanggalPembayaran;

  Transaksi({
    required this.id,
    required this.pesananId,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.tanggalPembayaran,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      id: json['id'],
      pesananId: json['pesanan_id'],
      metodePembayaran: json['metode_pembayaran'],
      statusPembayaran: json['status_pembayaran'],
      tanggalPembayaran: json['tanggal_pembayaran'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pesanan_id': pesananId,
        'metode_pembayaran': metodePembayaran,
        'status_pembayaran': statusPembayaran,
        'tanggal_pembayaran': tanggalPembayaran,
      };
}