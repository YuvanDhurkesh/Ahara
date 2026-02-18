/// File: simplified_seller_home.dart
/// Purpose: Accessibility-focused interface for the seller dashboard.
/// 
/// Responsibilities:
/// - Provides a high-contrast, large-format UI for core redistribution tasks
/// - Simplifies navigation for users with visual or cognitive impairments
/// - Highlights the "Donate Food" primary action as a central focal point
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../pages/create_listing_page.dart';
import '../../../core/localization/app_localizations.dart';

/// Streamlined view for food donors prioritizing ease of use and high visibility.
/// 
/// Features:
/// - Giant interactive primary action targets
/// - Minimalist aesthetic with oversized iconography
/// - Core navigational shortcuts to profile and inventory
class SimplifiedSellerHome extends StatelessWidget {
  const SimplifiedSellerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.translate("seller_dashboard"),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 60),
              
              // GIANT DONATE BUTTON
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateListingPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "DONATE FOOD",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // SECONDARY ACTIONS (Large Icons)
              Row(
                children: [
                  _buildLargeAction(
                    context,
                    icon: Icons.list_alt_rounded,
                    label: "MY LISTS",
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 20),
                  _buildLargeAction(
                    context,
                    icon: Icons.person_rounded,
                    label: "PROFILE",
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeAction(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
