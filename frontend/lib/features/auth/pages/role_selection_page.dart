import 'package:flutter/material.dart';
import 'buyer_register_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _go(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerRegisterPage(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Role"),
      ),

      body: ListView(
        children: [

          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text("Buyer"),
            onTap: () => _go(context, "buyer"),
          ),

          ListTile(
            leading: const Icon(Icons.store),
            title: const Text("Seller"),
            onTap: () => _go(context, "seller"),
          ),

          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text("Volunteer"),
            onTap: () => _go(context, "volunteer"),
          ),
        ],
      ),
    );
  }
}
