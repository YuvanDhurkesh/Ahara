import 'package:flutter/material.dart';

class DeliveryCard extends StatelessWidget {
  final String status;
  const DeliveryCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sunshine Delights',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(status, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
