import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;

  ChatScreen({super.key, required this.chatId});

  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ IMPORTANT
      appBar: AppBar(
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          // ======================
          // Messages List
          // ======================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No messages yet"),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    final text = msg['text']?.toString() ?? '';
                    final senderId = msg['sender_id']?.toString();
                    final isMe = senderId == currentUser;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ======================
          // Message Input Field (FIXED)
          // ======================
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: () async {
                      final text = messageController.text.trim();
                      if (text.isEmpty) return;

                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .add({
                        'text': text,
                        'sender_id': currentUser,
                        'created_at': FieldValue.serverTimestamp(),
                      });

                      messageController.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
