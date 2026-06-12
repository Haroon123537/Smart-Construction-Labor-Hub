import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static Future<void> notifyEmailReceived() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('email_responses').push();

    await ref.set({
      'message': 'Your email has been received. We will respond soon. 📧',
      'status': 'unread',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'user_id': user.uid,      // ✅ CUSTOMER UID ONLY
      'user_email': user.email ?? '',
      'subject': '',
    });
  }
}
