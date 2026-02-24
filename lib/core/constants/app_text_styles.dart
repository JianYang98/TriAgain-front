import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1 = GoogleFonts.notoSansKr(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle heading2 = GoogleFonts.notoSansKr(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle heading3 = GoogleFonts.notoSansKr(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle body1 = GoogleFonts.notoSansKr(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle body2 = GoogleFonts.notoSansKr(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle caption = GoogleFonts.notoSansKr(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle sub = GoogleFonts.notoSansKr(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle button = GoogleFonts.notoSansKr(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
