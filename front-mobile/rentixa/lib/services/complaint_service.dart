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

  /// ✏️ UPDATE COMPLAINT
  static Future<void> update({required int id, required String status}) async {
    // Exemple : requête API PUT ou PATCH
    final response = await http.put(
      Uri.parse('$baseUrl/complaints/$id/'),
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de mettre à jour le status');
    }
  }

  /// 📥 GET ALL COMPLAINTS
  static Future<List<Complaint>> getAll() async {
    final token = await _token();

    final res = await http.get(
      Uri.parse('$baseUrl/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(res.body);

    return (data['Complaints'] as List)
        .map((e) => Complaint.fromJson(e))
        .toList();
  }

  /// ➕ CREATE COMPLAINT
  static Future<void> create({
    required String title,
    required String text,
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
        'Text': text,
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
