import 'dart:convert';
import 'package:rentixa/models/create_feedback_model.dart';
import 'package:http/http.dart' as http;
import '../models/feedback.dart';

class FeedbackService {
  static const String baseUrl = "http://172.17.237.201:8111";

  static Future<void> submitFeedback(CreateFeedbackModel feedback) async {
    final response = await http.post(
      Uri.parse("$baseUrl/feedback/addFeedback"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(feedback.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to submit feedback");
    }
  }
    /// GET all feedbacks per annonce
  static Future<List<FeedbackModel>> getFeedbacks() async {
    final res = await http.get(
      Uri.parse('$baseUrl/feedback/getFeedback'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['Feedback'] as List)
          .map((e) => FeedbackModel.fromJson(e))
          .toList();
    }
    throw Exception("Failed to load feedbacks");
  }

  /// LIKE / DISLIKE
  static Future<void> updateReaction(
      int feedbackId, bool isLike) async {
    await http.put(
      Uri.parse('$baseUrl/feedback/addLikeDislike/$feedbackId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "type": isLike ? "like" : "dislike",
      }),
    );
  }
  // Edit existing feedback
  static Future<void> updateFeedback(
      int feedbackId, String label, String comment, int rating) async {
    final response = await http.put(
      Uri.parse("$baseUrl/feedback/updateFeedback/$feedbackId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "label": label,
        "comment": comment,
        "rating": rating,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to update feedback");
    }
  }

  /// DELETE feedback
  static Future<void> deleteFeedback(int feedbackId) async {
    await http.delete(
      Uri.parse('$baseUrl/feedback/deleteFeedback/$feedbackId'),
    );
  }
}
