import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint.dart';

class ComplaintService {
  static const String baseUrl = "http://localhost:8111/complaints";

  /// ✏️ UPDATE COMPLAINT STATUS
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 📥 GET ALL COMPLAINTS
  static Future<List<Complaint>> getAll() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['Complaints'] as List)
          .map((e) => Complaint.fromJson(e))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des réclamations');
    }
  }

  /// ➕ CREATE COMPLAINT
  static Future<void> create({
    required String title,
    required String description,
    required int userId,
  }) async {
    final token = await _token();

    await http.post(
      Uri.parse('$baseUrl/create/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'Text': description,
        'user': userId,
        'status': 'pending',
      }),
    );
  }

  /// 🗑 DELETE
  static Future<void> delete(int id) async {
    final token = await _token();

    await http.delete(
      Uri.parse('$baseUrl/delete/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// ➕ UPDATE COMPLAINT
  static Future<void> update({
    required int id,
    required String title,
    required String description,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Token manquant');

    final response = await http.put(
      Uri.parse('$baseUrl/update/$id/'), // Endpoint backend
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'description': description}),
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de mettre à jour la réclamation');
    }
  }

  /// 💬 REPLY
  static Future<void> reply({
    required int id,
    required String reply,
    required String title,
    required int userId,
  }) async {
    final token = await _token();

    await http.put(
      Uri.parse('$baseUrl/reply/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reply': reply, 'title': title, 'user': userId}),
    );
  }
}
