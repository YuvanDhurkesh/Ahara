import 'package:flutter/material.dart';

class VerificationForm extends StatelessWidget {
  const VerificationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Upload ID Document'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          items: const [
            DropdownMenuItem(value: 'bike', child: Text('Bike')),
            DropdownMenuItem(value: 'cycle', child: Text('Bicycle')),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(labelText: 'Transport Type'),
        ),
      ],
    );
  }
}
