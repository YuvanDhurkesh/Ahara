import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../auth/pages/register_selection_page.dart';
import '../../auth/pages/login_page.dart';
import '../../../../core/utils/responsive_layout.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _trustKey = GlobalKey();
  final GlobalKey _impactKey = GlobalKey();

  String _activeSection = "";

  void _scrollToSection(GlobalKey key, String sectionName) {
    setState(() {
      _activeSection = sectionName;
    });

    // Slight delay to allow the drawer to close fully before scrolling starts
    Future.delayed(const Duration(milliseconds: 300), () {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.0, // Ensures the section moves to the TOP of the screen
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key:
          GlobalKey<
            ScaffoldState
          >(), // Helpful for programmatic access if needed
      backgroundColor: AppColors.background,
      endDrawer: isMobile ? _buildMobileDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Ahara",
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
          ],
        ),
        actions: [
          if (!isMobile) ...[
            _NavBarItem(
              "How it works",
              isActive: _activeSection == "howitworks",
              onTap: () => _scrollToSection(_howItWorksKey, "howitworks"),
            ),
            _NavBarItem(
              "Trust",
              isActive: _activeSection == "trust",
              onTap: () => _scrollToSection(_trustKey, "trust"),
            ),
            _NavBarItem(
              "Impact",
              isActive: _activeSection == "impact",
              onTap: () => _scrollToSection(_impactKey, "impact"),
            ),
          ],
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showAuthOptions(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: 0,
              ),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              "Join Us",
              style: TextStyle(fontSize: isMobile ? 12 : 13),
            ),
          ),
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          SizedBox(width: isMobile ? 8 : 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HERO
            const HeroSection(),

            /// HOW IT WORKS
            HowItWorks(key: _howItWorksKey),

            /// TRUST
            TrustSection(key: _trustKey),

            /// IMPACT
            ImpactSection(key: _impactKey),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Menu",
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            _buildDrawerItem("How it works", () {
              Navigator.pop(context);
              _scrollToSection(_howItWorksKey, "howitworks");
            }),
            _buildDrawerItem("Trust", () {
              Navigator.pop(context);
              _scrollToSection(_trustKey, "trust");
            }),
            _buildDrawerItem("Impact", () {
              Navigator.pop(context);
              _scrollToSection(_impactKey, "impact");
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Ahara v1.0",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.primary,
      ),
      onTap: onTap,
    );
  }

  void _showAuthOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Join the Ahara Community",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to your account or register to start sharing.",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text("Login to Ahara"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterSelectionPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text("Create New Account"),
                ),
              ),
              const SizedBox(height: 16),
              const SafeArea(top: false, child: SizedBox(height: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HERO SECTION
////////////////////////////////////////////////////////////

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeroText(context, isMobile),
                    const SizedBox(height: 48),
                    _buildHeroImage(context, isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: _buildHeroText(context, isMobile)),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: _buildHeroImage(context, isMobile),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "COMMUNITY-DRIVEN FOOD SHARING",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Small Acts,\nBig Plates.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: isMobile ? 44 : 64,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Join a community of food donors and volunteers turning local surplus into neighborhood meals with care and transparency.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: 17,
            color: AppColors.textLight.withOpacity(0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context, bool isMobile) {
    return Container(
      height: isMobile ? 240 : 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1000&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.textDark.withOpacity(0.2)],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HOW IT WORKS
////////////////////////////////////////////////////////////

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const SectionTitle("How It Works"),
          const SizedBox(height: 40),
          ResponsiveLayout(
            mobile: Column(
              children: const [
                FeatureCard(
                  title: "Give Food",
                  icon: Icons.shopping_basket_outlined,
                ),
                SizedBox(height: 16),
                FeatureCard(title: "Volunteer", icon: Icons.people_outline),
                SizedBox(height: 16),
                FeatureCard(
                  title: "Find a meal",
                  icon: Icons.restaurant_outlined,
                ),
              ],
            ),
            desktop: Row(
              children: const [
                Expanded(
                  child: FeatureCard(
                    title: "Give Food",
                    icon: Icons.shopping_basket_outlined,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    title: "Volunteer",
                    icon: Icons.people_outline,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    title: "Find a meal",
                    icon: Icons.restaurant_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// TRUST SECTION
////////////////////////////////////////////////////////////

class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: const [
          SectionTitle("Why Trust Us"),
          SizedBox(height: 40),
          ResponsiveLayout(
            mobile: Column(
              children: const [
                FeatureCard(title: "Food Safety", icon: Icons.security),
                SizedBox(height: 16),
                FeatureCard(
                  title: "Verified Staff",
                  icon: Icons.verified_user_outlined,
                ),
                SizedBox(height: 16),
                FeatureCard(
                  title: "Transparency",
                  icon: Icons.visibility_outlined,
                ),
              ],
            ),
            desktop: Row(
              children: [
                Expanded(
                  child: FeatureCard(
                    title: "Food Safety",
                    icon: Icons.security,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    title: "Verified Staff",
                    icon: Icons.verified_user_outlined,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    title: "Transparency",
                    icon: Icons.visibility_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// IMPACT SECTION
////////////////////////////////////////////////////////////

class ImpactSection extends StatelessWidget {
  const ImpactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            "Our Global Impact",
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ResponsiveLayout(
              mobile: Column(
                children: const [
                  ImpactCard("5,000+", "Meals Saved", Icons.eco_outlined),
                  SizedBox(height: 16),
                  ImpactCard(
                    "1.2 Tons",
                    "Waste Reduced",
                    Icons.recycling_outlined,
                  ),
                  SizedBox(height: 16),
                  ImpactCard("150+", "Partners", Icons.handshake_outlined),
                ],
              ),
              desktop: Row(
                children: const [
                  Expanded(
                    child: ImpactCard(
                      "5,000+",
                      "Meals Saved",
                      Icons.eco_outlined,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ImpactCard(
                      "1.2 Tons",
                      "Waste Reduced",
                      Icons.recycling_outlined,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ImpactCard(
                      "150+",
                      "Partners",
                      Icons.handshake_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImpactCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const ImpactCard(this.number, this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              number,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// REUSABLE WIDGETS
////////////////////////////////////////////////////////////

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Container(
          height: 3,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const FeatureCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  const _NavBarItem(this.title, {required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textLight.withOpacity(0.7),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
