import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


class CardPaymentHelper {
  // Formatter for card input with space every 4 digits
  static String formatCardNumber(String input) {
    input = input.replaceAll(RegExp(r'\D'), ''); // remove non-digits
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      if ((i + 1) % 4 == 0 && i + 1 != input.length) buffer.write(' ');
    }
    return buffer.toString();
  }

  // Validator for card number
  static String? validateCardNumber(String? value) {
    if (value == null) return 'Enter card number';
    String cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 16) return 'Card must be 16 digits';
    if (!_luhnCheck(cleaned)) return 'Invalid card number';
    return null;
  }

  // Luhn algorithm to check card validity
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // Validator for expiry date
  static String? validateExpiryDate(String? value) {
    if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Enter valid MM/YY';
    }
    final parts = value.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    final currentYear = int.parse(DateFormat('yy').format(now));
    final currentMonth = now.month;
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card expired';
    }
    return null;
  }

  // Validator for CVV
  static String? validateCVV(String? value) {
    if (value == null || value.length != 3 || !RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'Enter 3-digit CVV';
    }
    return null;
  }

  // Input formatter for TextField (optional)
  static TextInputFormatter cardInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String formatted = formatCardNumber(newValue.text);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }
}
