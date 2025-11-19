import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.100:8000/api";
  
  // Debug mode
  static const bool debugMode = true;

  // Helper method untuk debug print
  static void _debugPrint(String message) {
    if (debugMode) {
      print('🔍 [API_DEBUG] $message');
    }
  }
  static void debugPrint(String message) {
    if (debugMode) {
      print('🔍 [API_DEBUG] $message');
    }
  }

  // Helper method to get headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }
// ============ EMAIL VERIFICATION ENDPOINTS ============

static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
  try {
    final url = "$baseUrl/verify-email";
    final body = jsonEncode({
      "email": email,
      "otp": otp,
    });

    _debugPrint('📤 VERIFY EMAIL REQUEST:');
    _debugPrint('   URL: $url');
    _debugPrint('   Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: body,
    );

    final data = _handleResponse(response);
    
    // Save token jika verifikasi berhasil
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
      await prefs.setString('user', jsonEncode(data['data']['user']));
      _debugPrint('✅ EMAIL VERIFIED: Token saved for ${data['data']['user']['username']}');
    }
    
    return data;
  } catch (e) {
    _debugPrint('💥 VERIFY EMAIL EXCEPTION: $e');
    throw Exception("Verify email error: $e");
  }
}

static Future<Map<String, dynamic>> resendOtp(String email) async {
  try {
    final url = "$baseUrl/resend-otp";
    final body = jsonEncode({
      "email": email,
    });

    _debugPrint('📤 RESEND OTP REQUEST:');
    _debugPrint('   URL: $url');
    _debugPrint('   Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: body,
    );

    return _handleResponse(response);
  } catch (e) {
    _debugPrint('💥 RESEND OTP EXCEPTION: $e');
    throw Exception("Resend OTP error: $e");
  }
}
  // Helper method to handle response
// Helper method to handle response
static dynamic _handleResponse(http.Response response) {
  _debugPrint('📥 RESPONSE RECEIVED:');
  _debugPrint('   URL: ${response.request?.url}');
  _debugPrint('   Status: ${response.statusCode}');
  _debugPrint('   Headers: ${response.headers}');
  _debugPrint('   Body: ${response.body}');
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 403) {
    // Handle forbidden (email not verified)
    final data = jsonDecode(response.body);
    _debugPrint('❌ FORBIDDEN: ${data['message']}');
    return data;
  } else {
    _debugPrint('❌ ERROR: Request failed with status ${response.statusCode}');
    throw Exception("Request failed (${response.statusCode}): ${response.body}");
  }
}
  // ============ AUTH ENDPOINTS ============
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = "$baseUrl/login";
      final body = jsonEncode({"username": username, "password": password});
      
      _debugPrint('📤 LOGIN REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Body: $body');
      _debugPrint('   Headers: ${{"Accept": "application/json", "Content-Type": "application/json"}}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: body,
      );

      final data = _handleResponse(response);
      
      // Save token to shared preferences
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('user', jsonEncode(data['data']['user']));
        _debugPrint('✅ LOGIN SUCCESS: Token saved, User: ${data['data']['user']['username']}');
      } else {
        _debugPrint('❌ LOGIN FAILED: ${data['message']}');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 LOGIN EXCEPTION: $e');
      throw Exception("Tidak dapat terhubung ke server: $e");
    }
  }

  static Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String password, 
    String address
  ) async {
    try {
      final url = "$baseUrl/register";
      final body = jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "address": address,
      });

      _debugPrint('📤 REGISTER REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: body,
      );

      final data = _handleResponse(response);
      
      // Save token to shared preferences
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('user', jsonEncode(data['data']['user']));
        _debugPrint('✅ REGISTER SUCCESS: User ${data['data']['user']['username']} created');
      } else {
        _debugPrint('❌ REGISTER FAILED: ${data['message']}');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 REGISTER EXCEPTION: $e');
      throw Exception("Tidak dapat terhubung ke server: $e");
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/logout";
      
      _debugPrint('📤 LOGOUT REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Headers: ${headers.containsKey('Authorization') ? 'Token present' : 'No token'}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      
      _debugPrint('✅ LOGOUT SUCCESS: Local data cleared');
      
      return _handleResponse(response);
    } catch (e) {
      _debugPrint('💥 LOGOUT EXCEPTION: $e');
      throw Exception("Logout error: $e");
    }
  }


 // Tambahkan di ApiService.dart

// Untuk update profile
static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
  try {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/profile"),
      headers: headers,
      body: jsonEncode(profileData),
    );
    
    // Update stored user data if successful
    final data = _handleResponse(response);
    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data['data']));
    }
    
    return data;
  } catch (e) {
    _debugPrint('💥 UPDATE PROFILE EXCEPTION: $e');
    throw Exception("Update profile error: $e");
  }
}

