import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';

class ChatbotService {
  static const String baseUrl = "http://172.24.162.10:8111/chatbot";

  /// Send message
  static Future<String> sendMessage({
    required String question,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/query/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": question,
        "user": userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["answer"] ?? "";
    } else {
      throw Exception("Failed to send message");
    }
  }

static Future<List<ChatHistoryModel>> getHistory(int userId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/messages/$userId"),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(response.body);

    final List messages = body['messages'];

    return messages
        .map((e) => ChatHistoryModel.fromJson(e))
        .toList();
  } else {
    throw Exception("Failed to load history");
  }
  
}
 /// Delete message
  static Future<void> deleteMessage(int messageId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/message/delete/$messageId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete message");
    }
  }
    /// 🔹 Update last user message and bot response
  static Future<void> updateLastMessage({
    required int messageId,
    required String question,
  }) async {
    final url = Uri.parse("$baseUrl/message/$messageId/");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": question,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la mise à jour du message");
    }
  }
}
