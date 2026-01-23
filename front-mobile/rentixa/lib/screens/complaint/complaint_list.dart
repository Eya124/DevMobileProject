import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/models/complaint.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/screens/complaint/Add_complaint.dart';
import 'package:rentixa/services/auth_service.dart';
import 'package:rentixa/services/complaint_service.dart';

// ✅ Import du Header
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

  Future<void> load() async {
    setState(() => loading = true);
    try {
      complaints = await ComplaintService.getAll();
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
    }
    setState(() => loading = false);
  }

  // ... (Tes méthodes addComplaintDialog et replyDialog restent ici) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2), // Couleur de fond harmonisée
      // 1. ✅ AJOUT DU HEADER ICI
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Header(
              isConnected: authProvider.userId != null,
              isVerified: authProvider.userId != null,
              isAdmin: false, // À mettre à true si c'est le panel admin
              username: authProvider.userInitials,
            );
          },
        ),
      ),

      body: Column(
        children: [
          // Titre de la page sous le header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestion des plaintes',
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
                    itemBuilder: (_, i) {
                      final c = complaints[i];
                      return _buildComplaintCard(
                        c,
                      ); // Utilisation de la fonction de dessin
                    },
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

  // 2. ✅ LA FONCTION QUI DESSINE CHAQUE CARTE (pour que ton code fonctionne)
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
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () async {
            await ComplaintService.delete(c.id);
            load();
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
