import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String label;
  const BadgeWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFD08A5D),
    );
  }
}
