import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../auth/pages/login_page.dart';
import 'buyer_account_details_page.dart';
import '../../../../core/utils/responsive_layout.dart';
import 'buyer_notifications_page.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'package:provider/provider.dart';

class BuyerProfilePage extends StatelessWidget {
  const BuyerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Hello, Harishree",
                      style: GoogleFonts.lora(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showManageAccountSheet(context),
                      icon: const Icon(Icons.settings_outlined, size: 28),
                      color: AppColors.textDark,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Rewards & Trust Score Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        title: "Rewards",
                        value: "Gold",
                        subtext: "2,450 pts",
                        icon: Icons.star_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        title: "Trust Score",
                        value: "950",
                        subtext: "Top 5% Buyer",
                        icon: Icons.shield_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Recent Activity or other profile content could go here
                Text(
                  "Your Impact",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      _buildImpactStat("Meals Saved", "12", Icons.lunch_dining),
                      _buildImpactStat("CO2 Saved", "4.5 kg", Icons.co2),
                      _buildImpactStat(
                        "Money Saved",
                        "₹1,200",
                        Icons.savings_outlined,
                      ),
                    ],
                  ),
                  desktop: Row(
                    children: [
                      Expanded(
                        child: _buildImpactStat(
                          "Meals Saved",
                          "12",
                          Icons.lunch_dining,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImpactStat(
                          "CO2 Saved",
                          "4.5 kg",
                          Icons.co2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImpactStat(
                          "Money Saved",
                          "₹1,200",
                          Icons.savings_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showManageAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ResponsiveLayout.isDesktop(context) ? 500 : double.infinity,
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Manage account",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildSectionHeader("SETTINGS"),
                    _buildMenuItem(
                      context,
                      Icons.person_outline,
                      "Account details",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.credit_card_outlined,
                      "Payment cards",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.confirmation_number_outlined,
                      "Vouchers",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.card_giftcard,
                      "Special Rewards",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.notifications_outlined,
                      "Notifications",
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("COMMUNITY"),
                    _buildMenuItem(
                      context,
                      Icons.favorite_border,
                      "Invite your friends",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.storefront,
                      "Recommend a store",
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("SUPPORT"),
                    _buildMenuItem(
                      context,
                      Icons.shopping_bag_outlined,
                      "Help with an order",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      "How Ahara works",
                    ),
                    _buildMenuItem(context, Icons.work_outline, "Careers"),

                    const SizedBox(height: 24),
                    _buildSectionHeader("OTHER"),
                    _buildMenuItem(
                      context,
                      Icons.visibility_off_outlined,
                      "Hidden Stores",
                    ),
                    _buildMenuItem(context, Icons.article_outlined, "Blog"),
                    _buildMenuItem(context, Icons.gavel_outlined, "Legal"),

                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton(
                        onPressed: () async {
                          await Provider.of<AppAuthProvider>(context, listen: false).logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Log out",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        if (title == "Account details") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BuyerAccountDetailsPage(),
            ),
          );
        } else if (title == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BuyerNotificationsPage(),
            ),
          );
        }
      },
    );
  }
}
