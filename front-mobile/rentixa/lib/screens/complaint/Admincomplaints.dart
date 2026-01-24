import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/models/complaint.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/complaint_service.dart';
import 'package:rentixa/widgets/header.dart';

class AdminComplaintPage extends StatefulWidget {
  const AdminComplaintPage({Key? key}) : super(key: key);

  @override
  State<AdminComplaintPage> createState() => _AdminComplaintPageState();
}

class _AdminComplaintPageState extends State<AdminComplaintPage> {
  List<Complaint> complaints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final allComplaints = await ComplaintService.getAll();
      complaints = allComplaints;
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
      complaints = [];
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Header(
              isConnected: authProvider.userId != null,
              isVerified: authProvider.userId != null,
              isAdmin: true,
              username: authProvider.userInitials,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toutes les réclamations',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: load,
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : complaints.isEmpty
                ? const Center(child: Text("Aucune réclamation trouvée"))
                : ListView.builder(
                    itemCount: complaints.length,
                    itemBuilder: (_, i) => _buildComplaintCard(complaints[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          c.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(c.description),
            const SizedBox(height: 8),
            Text(
              'Statut: ${c.status}',
              style: TextStyle(
                color: _getStatusColor(c.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Icône de réponse désormais toujours visible
            IconButton(
              icon: const Icon(Icons.reply, color: Colors.blue),
              onPressed: () async {
                await _replyDialog(c);
                load();
              },
            ),
            // ℹ️ Détails
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.grey),
              onPressed: () => _showDetailsDialog(c),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _replyDialog(Complaint c) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Répondre à : ${c.title}"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Votre réponse",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await ComplaintService.reply(
                id: c.id,
                reply: controller.text.trim(),
                title: c.title,
                userId: c.userId,
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Envoyer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailsDialog(Complaint c) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Détails de la réclamation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Titre : ${c.title}"),
            const SizedBox(height: 8),
            Text("Description : ${c.description}"),
            const SizedBox(height: 8),
            Text("Créée le : ${_formatDate(c.createdAt)}"),
            const SizedBox(height: 8),
            Text("Dernière mise à jour : ${_formatDate(c.updatedAt)}"),
            const SizedBox(height: 8),
            Text(
              "Statut : ${c.status}",
              style: TextStyle(
                color: _getStatusColor(c.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