// Untuk get profile
static Future<Map<String, dynamic>> getProfile() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: headers,
    );
    return _handleResponse(response);
  } catch (e) {
    _debugPrint('💥 GET PROFILE EXCEPTION: $e');
    throw Exception("Get profile error: $e");
  }
}
  // ============ HARGA ENDPOINTS ============
  static Future<Map<String, dynamic>> getHarga() async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/harga";
      
      _debugPrint('📤 GET HARGA REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _debugPrint('💥 GET HARGA EXCEPTION: $e');
      throw Exception("Get harga error: $e");
    }
  }

  // ============ PESANAN ENDPOINTS ============
  static Future<Map<String, dynamic>> createPesanan(Map<String, dynamic> pesananData) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/pesanan";
      
      _debugPrint('📤 CREATE PESANAN REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Body: $pesananData');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(pesananData),
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        _debugPrint('✅ PESANAN CREATED: ID ${data['data']['id']}');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 CREATE PESANAN EXCEPTION: $e');
      throw Exception("Create pesanan error: $e");
    }
  }

  static Future<Map<String, dynamic>> getPesananUser() async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/pesanan";
      
      _debugPrint('📤 GET PESANAN USER REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        _debugPrint('✅ PESANAN RETRIEVED: ${data['data'].length} orders found');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 GET PESANAN EXCEPTION: $e');
      throw Exception("Get pesanan error: $e");
    }
  }

  static Future<Map<String, dynamic>> getPesananDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/pesanan/$id";
      
      _debugPrint('📤 GET PESANAN DETAIL REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _debugPrint('💥 GET PESANAN DETAIL EXCEPTION: $e');
      throw Exception("Get pesanan detail error: $e");
    }
  }

  static Future<Map<String, dynamic>> updateMetodePengambilan(int id, String metode, String? alamat) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/pesanan/$id/pengambilan";
      final body = {
        'metode_pengambilan': metode,
        'alamat_pengambilan': alamat,
      };
      
      _debugPrint('📤 UPDATE METODE PENGAMBILAN REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        _debugPrint('✅ METODE PENGAMBILAN UPDATED');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 UPDATE METODE PENGAMBILAN EXCEPTION: $e');
      throw Exception("Update metode pengambilan error: $e");
    }
  }

  // ============ PAYMENT ENDPOINTS ============
  static Future<Map<String, dynamic>> createPaymentTransaction(int pesananId) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/payment/create";
      final body = {'pesanan_id': pesananId};
      
      _debugPrint('📤 CREATE PAYMENT REQUEST:');
      _debugPrint('   URL: $url');
      _debugPrint('   Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        _debugPrint('✅ PAYMENT TRANSACTION CREATED: ${data['data']['snap_token'] != null ? 'Snap token received' : 'No token'}');
      }
      
      return data;
    } catch (e) {
      _debugPrint('💥 CREATE PAYMENT EXCEPTION: $e');
      throw Exception("Create payment transaction error: $e");
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int pesananId) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/payment/status/$pesananId";
      
      _debugPrint('📤 GET PAYMENT STATUS REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _debugPrint('💥 GET PAYMENT STATUS EXCEPTION: $e');
      throw Exception("Get payment status error: $e");
    }
  }

  // ============ INVOICE ENDPOINTS ============
  static Future<Map<String, dynamic>> getInvoiceData(int id) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/invoice/$id";
      
      _debugPrint('📤 GET INVOICE DATA REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _debugPrint('💥 GET INVOICE DATA EXCEPTION: $e');
      throw Exception("Get invoice data error: $e");
    }
  }

  static Future<http.Response> downloadInvoice(int id) async {
    try {
      final headers = await _getHeaders();
      final url = "$baseUrl/invoice/$id/download";
      
      _debugPrint('📤 DOWNLOAD INVOICE REQUEST:');
      _debugPrint('   URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      _debugPrint('📥 DOWNLOAD INVOICE RESPONSE:');
      _debugPrint('   Status: ${response.statusCode}');
      _debugPrint('   Content-Type: ${response.headers['content-type']}');
      _debugPrint('   Content-Length: ${response.headers['content-length']}');
      
      return response;
    } catch (e) {
      _debugPrint('💥 DOWNLOAD INVOICE EXCEPTION: $e');
      throw Exception("Download invoice error: $e");
    }
  }

  // ============ UTILITY METHODS ============
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLoggedIn = token != null && token.isNotEmpty;
    
    _debugPrint('🔐 CHECK LOGIN STATUS: $isLoggedIn');
    if (isLoggedIn) {
      _debugPrint('   Token exists: ${token!.substring(0, 20)}...');
    }
    
    return isLoggedIn;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _debugPrint('🧹 AUTH DATA CLEARED');
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    
    if (userString != null) {
      final userData = jsonDecode(userString);
      _debugPrint('👤 STORED USER DATA: ${userData['username']}');
      return userData;
    } else {
      _debugPrint('👤 NO STORED USER DATA FOUND');
      return null;
    }
  }

  // Method untuk test koneksi ke server
  static Future<bool> testConnection() async {
    try {
      _debugPrint('🧪 TESTING CONNECTION TO: $baseUrl');
      final response = await http.get(Uri.parse(baseUrl));
      _debugPrint('🧪 CONNECTION TEST RESULT: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      _debugPrint('💥 CONNECTION TEST FAILED: $e');
      return false;
    }
  }
}