class CreateFeedbackModel {
  final String label;
  final int rating;
  final int likes;
  final int dislikes;
  final String comment;
  final int userId;
  final int annonceId;

  CreateFeedbackModel({
    required this.label,
    required this.rating,
    required this.likes,
    required this.dislikes,
    required this.comment,
    required this.userId,
    required this.annonceId,
  });

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "rating": rating,
      "likes": likes,
      "dislikes": dislikes,
      "comment": comment,
      "user_id": userId,
      "annonce": annonceId,
    };
  }
}
