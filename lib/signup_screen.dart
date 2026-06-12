import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account Created')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.deepPurple.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/logo.jpg', height: 100),
                        SizedBox(height: 20),
                        Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 10),
                        _buildInputField('Name'),
                        SizedBox(height: 10),
                        _buildInputField('Email', controller: emailController),
                        SizedBox(height: 10),
                        _buildInputField('Password', isPassword: true, controller: passwordController),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text('Sign Up', style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Already have an account? Log in', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, {bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: isPassword ? Icon(Icons.lock, color: Colors.white54) : Icon(Icons.person, color: Colors.white54),
      ),
    );
  }
}
