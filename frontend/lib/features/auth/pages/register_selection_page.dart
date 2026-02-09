class RegisterSelectionPage extends StatelessWidget {
  const RegisterSelectionPage({super.key});

  void navigateWithRole(BuildContext context, Widget page) {
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

            _buildBuyerCard(context),
            const SizedBox(height: 24),
            _buildSellerCard(context),
            const SizedBox(height: 24),
            _buildVolunteerCard(context),

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
    );
  }

  Widget _buildBuyerCard(BuildContext context) {
    return _SelectionCard(
      title: "Register as Buyer",
      description: "Find and purchase surplus meals near you at great prices.",
      icon: Icons.shopping_bag_outlined,
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
        navigateWithRole(context, const SellerRegisterPage());
      },
    );
  }

  Widget _buildVolunteerCard(BuildContext context) {
    return _SelectionCard(
      title: "Register as Volunteer",
      description: "Lend a hand in distributing food to those who need it.",
      icon: Icons.volunteer_activism_outlined,
      onTap: () {
        navigateWithRole(context, const VolunteerRegisterPage());
      },
    );
  }
}
