class ChatHistoryModel {
  final int id;
  final String question;
  final String answer;
  final int createdBy;
  final DateTime createdAt;

  ChatHistoryModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryModel(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
