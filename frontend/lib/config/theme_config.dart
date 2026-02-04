import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/styles/app_colors.dart';

class ThemeConfig {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme(),
    primaryColor: AppColors.primary,
    useMaterial3: true,
  );
}
