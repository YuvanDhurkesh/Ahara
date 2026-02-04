import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: const [

            /// HERO
            HeroSection(),

            /// HOW IT WORKS
            HowItWorks(),

            /// TRUST
            TrustSection(),

            /// IMPACT
            ImpactSection(),

            SizedBox(height: 40),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 60,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          Text(
            "Redistributing Surplus Food,\nReducing Waste",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Join our community-driven platform to bridge the gap between food waste and food insecurity.",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          Column(
            children: [
              HeroButton(
                text: "Register as Seller",
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),

              HeroButton(
                text: "Find Food",
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),

              HeroButton(
                text: "Become a Volunteer",
                color: AppColors.primary,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class HeroButton extends StatelessWidget {
  final String text;
  final Color color;

  const HeroButton({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {},
        child: Text(text),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          SectionTitle("How It Works"),
          SizedBox(height: 20),

          FeatureCard(
            title: "Sellers",
            description:
                "Restaurants and hotels list surplus food with safety info.",
          ),
          FeatureCard(
            title: "Volunteers",
            description:
                "Verified locals pick up food and deliver safely.",
          ),
          FeatureCard(
            title: "Buyers / NGOs",
            description:
                "Browse listings and receive fresh food.",
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          SectionTitle("Why Trust Us"),
          SizedBox(height: 20),

          FeatureCard(
            title: "Food Safety 🛡️",
            description:
                "Strict certification checks and hygiene declarations.",
          ),
          FeatureCard(
            title: "Verified Volunteers 🤝",
            description:
                "Background checks and training ensured.",
          ),
          FeatureCard(
            title: "Ratings System ⭐",
            description:
                "Transparent feedback ensures accountability.",
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
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: const Column(
        children: [
          Text(
            "Our Impact",
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 30),

          ImpactItem("5,000+", "Meals Saved"),
          ImpactItem("1.2 Tons", "Waste Reduced"),
          ImpactItem("150+", "Verified Partners"),
        ],
      ),
    );
  }
}

class ImpactItem extends StatelessWidget {
  final String number;
  final String label;

  const ImpactItem(this.number, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
