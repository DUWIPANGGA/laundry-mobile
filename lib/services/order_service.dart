import 'api_service.dart';

class OrderService {
  // Method untuk mendapatkan detail pesanan
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      return await ApiService.getPesananDetail(orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Method untuk update metode pengambilan
  static Future<Map<String, dynamic>> updatePickupMethod(
    int orderId, 
    String method, 
    String? address
  ) async {
    try {
      return await ApiService.updateMetodePengambilan(orderId, method, address);
    } catch (e) {
      rethrow;
    }
  }

  // Method untuk mendapatkan riwayat pesanan
  static Future<Map<String, dynamic>> getOrderHistory() async {
    try {
      return await ApiService.getPesananUser();
    } catch (e) {
      rethrow;
    }
  }

  // Method untuk membatalkan pesanan
  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      // Endpoint untuk cancel order (perlu ditambahkan di backend)
      // Sementara menggunakan update status
      final response = await ApiService.updateMetodePengambilan(
        orderId, 
        'batal', 
        null
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Method untuk menghitung estimasi harga
  static double calculateEstimatePrice(String service, double weight) {
    // Logika perhitungan harga sementara
    // Di production, ini harus mengambil dari API
    final priceMap = {
      'Cuci Kering': 5000.0,
      'Cuci Setrika': 7000.0,
      'Setrika': 3000.0,
    };
    
    return (priceMap[service] ?? 0.0) * weight;
  }
}