import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint.dart';

class ComplaintService {
  static const String baseUrl = 'http://10.0.2.2:8111/complaints';

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ✏️ UPDATE COMPLAINT STATUS
  static Future<void> update({required int id, required String status}) async {
    final token = await _token();
    if (token == null) throw Exception('Token manquant');

    final response = await http.put(
      Uri.parse('$baseUrl/update/$id/'), // endpoint corrigé
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de mettre à jour le status');
    }
  }

  /// 📥 GET ALL COMPLAINTS
  static Future<List<Complaint>> getAll() async {
    final token = await _token();
    if (token == null) throw Exception('Token manquant');

    final res = await http.get(
      Uri.parse('$baseUrl/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200)
      throw Exception('Erreur lors de la récupération des plaintes');

    final data = jsonDecode(res.body);

    // Ajuster la clé selon l'API
    return (data['complaints'] as List)
        .map((e) => Complaint.fromJson(e))
        .toList();
  }

  /// ➕ CREATE COMPLAINT
  static Future<void> create({
    required String title,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('user_id');

    if (token == null || userId == null) throw Exception('Session expirée');

    final response = await http.post(
      Uri.parse('$baseUrl/create/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'user': userId,
        'status': 'pending',
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Impossible de créer la plainte');
    }
  }

  /// 🗑 DELETE COMPLAINT
  static Future<void> delete(int id) async {
    final token = await _token();
    if (token == null) throw Exception('Token manquant');

    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Impossible de supprimer la plainte');
    }
  }

  /// 💬 REPLY TO COMPLAINT
  static Future<void> reply({required int id, required String reply}) async {
    final token = await _token();
    if (token == null) throw Exception('Token manquant');

    final response = await http.put(
      Uri.parse('$baseUrl/reply/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reply': reply}),
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de répondre à la plainte');
    }
  }
}
