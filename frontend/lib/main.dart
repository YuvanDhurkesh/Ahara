import 'package:flutter/material.dart';
import 'config/theme_config.dart';
import 'features/common/pages/landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahara',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      home: const LandingPage(),
    );
  }
}
