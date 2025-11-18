class Harga {
  int id;
  String layanan;
  int hargaPerKg;

  Harga({
    required this.id,
    required this.layanan,
    required this.hargaPerKg,
  });

  factory Harga.fromJson(Map<String, dynamic> json) {
    return Harga(
      id: json['id'],
      layanan: json['layanan'],
      hargaPerKg: json['hargaPerKg'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'layanan': layanan,
        'hargaPerKg': hargaPerKg,
      };
}