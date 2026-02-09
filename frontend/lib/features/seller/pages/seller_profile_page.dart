import 'package:flutter/material.dart';

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Profile")),
      body: const Center(child: Text("Update your business profile and settings.")),
    );
  }
}
