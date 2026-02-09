import 'package:flutter/material.dart';

class AvailabilityToggle extends StatelessWidget {
  const AvailabilityToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Available for deliveries'),
      value: true,
      onChanged: (_) {},
      activeColor: const Color(0xFFD08A5D),
    );
  }
}
