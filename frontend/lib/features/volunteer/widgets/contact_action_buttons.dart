import 'package:flutter/material.dart';

class ContactActionButtons extends StatelessWidget {
  const ContactActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Call'),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.message),
              label: const Text('Text'),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
