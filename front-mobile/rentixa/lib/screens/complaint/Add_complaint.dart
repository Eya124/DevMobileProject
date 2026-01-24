import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentixa/providers/auth_provider.dart';
import 'package:rentixa/services/complaint_service.dart';
import 'package:rentixa/widgets/header.dart';
import 'package:rentixa/screens/complaint/complaint_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddComplaintPage extends StatefulWidget {
  const AddComplaintPage({Key? key}) : super(key: key);

  @override
  _AddComplaintPageState createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _submitting = false;

  final Color primaryColor = const Color(0xFF008080);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception("Session expirée : Veuillez vous reconnecter.");
      }

      final userId = int.parse(
        Provider.of<AuthProvider>(context, listen: false).userId!,
      );

      await ComplaintService.create(
        title: _titleController.text.trim(),
        description: _textController.text.trim(),
        userId: userId,
      );

      if (!mounted) return;

      _showSnackBar("Réclamation envoyée avec succès !", Colors.green);

      // Naviguer vers la page liste
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ComplaintListPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Erreur : ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) => Header(
            isConnected: true,
            isVerified: true,
            isAdmin: false,
            username: auth.userInitials,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Nouvelle Réclamation",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel("Titre"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration(
                  hint: "Ex: Fuite d'eau",
                  icon: Icons.title,
                ),
                validator: (v) => v!.isEmpty ? "Titre requis" : null,
              ),
              const SizedBox(height: 20),
              _buildLabel("Description"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                maxLines: 5,
                decoration: _buildInputDecoration(
                  hint: "Détails...",
                  icon: Icons.description,
                ),
                validator: (v) => v!.isEmpty ? "Description requise" : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Envoyer la réclamation",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primaryColor),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
