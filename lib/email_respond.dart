import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateEmailResponsePage extends StatefulWidget {
  const CreateEmailResponsePage({super.key});

  @override
  State<CreateEmailResponsePage> createState() => _CreateEmailResponsePageState();
}

class _CreateEmailResponsePageState extends State<CreateEmailResponsePage> {
  bool _loading = false;
  String _status = "";

  Future<void> _createEmailResponse() async {
    setState(() {
      _loading = true;
      _status = "Creating email_responses collection...";
    });

    try {
      final dbRef = FirebaseDatabase.instance.ref();

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Add sample auto-response
      await dbRef.child("email_responses").push().set({
        "user_id": "exampleUserId123",         // replace with real user ID
        "user_email": "user@example.com",      // replace with real user email
        "subject": "Test Inquiry",
        "message": "📧 Your email has been received! We will get back to you soon. 🙏",
        "timestamp": timestamp,
        "status": "unread",
      });

      setState(() {
        _status = "✅ Collection 'email_responses' created successfully!";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Failed to create collection: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(); // Initialize Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Email Responses")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : _createEmailResponse,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Collection"),
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
