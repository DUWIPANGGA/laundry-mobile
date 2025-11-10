import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.2:8000/api"; // IP laptop kamu

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Gagal login (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Tidak dapat terhubung ke server: $e");
    }
  }
}
