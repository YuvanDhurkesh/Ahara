import 'package:flutter/material.dart';

class VolunteerNotificationsPage extends StatelessWidget {
  const VolunteerNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EF),
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationTile(text: 'New delivery request available'),
          _NotificationTile(text: 'Delivery completed successfully'),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String text;
  const _NotificationTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text),
    );
  }
}
