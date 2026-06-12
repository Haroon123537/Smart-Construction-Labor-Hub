import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';
import 'home_screen.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // ✅ added key constructor

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

 // final GoogleSignIn _googleSignIn = GoogleSignIn(
   // scopes: ['email', 'profile'],
  //);


  bool _obscureText = true;
  bool loading = false;
  get auth => null;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
      _goToHome();
    } catch (e) {
      _showError("Error: $e");
    }
  }

  // 🔹 Google Sign-In
  Future<void> loginWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });

      // 🔹 Use GoogleSignIn() directly (Web compatible)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: "25851239454-b7ar87nlpqo3bgss2r4fn2pm6u0174mg.apps.googleusercontent.com",
        scopes: ['email', 'profile'],
      );

      // 🔹 Start sign-in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          loading = false;
        });
        return; // user canceled
      }

      // 🔹 Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 🔹 Create Firebase credential (Web only needs idToken)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 🔹 Sign in with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 🔹 Navigate to HomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }



  void resetPassword(BuildContext context) async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter your email"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: emailController.text.trim());
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset link sent!')));
                } catch (e) {
                  _showError("Error: $e");
                }
              },
              child: const Text('Send'),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  void _goToHome() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Login Successful')));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(nextPage: HomePage()),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.indigo.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15), // ✅ fixed
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)), // ✅ fixed
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/logo.jpg', height: 100),
                        const SizedBox(height: 20),
                        const Text('Welcome Back!',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 10),
                        _buildInputField('Email',
                            controller: email, isPassword: false),
                        const SizedBox(height: 10),
                        _buildInputField('Password',
                            isPassword: true, controller: password),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.white.withValues(alpha: 0.2), // ✅ fixed
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('Login',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 15),

                        // 🔹 Google Sign-In button
                        ElevatedButton.icon(
                          onPressed: loginWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 28,
                            width: 28,
                            fit: BoxFit.contain,
                          ), // ✅ adjusted size
                          label: const Text('Sign in with Google',
                              style: TextStyle(color: Colors.black87)),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () => resetPassword(context),
                                child: const Text('Forgot Password?',
                                    style: TextStyle(color: Colors.white))),
                            TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => SignupPage())),
                                child: const Text('Signup',
                                    style: TextStyle(color: Colors.white))),
                          ],
                        ),
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

  Widget _buildInputField(String label,
      {bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      style: const TextStyle(color: Colors.white),
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      autofillHints:
      isPassword ? [AutofillHints.password] : [AutofillHints.email],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1), // ✅ fixed
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility),
          color: Colors.white54,
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : const Icon(Icons.email, color: Colors.white54),
      ),
    );
  }
}
