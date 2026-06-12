import 'package:firebase_database/firebase_database.dart';

class FeedbackAutoResponseService {
  static Future<void> sendAutoResponse({
    required String feedbackId,
    required String userId,
  }) async {
    final DatabaseReference db = FirebaseDatabase.instance.ref();

    final String responseMessage = "🤑 Thank you for contacting us!\n\n"
        "We’ve successfully received your feedback and our team is reviewing it carefully.\n"
        "Your concern is important to us.\n"
        "You’ll receive a detailed confirmation very soon.\n\n"
        "Best regards\n"
        "For more detail or improvement you can email us at: 26116@students.riphah.edu.pk";

    // Save company response to feedback_responses only
    await db.child('feedback_responses/$feedbackId').push().set({
      'userId': userId,
      'responseMessage': responseMessage,
      'responseTimestamp': ServerValue.timestamp,
      'sender': 'company',
    });

    // Update feedback status
    await db.child('feedback/$feedbackId').update({
      'status': 'responded',
    });
  }
}
