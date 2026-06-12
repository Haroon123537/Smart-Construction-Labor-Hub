import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationExample extends StatefulWidget {
  @override
  _NotificationExampleState createState() => _NotificationExampleState();
}

class _NotificationExampleState extends State<NotificationExample> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? link,
  }) async {
    final String notificationId = _dbRef.child('notifications').push().key!;
    final Map<String, dynamic> notificationData = {
      'id': notificationId,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'link': link ?? '',
      'is_read': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _dbRef.child('notifications/$notificationId').set(notificationData);
    print('✔ Notification sent: $title');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Example")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            sendNotification(
              userId: 'user_123',
              type: 'feedback',
              title: 'Feedback Received',
              message: 'Your feedback has been sent to the admin.',
            );
          },
          child: Text("Send Notification"),
        ),
      ),
    );
  }
}