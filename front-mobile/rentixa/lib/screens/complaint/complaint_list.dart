import 'package:flutter/material.dart';
import 'package:rentixa/models/complaint.dart';
import 'package:rentixa/services/complaint_service.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({Key? key}) : super(key: key);

  @override
  State<ComplaintListPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintListPage> {
  List<Complaint> complaints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    complaints = await ComplaintService.getAll();
    setState(() => loading = false);
  }

  /// 💬 REPLY
  void replyDialog(Complaint c) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Répondre à la plainte'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Votre réponse'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Envoyer la réponse via le service
              await ComplaintService.reply(
                id: c.id,
                reply: ctrl.text,
                title: c.title,
                userId: c.userId,
              );

              // Mettre à jour le status si ce n'est pas encore résolu
              if (c.status.toLowerCase() != 'resolved') {
                await ComplaintService.update(id: c.id, status: 'in progress');
              }

              Navigator.pop(context);
              load(); // recharger la liste
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des plaintes'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: complaints.length,
              itemBuilder: (_, i) {
                final c = complaints[i];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(c.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.text),
                        const SizedBox(height: 6),
                        Text(
                          'Status: ${c.status}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.status.toLowerCase() == 'pending'
                                ? Colors.red
                                : c.status.toLowerCase() == 'in progress'
                                ? Colors.orange
                                : c.status.toLowerCase() == 'resolved'
                                ? Colors.green
                                : Colors.green,
                          ),
                        ),
                        if (c.reply != null) ...[
                          const SizedBox(height: 6),
                          Text('Réponse: ${c.reply}'),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Affiche le bouton "reply" seulement si aucune réponse n'existe
                        if (c.reply == null)
                          IconButton(
                            icon: const Icon(Icons.reply),
                            onPressed: () => replyDialog(c),
                          ),

                        // Le bouton "delete" reste toujours visible
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ComplaintService.delete(c.id);
                            load();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
