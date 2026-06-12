import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationsPage({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepPurple,
        elevation: 6,
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final note = notifications[index];
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
              note['timestamp'] ?? 0);

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              title: Text(
                note['title'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    note['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2,'0')}",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: note['is_read'] == true
                  ? null
                  : Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () async {
                // mark as read
                await FirebaseDatabase.instance
                    .ref('notifications/${note['id']}')
                    .update({'is_read': true});
                // optionally show details or close page
              },
            ),
          );
        },
      ),
    );
  }
}
