import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'payment_response.dart';
import 'feedback_responses.dart';
import 'labors.dart';
import 'Help page.dart';
import '3d_viewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'email_respond.dart';
import 'hiring_rqeuests.dart';
import 'creating_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String feedbackId = 'test_feedback_001';

  try {
    // Only initialize Firebase if no app exists
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDRXbBjjTIybo2ot2LPGKNH4l2FB8n84pM",
          authDomain: "smart-construction-hub.firebaseapp.com",
          projectId: "smart-construction-hub",
          storageBucket: "smart-construction-hub.firebasestorage.app",
          messagingSenderId: "867251034015",
          appId: "1:867251034015:web:de9700adb6b09062d00faa",
          measurementId: "G-QF4MKP41L8",
          databaseURL: "https://smart-construction-hub-default-rtdb.firebaseio.com",
        ),
      );
    }
  } catch (e) {
    // If Firebase is already initialized, just print the error and continue
    print("Firebase already initialized: $e");
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Force LTR globally
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Construction & Labor Hub',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF1E1E2C),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: AuthGate()
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        // Still waiting for Firebase → show splash/loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in → HomePage
        if (snapshot.hasData) {
          return HomePage();
        }

        // If not logged in → LoginPage
        return LoginPage();
      },
    );
  }
}