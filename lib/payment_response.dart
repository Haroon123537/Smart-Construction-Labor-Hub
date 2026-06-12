import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PaymentResponseSetupApp extends StatelessWidget {
  const PaymentResponseSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Response Setup',
      debugShowCheckedModeBanner: false,
      home: const PaymentResponseSetup(),
    );
  }
}

class PaymentResponseSetup extends StatefulWidget {
  const PaymentResponseSetup({super.key});

  @override
  State<PaymentResponseSetup> createState() => _PaymentResponseSetupState();
}

class _PaymentResponseSetupState extends State<PaymentResponseSetup> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _loading = false;
  // <-- use the 'success' parameter


  Future<void> createDemoResponse({bool success = true}) async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final paymentId = 'demo_payment_001';

      String message;
      if (success) {
        message =
        "🎉 Hooray! Your payment has been successfully received.\n\n"
            "💳 Amount: PKR 0 (demo)\n"
            "🗓 Date: ${DateTime.now()}\n"
            "Thank you for trusting our service! We’re processing your order and will update you shortly. ✅";
      } else {
        message =
        "⚠️ Oops! Your payment could not be processed.\n\n"
            "Please check your card details, ensure sufficient balance, or try again later.\n"
            "If the problem persists, contact our support team. 💬";
      }





      final ref = FirebaseDatabase.instance.ref('payment_responses').push();
      await ref.set({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'paymentId': paymentId,
        'status': success ? 'success' : 'failed', // <-- fixed here
        'reason': message,
        'timestamp': ServerValue.timestamp,
        'read': false,
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment response created!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Response Setup')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => createDemoResponse(success: true),
              child: const Text('Create Success Response'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => createDemoResponse(success: false),
              child: const Text('Create Failed Response'),
            ),
          ],
        ),
      ),
    );
  }
}
