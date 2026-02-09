import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_register_page.dart';
import 'login_page.dart';
import '../../../../core/utils/responsive_layout.dart';

class RegisterSelectionPage extends StatelessWidget {
  const RegisterSelectionPage({super.key});

  void navigateWithRole(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "How would you like\nto join us?",
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 40,
                    height: 1.1,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Select your role to get started with the community and help reduce food waste.",
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      _buildBuyerCard(context),
                      const SizedBox(height: 20),
                      _buildSellerCard(context),
                      const SizedBox(height: 20),
                      _buildVolunteerCard(context),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBuyerCard(context)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildSellerCard(context)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildVolunteerCard(context)),
                    ],
                  ),
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
                          MaterialPageRoute(builder: (_) => const LoginPage()),
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
        ),
      ),
    );
  }

  Widget _buildBuyerCard(BuildContext context) {
    return _SelectionCard(
      title: "Register as Buyer",
      description: "Find and purchase surplus meals near you at great prices.",
      icon: Icons.shopping_basket_outlined,
      onTap: () {
        navigateWithRole(context, const BuyerRegisterPage(role: "buyer"));
      },
    );
  }

  Widget _buildSellerCard(BuildContext context) {
    return _SelectionCard(
      title: "Register as Seller",
      description: "List your surplus food and help reduce local waste.",
      icon: Icons.storefront_outlined,
      onTap: () {
        navigateWithRole(context, const BuyerRegisterPage(role: "seller"));
      },
    );
  }

  Widget _buildVolunteerCard(BuildContext context) {
    return _SelectionCard(
      title: "Register as Volunteer",
      description: "Lend a hand in distributing food to those who need it.",
      icon: Icons.volunteer_activism_outlined,
      onTap: () {
        navigateWithRole(context, const BuyerRegisterPage(role: "volunteer"));
      },
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
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
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight.withOpacity(0.5),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight.withOpacity(0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
