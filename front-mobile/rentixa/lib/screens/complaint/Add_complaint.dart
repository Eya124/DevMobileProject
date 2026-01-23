import 'package:flutter/material.dart';
import 'package:rentixa/models/complaint.dart';
import 'package:rentixa/services/complaint_service.dart';
import 'package:rentixa/services/auth_service.dart'; // Service pour récupérer user connecté

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
  final ComplaintService _service = ComplaintService();

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
      final title = _titleController.text.trim();
      final text = _textController.text.trim();

      // Récupération de l'utilisateur connecté
      //final user = await AuthService.getCurrentUser();
      //if (user == null) throw Exception("Utilisateur non connecté");

      await ComplaintService.create(
          title: title,
          text: text,
          userId: 1,
        );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plainte créée avec succès")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer une plainte"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Titre",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Le titre est requis"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Texte de la plainte",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Le texte est requis"
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.teal,
                        ),
                        onPressed: _submitting ? null : _submitComplaint,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Créer la plainte",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
