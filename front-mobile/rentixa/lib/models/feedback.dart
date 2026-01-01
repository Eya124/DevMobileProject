class FeedbackModel {
  final int id;
  final String label;
  final int rating;
  int likes;
  int dislikes;
  final String comment;
  final int userId;
  final String firstName;
  final String lastName;
  final int annonceId;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.label,
    required this.rating,
    required this.likes,
    required this.dislikes,
    required this.comment,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.annonceId,
    required this.createdAt,
  });
  
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      label: json['label'],
      rating: json['rating'],
      likes: json['likes'],
      dislikes: json['dislikes'],
      comment: json['comment'] ?? '',
      userId: json['user_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      annonceId: json['annonce'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


  

