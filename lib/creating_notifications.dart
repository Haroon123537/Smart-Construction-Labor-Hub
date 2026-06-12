import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateNotificationButton extends StatelessWidget {
  final String userId; // current user's ID
  final String requestId; // hiring request ID

  const CreateNotificationButton({
    super.key,
    required this.userId,
    required this.requestId,
  });

  Future<void> createNotification() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('user_notifications')
          .child(userId)
          .child(requestId);

      await ref.set({
        'requestId': requestId,
        'status': '', // still keep status for Accepted/Rejected internally
        'message': '', // <-- this will be updated by backend JS
        'createdAt': ServerValue.timestamp,
      });

      debugPrint("Realtime DB notification node created successfully!");
    } catch (e) {
      debugPrint("Error creating notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await createNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification node created!")),
        );
      },
      child: const Text("Create Notification"),
    );
  }
}
