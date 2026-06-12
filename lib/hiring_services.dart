import 'package:firebase_database/firebase_database.dart';

class HiringService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> checkAndProcessHiringRequest({
    required String requestId,
    required String laborId,
    required String skill,
    required String userId,
  }) async {
    // 1️⃣ Read labor data
    final laborSnap = await _db.ref("Labors/$laborId").get();
    if (!laborSnap.exists) return;

    final labor = Map<String, dynamic>.from(laborSnap.value as Map);

    final bool isAvailable = labor['Availability'] == true;
    final String laborSkill = labor['Skills'];

    String status;
    String message;

    // 2️⃣ Availability + skill check
    if (isAvailable && laborSkill == skill) {
      status = "Accepted";
      message = "Labor is available. You can contact them now.";

      // Mark labor unavailable
      await _db.ref("Labors/$laborId").update({
        "Availability": false,
      });
    } else {
      status = "Rejected";
      message = "Sorry, labor is not available.";
    }

    // 3️⃣ Update hiring request status
    await _db.ref("hiring_requests/$requestId").update({
      "status": status,
    });

    // 4️⃣ Save notification for bell icon
    // 🔹 USE THE SAME PUSH KEY AS HIRING REQUEST
    final notificationKey = requestId.isNotEmpty ? requestId : _db.ref().push().key;

    await _db.ref("user_notifications/$userId/$notificationKey").set({
      "requestId": notificationKey,    // must match child key
      "status": status,                // Accepted or Rejected
      "message": message,
      "createdAt": ServerValue.timestamp,
      "read": false,                   // must include
      "userId": userId,                // must include
    });
  }
}
