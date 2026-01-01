import 'package:flutter/material.dart';
// import 'package:rentixa/models/ads.dart';
import 'package:rentixa/models/feedback.dart';
import 'package:rentixa/screens/feedback/add_edit_feedback_page.dart';
import '../services/feedback_service.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;
  final int currentUserId;
  final VoidCallback onRefresh;
  final List<Ads> adsList;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.currentUserId,
    required this.onRefresh,
    required this.adsList,
  });

  bool get isOwner => feedback.userId == currentUserId && currentUserId != 0;
  bool get isAnonymous => currentUserId == 0;

  @override
  Widget build(BuildContext context) {
    // Find annonce title
    final annonceTitle = adsList
        .firstWhere(
          (ad) => ad.id == feedback.annonceId,
          orElse: () => Ads(id: 0, title: "Unknown", price: 0, state: '', type: '', phone: 0),
        )
        .title;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              feedback.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 4),

            // Comment
            if (feedback.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(feedback.comment),
              ),

            const SizedBox(height: 4),

            // Rating
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < feedback.rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 20,
                );
              }),
            ),

            const SizedBox(height: 8),

            // Likes / Dislikes
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.green),
                  onPressed: () async {
                    await FeedbackService.updateReaction(feedback.id, true);
                    onRefresh();
                  },
                ),
                Text('${feedback.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.thumb_down, color: Colors.red),
                  onPressed: () async {
                    await FeedbackService.updateReaction(feedback.id, false);
                    onRefresh();
                  },
                ),
                Text('${feedback.dislikes}'),
              ],
            ),

            const SizedBox(height: 8),

            // Other info
            Text('Annonce: $annonceTitle'),
            Text('User: ${feedback.firstName} ${feedback.lastName}'),
            Text('Created at: ${feedback.createdAt.toLocal()}'),

            const SizedBox(height: 8),

            // Owner actions
            if (isOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditFeedbackPage(
                            adsList: adsList,
                            feedbackToEdit: feedback,
                          ),
                        ),
                      );
                      if (result == true) onRefresh();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await FeedbackService.deleteFeedback(feedback.id);
                      onRefresh();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
