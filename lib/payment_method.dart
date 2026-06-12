import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'online_purchasing.dart';
import 'payment_verification.dart';
import 'package:flutter/services.dart';


class PaymentMethod extends StatefulWidget {
  const PaymentMethod({super.key});

  @override
  _PaymentMethodState createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;


  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty || value.length != 16 || !RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'Please enter a valid 16-digit card number.';
    }
    return null;
  }

  String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Please enter a valid expiry date (MM/YY).';
    }
    List<String> parts = value.split('/');
    int month = int.tryParse(parts[0]) ?? 0;
    int year = int.tryParse(parts[1]) ?? 0;

    if (month < 1 || month > 12) return 'Enter valid month (01-12)';
    if (year < 25) return 'Card expiry year must be 2025 or later';
    return null;
  }

  String? validateCVV(String? value) {
    if (value == null || value.isEmpty || value.length != 3 || !RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'Please enter a valid 3-digit CVV.';
    }
    return null;
  }

  Future<void> _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // ✅ start loading
      });

      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'Anonymous';
      final timestamp = ServerValue.timestamp;

      try {
        final ref = FirebaseDatabase.instance.ref('payments').push();

        await ref.set({
          'cardHolder': _cardHolderController.text,
          'cardNumber': _cardNumberController.text,
          'expiryDate': _expiryDateController.text,
          'cvv': _cvvController.text,
          'timestamp': timestamp,
          'userId': userId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Payment submitted successfully!')),
        );

        // Clear fields
        _cardHolderController.clear();
        _cardNumberController.clear();
        _expiryDateController.clear();
        _cvvController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnlinePurchasingPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Payment failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // ✅ stop loading
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF1E1E2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("💳 Payment Form",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                          SizedBox(height: 20),
                          _buildField(_cardHolderController, 'Card Holder Name', TextInputType.name),
                          SizedBox(height: 12),
                          _buildField(_cardNumberController, 'Card Number', TextInputType.number,
                              validator: CardPaymentHelper.validateCardNumber,
                              inputFormatters: [CardPaymentHelper.cardInputFormatter()]),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(_expiryDateController, 'MM/YY', TextInputType.datetime,
                                    validator: CardPaymentHelper.validateExpiryDate),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildField(_cvvController, 'CVV', TextInputType.number,
                                    validator: CardPaymentHelper.validateCVV),
                              ),
                            ],
                          ),
                          Text(
                            "All local debit/credit cards are accepted.",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),

                          SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitPayment, // disable while loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 10,
                            ),
                            child: _isLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              "Submit Payment",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                color: Colors.white,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      TextInputType type, {
        String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters, // ← add this line
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      inputFormatters: inputFormatters, // ← use it here
      style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

}
