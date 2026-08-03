import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand / accent
  static const teal = Color(0xFF26C6DA);
  static const navyDark = Color(0xFF1A237E);
  static const navyMid = Color(0xFF283593);

  // Backgrounds
  static const scaffoldBg = Color(0xFFF4F6F8);
  static const cardBg = Colors.white;
  static const inputBg = Colors.white;

  // Text
  static const textPrimary = Color(0xDE000000); // black87
  static const textSecondary = Color(0x8A000000); // black54
  static const textHint = Color(0x80000000); // grey.shade500 approx

  // Destination card gradients
  static const gradientBrown = [Color(0xFF4A3728), Color(0xFF6D4C41)];
  static const gradientBlue = [Color(0xFF1565C0), Color(0xFF42A5F5)];
  static const gradientGreen = [Color(0xFF1B5E20), Color(0xFF388E3C)];

  // Feature card gradients
  static const gradientTransport = [Color(0xFF263238), Color(0xFF37474F)];
  static const gradientAccommodation = [Color(0xFF1B5E20), Color(0xFF2E7D32)];

  // Header gradient
  static const gradientHeader = [navyDark, navyMid];

  // Misc
  static const tagOverlay = Color(0x8A000000); // black54
  static const divider = Color(0xFFE0E0E0); // grey.shade200 approx
  static const shadow = Color(0x14000000); // black ~8%
}
