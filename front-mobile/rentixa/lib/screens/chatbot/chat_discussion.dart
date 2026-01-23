import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/chatbot_service.dart';
import '../../providers/auth_provider.dart';

class ChatMessage {
  final int? id;
  final String text;
  final bool isUser;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
  });
}

class ChatDiscussionModal extends StatefulWidget {
  @override
  _ChatDiscussionModalState createState() => _ChatDiscussionModalState();
}

class _ChatDiscussionModalState extends State<ChatDiscussionModal> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // 🔥 toujours depuis la DB
  }

  int? getLastUserMessageIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return i;
    }
    return null;
  }

  /// 🔹 Charger l'historique depuis la DB
  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = int.tryParse(authProvider.userId ?? "0") ?? 0;

    try {
      final history = await ChatbotService.getHistory(userId);

      setState(() {
        _messages.clear();

        for (final item in history) {
          _messages.add(ChatMessage(
            id: item.id,
            text: item.question,
            isUser: true,
          ));

          _messages.add(ChatMessage(
            id: item.id,
            text: item.answer,
            isUser: false,
          ));
        }
      });
    } catch (e) {
      debugPrint("Erreur chargement historique: $e");
    }
  }

  /// 🔹 Envoyer message (reload DB après)
  Future<void> _sendMessage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = int.tryParse(authProvider.userId ?? "0") ?? 0;

    if (_controller.text.trim().isEmpty) return;

    final question = _controller.text;
    _controller.clear();

    setState(() => _isLoading = true);

    try {
      await ChatbotService.sendMessage(
        question: question,
        userId: userId,
      );

      await _loadHistory(); // 🔥 reload DB
    } catch (e) {
      debugPrint("Erreur envoi message: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Edit last user message
  Future<void> _editLastUserMessage(int index) async {
    final lastMsg = _messages[index];
    _controller.text = lastMsg.text;

    final newQuestion = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Modifier le message"),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Entrez le nouveau message",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: Text("Enregistrer"),
          ),
        ],
      ),
    );

    if (newQuestion == null || newQuestion.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (lastMsg.id != null) {
        await ChatbotService.updateLastMessage(
          messageId: lastMsg.id!,
          question: newQuestion,
        );
      }
      await _loadHistory(); // reload DB
      _controller.clear();
    } catch (e) {
      debugPrint("Erreur mise à jour message: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Supprimer message (reload DB après)
  Future<void> _deleteMessage(int index) async {
    final msg = _messages[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer"),
        content: Text("Supprimer ce message ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Oui"),
          ),
        ],
      ),
    );

    if (confirm != true || msg.id == null) return;

    try {
      await ChatbotService.deleteMessage(msg.id!);
      await _loadHistory(); // 🔥 reload DB
    } catch (e) {
      debugPrint("Erreur suppression: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastUserIndex = getLastUserMessageIndex();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
               Icon(
                  Icons.smart_toy, // AI/Chatbot icon
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Annonce AI Chatbot",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Posez vos questions pour rechercher des annonces",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];

                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button only for last user message
                      if (msg.isUser && index == lastUserIndex)
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () => _editLastUserMessage(index),
                        ),

                      // Delete button for all user messages
                      if (msg.isUser)
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteMessage(index),
                        ),

                      /// 🔥 Scroll horizontal pour messages longs
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            padding: EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg.text,
                              softWrap: true,
                              maxLines: null, // ✅ illimité
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                color: msg.isUser ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Input
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Posez votre question...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.orange),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
