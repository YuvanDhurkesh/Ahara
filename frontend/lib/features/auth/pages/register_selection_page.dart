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
                  "Choose your path\nwith Ahara",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.1,
                    fontSize: 32,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Join our community and help transform local surplus into meaningful impact.",
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      _buildSellerCard(context),
                      const SizedBox(height: 20),
                      _buildVolunteerCard(context),
                      const SizedBox(height: 20),
                      _buildBuyerCard(context),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSellerCard(context)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildVolunteerCard(context)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildBuyerCard(context)),
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
      title: "Find a meal",
      description: "Discover surpus meals",
      icon: Icons.restaurant_menu_rounded,
      onTap: () {
        navigateWithRole(context, const BuyerRegisterPage(role: "buyer"));
      },
    );
  }

  Widget _buildSellerCard(BuildContext context) {
    return _SelectionCard(
      title: "Give Food",
      description: "Share your surplus",
      icon: Icons.shopping_basket_rounded,
      onTap: () {
        navigateWithRole(context, const BuyerRegisterPage(role: "seller"));
      },
    );
  }

  Widget _buildVolunteerCard(BuildContext context) {
    return _SelectionCard(
      title: "Volunteer",
      description: "Help distribute",
      icon: Icons.groups_rounded,
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
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
