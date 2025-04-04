import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = "Tawtheeq ";
  static const String appNameStyled = "Tawtheeq";

  // Colors
  static const Color primaryColor = Color(0xFF2C8572);
  static const Color secondaryColor = Color(0xFF64B49E);
  static const Color backgroundColor = Color(0xFFF5F9F8);
  static const Color errorColor = Color(0xFFD32F2F);

  // Text Styles
  static const TextStyle appNameStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 1.2,
  );

  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );

  // Input Decoration - Updated for RTL support
  static InputDecoration textFieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      // Replace prefixIcon with suffixIcon for RTL layout
      suffixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: true,
      hintTextDirection: TextDirection.rtl,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: const TextStyle(color: errorColor),
    );
  }
}
