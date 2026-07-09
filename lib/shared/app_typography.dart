import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers — ใช้ Prompt ให้ตรงกับ theme หลักของแอป
class AppTypography {
  AppTypography._();

  static TextStyle prompt({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.prompt(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    return prompt(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: color ?? const Color(0xFF0262EC),
    );
  }

  static TextStyle field(BuildContext context) {
    return prompt(fontSize: 14, color: const Color(0xFF1A2340));
  }

  static TextStyle hint() {
    return prompt(fontSize: 14, color: const Color(0xFF9E9E9E));
  }

  static TextStyle button({Color color = Colors.white, double fontSize = 16}) {
    return prompt(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle error({double fontSize = 11}) {
    return prompt(fontSize: fontSize, color: const Color(0xFFD32F2F));
  }
}
