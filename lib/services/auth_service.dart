import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:laundry_mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const bool debugMode = true;

  // Helper method untuk debug print
  static void _debugPrint(String message) {
    if (debugMode) {
      print('🔐 [AUTH_SERVICE] $message');
    }
  }

  // ============ LOGIN & REGISTER ============
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      _debugPrint('Attempting login for: $username');
      
      final response = await ApiService.login(username, password);
      
      if (response['success'] == true) {
        _debugPrint('✅ Login successful');
        return response;
      } else if (response['needs_verification'] == true) {
        _debugPrint('🔄 Email verification required for: ${response['email']}');
        
        // LANGSUNG REQUEST OTP ketika butuh verifikasi
        final resendResult = await resendOtp(response['email']);
        
        if (resendResult['success'] == true) {
          _debugPrint('📧 OTP sent successfully');
          return {
            'success': false,
            'needs_verification': true,
            'email': response['email'],
            'message': 'Silakan verifikasi email terlebih dahulu. OTP telah dikirim.'
          };
        } else {
          _debugPrint('❌ Failed to send OTP');
          return {
            'success': false,
            'needs_verification': true,
            'email': response['email'],
            'message': 'Silakan verifikasi email terlebih dahulu. ${resendResult['message']}'
          };
        }
      } else {
        _debugPrint('❌ Login failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      _debugPrint('💥 Login error: $e');
      return {
        'success': false,
        'message': 'Login gagal: $e'
      };
    }
  }
  static Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    try {
      _debugPrint('Verifying email: $email with OTP: $otp');
      
      final response = await ApiService.verifyEmail(email, otp);
      
      if (response['success'] == true) {
        _debugPrint('✅ Email verification successful');
        return response;
      } else {
        _debugPrint('❌ Email verification failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      _debugPrint('💥 Email verification error: $e');
      return {
        'success': false,
        'message': 'Verifikasi email gagal: $e'
      };
    }
  }

  /// Kirim ulang OTP verifikasi email
  static Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      _debugPrint('Resending OTP to: $email');
      
      final response = await ApiService.resendOtp(email);
      
      if (response['success'] == true) {
        _debugPrint('✅ OTP sent successfully');
        return response;
      } else {
        _debugPrint('❌ Failed to send OTP: ${response['message']}');
        return response;
      }
    } catch (e) {
      _debugPrint('💥 Resend OTP error: $e');
      return {
        'success': false,
        'message': 'Gagal mengirim ulang OTP: $e'
      };
    }
  }

  /// Register user baru
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String address,
  }) async {
    try {
      _debugPrint('Attempting registration for: $username ($email)');
      
      final response = await ApiService.register(username, email, password, address);
      
      if (response['success'] == true) {
        _debugPrint('✅ Registration successful');
        
        // Check jika perlu verifikasi email
        if (response['data']['needs_verification'] == true) {
          _debugPrint('📧 Email verification required after registration');
          return {
            'success': true,
            'needs_verification': true,
            'email': email,
            'message': response['message'] ?? 'Registrasi berhasil. Silakan verifikasi email Anda.'
          };
        }
        
        return response;
      } else {
        _debugPrint('❌ Registration failed: ${response['message']}');
        return response;
      }
    } catch (e) {
      _debugPrint('💥 Registration error: $e');
      return {
        'success': false,
        'message': 'Registrasi gagal: $e'
      };
    }
  }

 
  // ============ AUTH MANAGEMENT ============

  /// Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      _debugPrint('Logging out user');
      
      final response = await ApiService.logout();
      return response;
    } catch (e) {
      _debugPrint('💥 Logout error: $e');
      // Clear local data even if API call fails
      await clearAuthData();
      return {
        'success': false,
        'message': 'Logout error: $e'
      };
    }
  }

  /// Cek status login user
  static Future<bool> isLoggedIn() async {
    return await ApiService.isLoggedIn();
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getStoredUser() async {
    return await ApiService.getStoredUser();
  }

  /// Clear auth data
  static Future<void> clearAuthData() async {
    await ApiService.clearAuthData();
    _debugPrint('🧹 Auth data cleared');
  }

  /// Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      _debugPrint('Fetching user profile');
      
      final response = await ApiService.getProfile();
      return response;
    } catch (e) {
      _debugPrint('💥 Get profile error: $e');
      return {
        'success': false,
        'message': 'Gagal mengambil profil: $e'
      };
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _debugPrint('Updating user profile');
      
      final response = await ApiService.updateProfile(profileData);
      return response;
    } catch (e) {
      _debugPrint('💥 Update profile error: $e');
      return {
        'success': false,
        'message': 'Gagal update profil: $e'
      };
    }
  }

  // ============ VERIFICATION STATUS ============

  /// Cek apakah email user sudah terverifikasi
  static Future<bool> isEmailVerified() async {
    try {
      final user = await getStoredUser();
      if (user != null && user['email_verified'] != null) {
        return user['email_verified'] == true;
      }
      
      // Fallback: cek dari profile API
      final profile = await getProfile();
      if (profile['success'] == true) {
        return profile['data']['email_verified'] == true;
      }
      
      return false;
    } catch (e) {
      _debugPrint('💥 Check email verification error: $e');
      return false;
    }
  }

  /// Validasi token dan status user
  static Future<Map<String, dynamic>> validateAuthStatus() async {
    try {
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'User not logged in',
          'isValid': false
        };
      }

      final profile = await getProfile();
      if (profile['success'] == true) {
        return {
          'success': true,
          'isValid': true,
          'user': profile['data'],
          'email_verified': profile['data']['email_verified'] ?? false
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid token',
          'isValid': false
        };
      }
    } catch (e) {
      _debugPrint('💥 Validate auth status error: $e');
      return {
        'success': false,
        'message': 'Validation error: $e',
        'isValid': false
      };
    }
  }
}