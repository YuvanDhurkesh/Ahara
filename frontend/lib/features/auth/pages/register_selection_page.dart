import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_register_page.dart';
import 'login_page.dart';
import 'seller_register_page.dart';
import 'volunteer_register_page.dart';



class RegisterSelectionPage extends StatelessWidget {
  const RegisterSelectionPage({super.key});

  void navigateWithRole(
    BuildContext context,
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "How would you like\nto join us?",
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(height: 1.2),
            ),

            const SizedBox(height: 12),

            Text(
              "Select your role to get started with the community and help reduce food waste.",
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 48),

            /// BUYER
            _SelectionCard(
              title: "Register as Buyer",
              description:
                  "Find and purchase surplus meals near you at great prices.",
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                navigateWithRole(
                  context,
                  const BuyerRegisterPage(role: "buyer"),
                );
              },
            ),

            const SizedBox(height: 24),

            /// SELLER
            

_SelectionCard(
  title: "Register as Seller",
  description:
      "List your surplus food and help reduce local waste.",
  icon: Icons.storefront_outlined,
  onTap: () {
    navigateWithRole(
      context,
      BuyerRegisterPage(role: "seller")
    );
  },
),

const SizedBox(height: 24),

_SelectionCard(
  title: "Register as Volunteer",
  description:
      "Lend a hand in distributing food to those who need it.",
  icon: Icons.volunteer_activism_outlined,
  onTap: () {
    navigateWithRole(
      context,
      BuyerRegisterPage(role: "volunteer")

    );
  },
),


            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already registered? ",
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 18),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
