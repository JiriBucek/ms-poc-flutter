import 'package:flutter/material.dart';

/// The MilkSafe colour palette, ported 1:1 from the iOS `Style.swift`
/// (`UIColor.chXxx`). Names mirror the Swift ones for easy cross-reference.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color msOffWhite = Color(0xFFEEEEEE);
  static const Color white = Color(0xFFFFFFFF);

  /// Primary text / dark navy.
  static const Color dark = Color(0xFF001235);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color darkGrey = Color(0xFF999999);
  static const Color textGrey = Color(0xFF737373);
  static const Color subtitleGrey = Color(0xFF595959);

  static const Color primary = Color(0xFF0090F2);
  static const Color primaryDark = Color(0xFF0085F2);

  static const Color confirm = Color(0xFF229963);
  static const Color confirmLight = Color(0xFFD3EBE0);
  static const Color warning = Color(0xFFF0485E);
  static const Color darkBackground = Color(0xFF253772);

  /// Negative test result = safe = green.
  static const Color negative = Color(0xFF229B63);

  /// Positive test result = antibiotics detected = red.
  static const Color positive = Color(0xFFE00125);

  static const Color backgroundPink = Color(0xFFFBD1D7);
  static const Color backgroundGreen = Color(0xFFE5F3EC);
}
