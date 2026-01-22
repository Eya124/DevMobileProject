import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentixa/models/ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  // --- URL CONFIGURATION ---
  static String get baseUrl {
    // 1. If running on Web, use localhost
      return 'http://localhost:8111/annonces';
    // 2. If running on Android Emulator, use 10.0.2.2
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

  static Future<List<dynamic>> getAllStates() async {
  try {
    final url = Uri.parse('$baseUrl/all_states');
    print('DEBUG: Fetching states from $url'); // Confirming the URL
    
    final response = await http.get(url);
    print('DEBUG: Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('DEBUG: Data received: $data'); // See the actual JSON
      print('DEBUG: Data Type: ${data.runtimeType}'); // Check if it's a List or Map
      
      // If your Postman shows a direct list [{}, {}], this is correct:
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('states')) {
        return data['states'];
      }
    }
    return [];
  } catch (e) {
    print('DEBUG: Network Error: $e');
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
        
        // Look for the specific key your Django backend is sending
        if (data is Map && data.containsKey('delegations_by_state')) {
          return data['delegations_by_state'];
        } 
        // Fallback for direct list
        else if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching delegations: $e');
      return [];
    }
  }

 static Future<http.Response> addAd({
    required Ads ad,
    required List<String> imagePaths,
    String? userId,
    String? token,
  }) async {
    try {
      // Ensure the path is correct (usually /annonces/add based on your previous logs)
      final url = Uri.parse('$baseUrl/add');
      var request = http.MultipartRequest('POST', url);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // MATCHING DJANGO MODEL NAMES
      request.fields['title'] = ad.title;
      request.fields['description'] = ad.description ?? '';
      request.fields['size'] = ad.size ?? 'S'; 
      request.fields['price'] = ad.price.toString();
      
      // Changed from state_id to state, etc.
      request.fields['state'] = ad.state.toString();
      request.fields['delegation'] = ad.delegation?.toString() ?? '';
      request.fields['jurisdiction'] = '';
      request.fields['type'] = ad.type.toString();
      
      request.fields['phone'] = ad.phone.toString();
      request.fields['status'] = 'true';
      
      // If your model uses 'user' as the FK name:
      if (userId != null) request.fields['user'] = userId;

      for (String path in imagePaths) {
        var file = await http.MultipartFile.fromPath('images', path);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // DEBUG LOGGING
      if (response.statusCode == 400) {
        print('--- DJANGO ERROR BODY ---');
        print(response.body); // THIS WILL TELL US EXACTLY WHAT IS WRONG
        print('--------------------------');
      }

      return response;
    } catch (e) {
      print('DEBUG: Exception in addAd: $e');
      throw Exception('Failed to add advertisement: $e');
    }
  }

  /// 5. Get individual details
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

/// Get all Types
  static Future<List<dynamic>> getAllTypes() async {
    try {
      // Make sure '/types/all' matches your Django path 
      // (If states was '/all_states', check if this should be '/all_types')
      final url = Uri.parse('$baseUrl/all_types'); 
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        // We decode the direct list just like we did for states
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error in getAllTypes: $e");
      return [];
    }
  }

  static Future<bool> deleteAd(int id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // DEBUG: Let's see all keys currently stored
      print("Stored keys: ${prefs.getKeys()}");

      // Try all common keys
      final String? token = prefs.getString('access_token') ?? 
                            prefs.getString('token') ?? 
                            prefs.getString('access') ??
                            prefs.getString('jwt');

      if (token == null) {
        print("Error: No token found. Current keys are: ${prefs.getKeys()}");
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/annonces/delete/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );

      print("Delete response: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Exception: $e");
      return false;
    }
  }

}