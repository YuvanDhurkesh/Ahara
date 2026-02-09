import 'package:flutter/material.dart';

class RatingStarWidget extends StatelessWidget {
  final double rating;
  const RatingStarWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$rating ★',
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  }
}
