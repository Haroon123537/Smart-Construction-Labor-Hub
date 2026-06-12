import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'feedback_responses.dart';
import 'package:smart_constuction_hub/splash_screen.dart';
import 'home_screen.dart';

class RatingAndReviewScreen extends StatefulWidget {
  @override
  _RatingAndReviewScreenState createState() => _RatingAndReviewScreenState();
}

class _RatingAndReviewScreenState extends State<RatingAndReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  String _feedbackType = 'Suggestions';
  String _category = 'Labor Service';

  final List<String> feedbackTypes = ['Suggestions', 'Questions', 'Comments'];
  final List<String> categories = ['Labor Service', 'Material Delivery', 'Estimation', 'House Model Generation', 'Labor Hiring', 'Others'];



  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'Anonymous';
      final timestamp = ServerValue.timestamp; // Realtime DB timestamp

      try {
        // Reference to 'feedback' node
        final ref = FirebaseDatabase.instance.ref('feedback').push();

        await ref.set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'feedbackType': _feedbackType,
          'category': _category,
          'message': _messageController.text,
          'timestamp': timestamp,
          'userId': userId,
        });

        await FeedbackAutoResponseService.sendAutoResponse(
          feedbackId: ref.key!,        // use the pushed feedback key
          userId: userId,              // current user ID
        );



        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Feedback Submitted & Response Sent')),
        );

        // Clear fields
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color(0xFF302F2F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Feedback & Suggestions"),
        backgroundColor: const Color(0xFFFFBC3A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home,
                size: 25,
                color: const Color(0xFF302F2F)
            ),
            tooltip: "Home",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SplashScreen(nextPage: HomePage()),
                  ) );
            },
          ),
          SizedBox(
            width:15
          )
        ],
      ),
      body: Stack(
        children: [
          // 🌈 Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🧊 Glassmorphic Feedback Form
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.90,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            'Rate Our Services',
                            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),

                          _buildInput(_nameController, 'Full Name'),
                          _buildInput(_emailController, 'Email', isEmail: true),
                          _buildInput(_phoneController, 'Phone (+92)', isPhone: true),

                          _buildDropdown("Feedback Type", feedbackTypes, _feedbackType, (val) {
                            setState(() => _feedbackType = val!);
                          }),

                          _buildDropdown("Category", categories, _category, (val) {
                            setState(() => _category = val!);
                          }),

                          _buildInput(_messageController, 'Your Message', maxLines: 4),

                          SizedBox(height: 20),

                          // 🔘 Submit button
                          ElevatedButton(
                            onPressed: _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {bool isEmail = false, bool isPhone = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isEmail && !value.contains('@')) return 'Enter a valid email';
          if (isPhone && value.length < 11) return 'Enter valid phone with +92';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dropdownColor: Colors.black87,
        style: TextStyle(color: Colors.white),
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<String>>((val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val),
          );
        }).toList(),
      ),
    );
  }
}
