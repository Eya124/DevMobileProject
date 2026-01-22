class Complaint {
  final int id;
  final String title;
  final String text;
  final String status;
  final String? reply;
  final int userId;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.title,
    required this.text,
    required this.status,
    this.reply,
    required this.userId,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'],
      text: json['Text'],
      status: json['status'],
      reply: json['reply'],
      userId: json['user'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
