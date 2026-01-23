import 'package:flutter/material.dart';
// import 'package:fluttercourse/models/ads.dart';
import 'package:provider/provider.dart';
import '../../models/feedback.dart';
import '../../services/feedback_service.dart';
import '../../widgets/feedback_card.dart';
import '../../providers/auth_provider.dart';
import 'add_edit_feedback_page.dart';

class FeedbackListPage extends StatefulWidget {
  final List<Ads> adsList;

  const FeedbackListPage({super.key,required this.adsList});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  late Future<List<FeedbackModel>> feedbacksFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    feedbacksFuture =
        FeedbackService.getFeedbacks();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userIdString = authProvider.userId ?? "0"; // Default to "0" if null
    final userId = int.tryParse(userIdString) ?? 0; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis'),
        actions: [
          if (userId != 0)
            IconButton(
              icon: const Icon(Icons.add_comment),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditFeedbackPage(
                    adsList: widget.adsList,
                    ),
                  ),
                );
                setState(_load);
              },
            ),
        ],
      ),
      body: FutureBuilder<List<FeedbackModel>>(
        future: feedbacksFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun avis"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (_, i) => FeedbackCard(
              feedback: snapshot.data![i],
              currentUserId: userId,
              onRefresh: () => setState(_load),
              adsList: widget.adsList,
            ),
          );
        },
      ),
    );
  }
}
