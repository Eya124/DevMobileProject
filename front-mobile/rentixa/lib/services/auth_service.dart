import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentixa/models/user.dart';

class AuthService {
  // Use different URLs for emulator vs physical device
  static String get baseUrl {
    // For Android emulator, use 10.0.2.2 to access host machine
    // For physical device, use the actual IP address of your computer
    // You may need to change this to your computer's actual IP address
    return 'http://localhost:8111'; // For physical device (your computer's IP)
    // return 'http://10.0.2.2:8111'; // For emulator
  }

  static Future<http.Response> signUp({
    required User user,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/authentification/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...user.toJson(),
        "password": password,
      }),
    );
    return response;
  }

  /// Sign in with email and password.
  static Future<http.Response> signIn({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/authentification/signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return response;
  }

  /// Verifies the OTP code for the user with a dynamic userId.
  static Future<http.Response> verifyOtp({
    required String userId,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/authentification/verify_code/$userId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "verification_code": code,
      }),
    );
    return response;
  }

  /// Resend verification code to the user with a dynamic userId.
  static Future<http.Response> resendVerificationCode({
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/authentification/resend_verification_code/$userId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  }

  /// Logout the current user.
  static Future<http.Response> logout() async {
    final url = Uri.parse('$baseUrl/authentification/logout');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  }
}