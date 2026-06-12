import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
// 🔹 Chat Screen (unchanged)


// 🔹 Hire Contractor Page with ContractorHome theme
class ContractorHirePage extends StatelessWidget {
  final String userId;

  ContractorHirePage({super.key, required this.userId});

  // 🔹 Theme colors from ContractorHomePage
  static const Color primaryColor = Color(0xFF0E0E1F);
  static const Color accentColor = Color(0xFF2A2D3E);
  static const Color highlightColor = Color(0xFFF4B400);

  final TextEditingController messageCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Hire Contractor"),
        centerTitle: true,
        backgroundColor: accentColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // =======================
            // Available Contractors
            // =======================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Available Contractors",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contractors')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                        color: highlightColor,
                      ));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No contractors available",
                          style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final services = (data['services'] as List<dynamic>?)
                        ?.map((s) {
                      if (s is String) return s;
                      if (s is Map<String, dynamic>) return s['name'] ?? '';
                      return '';
                    }).where((s) => s.isNotEmpty).toList() ?? [];

                    final labors = (data['labors'] as List<dynamic>?)
                        ?.map((l) => l is Map<String, dynamic> ? l : {})
                        .cast<Map<String, dynamic>>()
                        .toList() ?? [];

                    final projects = (data['successful_projects'] as List<
                        dynamic>?)
                        ?.map((p) =>
                    p is String
                        ? p
                        : (p is Map<String, dynamic> ? p['title'] ?? '' : ''))
                        .where((p) => p.isNotEmpty)
                        .toList() ?? [];

                    return Card(
                      color: accentColor,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contractor Name & Experience
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? "No Name",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Experience: ${data['experience_years'] ??
                                            'N/A'} yrs",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: highlightColor),
                                  child: const Text("Hire"),
                                  onPressed: () =>
                                      _showHireDialog(context, doc.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Services
                            if (services.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Services:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: services
                                        .map((s) =>
                                        Chip(
                                          backgroundColor: highlightColor
                                              .withOpacity(0.2),
                                          label: Text(
                                            s,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),

                            // Labor Details
                            if (labors.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Available Laborers:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  ...labors.map((l) {
                                    final name = l['name'] ?? '';
                                    final skill = l['skill'] ?? '';
                                    final exp = l['experience'] ?? '';
                                    return Text(
                                      "• $name – $skill ($exp)",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70),
                                    );
                                  }),
                                  const SizedBox(height: 6),
                                ],
                              ),

                            // Successful Projects
                            if (projects.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Successful Projects:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  ...projects.map((p) =>
                                      Text(
                                        "• $p",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70),
                                      )),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const Divider(
              height: 30,
              thickness: 2,
              color: Colors.white24,
            ),

            // =======================
            // =======================
                     // User Requests
                       // =======================
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "My Requests",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              // 🔹 Firebase query for hire requests of current user
              stream: FirebaseFirestore.instance
                  .collection('hire_requests')
                  .where('user_id', isEqualTo: userId) // only current user's requests
                  .orderBy('created_at', descending: true) // latest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: highlightColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No hire requests yet",
                          style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      color: accentColor,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(
                          "Contractor ID: ${data['contractor_id']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              "Message: ${data['message']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Status: ${data['status']}",
                              style: TextStyle(
                                color: data['status'] == 'accepted'
                                    ? Colors.green
                                    : data['status'] == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: _buildAction(context, doc),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  // =======================
  // Show Hire Dialog
  // =======================
  void _showHireDialog(BuildContext context, String contractorId) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: accentColor,
            title: const Text(
                "Send Hire Request", style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: messageCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Describe your work / duration / budget",
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: highlightColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: highlightColor),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                    "Cancel", style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  messageCtrl.clear();
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: highlightColor),
                child: const Text("Send"),
                onPressed: () async {
                  final text = messageCtrl.text.trim();
                  if (text.isEmpty) return;

                  final existing = await FirebaseFirestore.instance
                      .collection('hire_requests')
                      .where('user_id', isEqualTo: userId)
                      .where('contractor_id', isEqualTo: contractorId)
                      .where('status', isEqualTo: 'pending')
                      .get();

                  if (existing.docs.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You already have a pending request"),
                      ),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('hire_requests')
                      .add({
                    'user_id': userId,
                    'contractor_id': contractorId,
                    'message': text,
                    'status': 'pending',
                    'chat_id': null,
                    'created_at': FieldValue.serverTimestamp(),
                  });

                  messageCtrl.clear();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hire request sent successfully"),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  // =======================
  // Decide action for request
  // =======================
  Widget _buildAction(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    if (data['status'] == 'pending') {
      return const Text(
        "Pending ⏳",
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      );
    }

    if (data['status'] == 'rejected') {
      return const Text(
        "Rejected ❌",
        style: TextStyle(color: Colors.red),
      );
    }

    if (data['status'] == 'accepted') {
      final chatId = data['chat_id'];
      if (chatId == null) {
        return const SizedBox.shrink(); // Chat not created yet
      }
      return ElevatedButton(
        child: const Text("Chat"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(chatId: data['chat_id'].toString()),


            ),
          );
        },

      );

    }

    return const SizedBox.shrink();
  }


}