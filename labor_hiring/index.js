const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.checkHiringRequest = functions.database
    .ref("hiring_requests/{requestId}")
    .onCreate(async (snapshot, context) => {
      const request = snapshot.val();
      const requestId = context.params.requestId;

      // 1️⃣ Get labor info
      const laborId = request.laborId;
      const laborSnapshot = await admin.database().ref("Labors/" + laborId).get();
      const labor = laborSnapshot.val();
      if (!labor) return;

      // 2️⃣ Check availability & skills
      const isAvailable = labor.Availability === true;
      const skillsMatch = labor.Skills.includes(request.skill);

      let status, message;
      if (isAvailable && skillsMatch) {
        status = "Accepted";
        message = "Labor is available. You can contact them now.";
        await admin.database().ref("Labors/" + laborId).update({ Availability: false });
        console.log("Request Accepted");
      } else {
        status = "Rejected";
        message = "Sorry, labor is not available.";
        console.log("Request Rejected");
      }

      // 3️⃣ Update hiring request status
      await admin.database().ref("hiring_requests/" + requestId).update({ status });

      // 4️⃣ Send notification to user
      const userId = request.userId; // must be sent from Flutter
      if (userId) {
        await admin.database().ref(`user_notifications/${userId}/${requestId}`).set({
          requestId,
          status,
          message,
          createdAt: admin.database.ServerValue.TIMESTAMP
        });
      }
    });
