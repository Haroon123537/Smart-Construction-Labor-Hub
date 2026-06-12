import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';


class HireRequestPage extends StatefulWidget {
  final String userCity;
  final String userEmail;

  const HireRequestPage({super.key, required this.userCity, required this.userEmail});

  @override
  _HireRequestPageState createState() => _HireRequestPageState();
}

class _HireRequestPageState extends State<HireRequestPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _isLoading = false;

  Future<void> createHireRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String requestId =
          _dbRef.child('hiring_requests').push().key ?? '';

      final Map<String, dynamic> requestData = {
        'city': widget.userCity,          // ✅ user's city
        'laborName': 'John Doe',          // labor name (can be dynamic)
        'skill': 'Electrician',           // labor skill
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
        'userEmail': widget.userEmail,    // ✅ user's email
      };

      await _dbRef.child('hiring_requests/$requestId').set(requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Hire request created!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hire Request Demo'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: _isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Icon(Icons.person_add),
          label: Text('Hire Labor'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _isLoading ? null : createHireRequest,
        ),
      ),
    );
  }
}
