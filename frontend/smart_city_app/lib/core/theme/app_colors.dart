import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color navy = Color(0xFF1E3A8A);

  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color cyan = Color(0xFF06B6D4);

  static const Color background = Color(0xFFEFF6FF);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color lightSky = Color(0xFFF0F9FF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color text = Color(0xFF172554);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFDCEAF7);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, skyBlue],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, skyBlue],
  );
}
