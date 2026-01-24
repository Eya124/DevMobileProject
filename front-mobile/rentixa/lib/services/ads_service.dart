import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:http/http.dart' as http;
import 'package:rentixa/models/ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  // --- URL CONFIGURATION ---
  static String get baseUrl {
    // 1. If running on Web, use localhost
      return 'http://10.0.2.2:8111/annonces';
    // 2. If running on Android Emulator, use localhost
    // 3. If running on Physical Device, use your PC's IP 
  }

  /// 1. Get all advertisements
  static Future<List<Ads>> getAllAds() async {
    try {
      final url = Uri.parse('$baseUrl/all');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> adsList = data is List ? data : (data['list_annonces'] ?? []);
        return adsList.map((json) => Ads.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load advertisements');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// 2. Get All States
  static Future<List<dynamic>> getAllStates() async {
    try {
      final url = Uri.parse('$baseUrl/all_states');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('states')) return data['states'];
      }
      return [];
    } catch (e) {
      print('DEBUG: Error fetching states: $e');
      return [];
    }
  }

  /// 3. Get Delegations
  static Future<List<dynamic>> getAllDelegationsByStateId(int? stateId) async {
    try {
      if (stateId == null) return [];
      final url = Uri.parse('$baseUrl/all_delegations_by_state/$stateId');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('delegations_by_state')) {
          return data['delegations_by_state'];
        } else if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching delegations: $e');
      return [];
    }
  }

  /// 4. Add Advertisement (Fixed parameter to match Modal)
  static Future<http.Response> addAd({
    required Ads ad,
    required List<Map<String, dynamic>> images, // Fixed to accept byte data
    String? userId,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/add');
      var request = http.MultipartRequest('POST', url);

      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Fields
      request.fields['title'] = ad.title;
      request.fields['description'] = ad.description ?? '';
      request.fields['size'] = ad.size ?? 'S'; 
      request.fields['price'] = ad.price.toString();
      request.fields['state'] = ad.state.toString();
      request.fields['delegation'] = ad.delegation?.toString() ?? '';
      request.fields['type'] = ad.type.toString();
      request.fields['phone'] = ad.phone.toString();
      if (userId != null) request.fields['user'] = userId;

      // Images from bytes (Works on Web and Mobile)
      for (var imgData in images) {
        request.files.add(http.MultipartFile.fromBytes(
          'images', 
          imgData['bytes'] as Uint8List,
          filename: imgData['name'],
        ));
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Failed to add advertisement: $e');
    }
  }

  /// 5. Update Advertisement (NEW)
  static Future<http.Response> updateAd({
    required int adId,
    required Ads ad,
    required List<Map<String, dynamic>> images,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/update/$adId'); // Ensure this matches Django URL
      var request = http.MultipartRequest('PUT', url);

      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = ad.title;
      request.fields['description'] = ad.description ?? '';
      request.fields['size'] = ad.size ?? 'S'; 
      request.fields['price'] = ad.price.toString();
      request.fields['state'] = ad.state.toString();
      request.fields['delegation'] = ad.delegation?.toString() ?? '';
      request.fields['type'] = ad.type.toString();
      request.fields['phone'] = ad.phone.toString();

      for (var imgData in images) {
        request.files.add(http.MultipartFile.fromBytes(
          'images', 
          imgData['bytes'] as Uint8List,
          filename: imgData['name'],
        ));
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Failed to update advertisement: $e');
    }
  }

  /// 6. Get individual details
  static Future<Map<String, dynamic>> getAdDetails(int adId) async {
    try {
      final url = Uri.parse('$baseUrl/$adId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Ad not found');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// 7. Get all Types
  static Future<List<dynamic>> getAllTypes() async {
    try {
      final url = Uri.parse('$baseUrl/all_types'); 
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error in getAllTypes: $e");
      return [];
    }
  }

  /// 8. Delete Advertisement
  static Future<bool> deleteAd(int id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token') ?? 
                            prefs.getString('token') ?? 
                            prefs.getString('access');

      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Exception: $e");
      return false;
    }
  }
}