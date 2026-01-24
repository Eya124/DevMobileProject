import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/models/complaint.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/screens/complaint/Add_complaint.dart';
import 'package:rentixa/services/complaint_service.dart';
import 'package:rentixa/widgets/header.dart';

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

  /// 🔄 Charge les réclamations de l'utilisateur
  Future<void> load() async {
    setState(() => loading = true);

    try {
      final allComplaints = await ComplaintService.getAll();

      // Récupérer l'utilisateur connecté
      final userIdStr = Provider.of<AuthProvider>(context, listen: false).userId;
      final int userId = int.tryParse(userIdStr ?? '0') ?? 0;

      // Filtrer les réclamations de l'utilisateur
      complaints = allComplaints.where((c) => c.userId == userId).toList();
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
              isAdmin: false,
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
                  'Mes réclamations',
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddComplaintPage()),
          );
          load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 📝 Carte de réclamation avec Update + Delete
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
            // 📝 Update
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                await _updateComplaintDialog(c);
                load();
              },
            ),
            // ❌ Delete
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await ComplaintService.delete(c.id);
                load();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Dialogue pour modifier la réclamation
  Future<void> _updateComplaintDialog(Complaint c) async {
    final titleController = TextEditingController(text: c.title);
    final descController = TextEditingController(text: c.description);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier la réclamation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  descController.text.trim().isEmpty) return;

              await ComplaintService.update(
                id: c.id,
                title: titleController.text.trim(),
                description: descController.text.trim(),
              );

              if (mounted) Navigator.pop(context);
              load();
            },
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🔹 Couleur selon status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
}
