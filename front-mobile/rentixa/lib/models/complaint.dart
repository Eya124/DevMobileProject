class Complaint {
  final int id;
  final String title;
  final String description; // correspond à description dans Django
  final String status;
  final String? reply; // si tu ajoutes ce champ dans Django
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt; // ajouté pour refléter Django

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
      description: json['description'], // corrige json['Text']
      status: json['status'],
      reply: json['reply'], // nullable
      userId: json['user'], // id de l'utilisateur
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'reply': reply,
      'user': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
