import 'package:flutter/material.dart';
import 'package:rentixa/models/create_feedback_model.dart';
import 'package:rentixa/models/feedback.dart';
import 'package:provider/provider.dart';
import '../../services/feedback_service.dart';
import '../../providers/auth_provider.dart';
// import '../../models/ads.dart';

class AddEditFeedbackPage extends StatefulWidget {
  final List<Ads> adsList;
  final FeedbackModel? feedbackToEdit; // null = add, non-null = edit

  const AddEditFeedbackPage({
    super.key,
    required this.adsList,
    this.feedbackToEdit,
  });

  @override
  State<AddEditFeedbackPage> createState() => _AddEditFeedbackPageState();
}

class _AddEditFeedbackPageState extends State<AddEditFeedbackPage> {
  final _formKey = GlobalKey<FormState>();

  Ads? selectedAd;
  int rating = 0;
  final labelCtrl = TextEditingController();
  final commentCtrl = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.feedbackToEdit != null) {
      // 🔹 Pre-fill fields if editing
      labelCtrl.text = widget.feedbackToEdit!.label;
      commentCtrl.text = widget.feedbackToEdit!.comment;
      rating = widget.feedbackToEdit!.rating;

      // Find the Ads object matching the feedback's annonceId
      selectedAd = widget.adsList.firstWhere(
        (ad) => ad.id == widget.feedbackToEdit!.annonceId,
        orElse: () => widget.adsList.first,
      );
    }
  }

  @override
  void dispose() {
    labelCtrl.dispose();
    commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedAd == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userIdString = authProvider.userId ?? "0";
    final userId = int.tryParse(userIdString) ?? 0;

    final feedback = CreateFeedbackModel(
      label: labelCtrl.text,
      rating: rating,
      likes: widget.feedbackToEdit?.likes ?? 0,
      dislikes: widget.feedbackToEdit?.dislikes ?? 0,
      comment: commentCtrl.text,
      userId: userId,
      annonceId: selectedAd!.id ?? 0,
    );

    setState(() => isLoading = true);

    try {
      if (widget.feedbackToEdit == null) {
        // Add new feedback
        await FeedbackService.submitFeedback(feedback);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback envoyé avec succès")),
        );
      } else {
        // Update existing feedback
        await FeedbackService.updateFeedback(
          widget.feedbackToEdit!.id,
          feedback.label,
          feedback.comment,
          feedback.rating,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback mis à jour avec succès")),
        );
      }
      Navigator.pop(context, true); // return true to refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'opération")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.feedbackToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier Avis" : "Donner un avis"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🔹 Ads dropdown
              DropdownButtonFormField<Ads>(
                value: selectedAd,
                hint: const Text("Choisir une annonce"),
                items: widget.adsList
                    .map(
                      (ad) => DropdownMenuItem(
                        value: ad,
                        child: Text(ad.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedAd = value),
                validator: (v) => v == null ? "Annonce requise" : null,
              ),

              const SizedBox(height: 16),

              // 🔹 Label
              TextFormField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: "Titre"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),

              const SizedBox(height: 16),

              // 🔹 Rating stars
              const Text("Note"),
              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () => setState(() => rating = i + 1),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // 🔹 Comment
              TextFormField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: "Commentaire"),
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // 🔹 Submit button
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? "Mettre à jour" : "Envoyer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
