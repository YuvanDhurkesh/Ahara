import 'package:flutter/material.dart';

class SellerListingsPage extends StatelessWidget {
  const SellerListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Listings")),
      body: const Center(child: Text("Manage your food listings here.")),
    );
  }
}
