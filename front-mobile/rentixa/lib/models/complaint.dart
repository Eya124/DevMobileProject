class Complaint {
  final int id;
  final String title;
  final String description;
  final String status;
  final String? reply;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.reply,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'],
      description: json['Text'], // ⚠️ corrige la clé
      status: json['status'],
      reply: json['reply'] as String?, // nullable
      userId: json['user'] is int ? json['user'] : json['user']['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
