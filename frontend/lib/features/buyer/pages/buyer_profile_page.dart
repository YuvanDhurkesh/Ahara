import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../auth/pages/login_page.dart';
import 'buyer_account_details_page.dart';
import '../../../../core/utils/responsive_layout.dart';
import 'buyer_notifications_page.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/animated_toast.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  bool _isLoadingStats = true;
  String? _statsError;
  int _ordersPlaced = 0;
  int _ordersCancelled = 0;
  double _totalSpent = 0;
  int? _localTrustScore;

  @override
  void initState() {
    super.initState();
    _fetchBuyerStats();
  }

  Future<void> _fetchBuyerStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      if (authProvider.mongoUser == null) {
        await authProvider.refreshMongoUser();
      }

      final buyerId = authProvider.mongoUser?['_id'];
      if (buyerId == null) {
        throw Exception("Unable to load buyer profile");
      }

      final orders = await BackendService.getBuyerOrders(buyerId.toString());

      int totalOrders = 0;
      int cancelledOrders = 0;
      double totalSpent = 0;
      int completedOrders = 0;
      int onTimeCount = 0;

      for (final order in orders) {
        totalOrders += 1;

        final status = (order['status'] ?? '').toString();
        if (status == 'cancelled' && order['cancellation'] != null && order['cancellation']['cancelledBy'] == 'buyer') {
          cancelledOrders += 1;
        }
        if (status == 'delivered' || status == 'completed') {
          completedOrders += 1;
          // check on-time: compare scheduled pickup to delivered timestamp if available
          final pickup = order['pickup'];
          final timeline = order['timeline'];
          DateTime? scheduled;
          DateTime? delivered;
          try {
            if (pickup != null && pickup['scheduledAt'] != null) {
              scheduled = DateTime.tryParse(pickup['scheduledAt'].toString());
            }
            if (timeline != null && timeline['deliveredAt'] != null) {
              delivered = DateTime.tryParse(timeline['deliveredAt'].toString());
            }
          } catch (_) {}
          if (delivered != null) {
            if (scheduled != null) {
              final diff = delivered.difference(scheduled).inMinutes;
              if (diff <= 60) onTimeCount += 1;
            } else {
              onTimeCount += 1;
            }
          }
        }

        final pricing = order['pricing'];
        final total = pricing is Map<String, dynamic>
            ? pricing['total']
            : (pricing is Map ? pricing['total'] : null);

        if (total is num) {
          totalSpent += total.toDouble();
        }
      }

      // compute a local trust score continuously based on recent orders
      int localScore = 50;
      if (totalOrders > 0) {
        final completionRate = completedOrders / totalOrders;
        final cancelRate = cancelledOrders / totalOrders;
        final onTimeRate = completedOrders > 0 ? (onTimeCount / completedOrders) : 0;
        final completionWeight = 30;
        final cancelWeight = 30;
        final onTimeWeight = 20;
        localScore = 50 + (completionRate * completionWeight).round() - (cancelRate * cancelWeight).round() + (onTimeRate * onTimeWeight).round();
        if (localScore > 100) localScore = 100;
        if (localScore < 0) localScore = 0;
      }

      if (!mounted) return;
      setState(() {
        _ordersPlaced = totalOrders;
        _ordersCancelled = cancelledOrders;
        _totalSpent = totalSpent;
        _localTrustScore = localScore;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final mongoUser = auth.mongoUser;
    final displayName =
        (mongoUser?['name'] ?? auth.currentUser?.displayName ?? 'Buyer')
            .toString();
    final trustScore = mongoUser?['trustScore'];
    final displayTrustScore = trustScore ?? (_isLoadingStats ? null : _localTrustScore);

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
                      "Hello, $displayName",
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
                        title: "Orders Placed",
                        value: _isLoadingStats
                            ? "..."
                            : _ordersPlaced.toString(),
                        subtext: _statsError != null
                            ? "Unable to load"
                            : "Your Order Journey",
                        icon: Icons.star_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        title: "Impact Score",
                        value: displayTrustScore == null
                          ? "N/A"
                          : ((_localTrustScore ?? trustScore) ?? displayTrustScore).toString(),
                        subtext: "Reflects contribution to waste reduction.",
                        icon: Icons.shield_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Dietary Preferences Section
                Row(
                  children: [
                    Text(
                      "Dietary Preferences",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _setAllPreferences(true),
                      child: Text("Select All", style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => _setAllPreferences(false),
                      child: Text("Clear All", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "We'll filter your feed based on these choices.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPreferenceChip("vegetarian", "Vegetarian", Icons.eco_outlined),
                    _buildPreferenceChip("vegan", "Vegan", Icons.eco),
                    _buildPreferenceChip("non_veg", "Non-Veg", Icons.kebab_dining_outlined),
                    _buildPreferenceChip("jain", "Jain", Icons.temple_hindu_outlined),
                  ],
                ),

                const SizedBox(height: 40),

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
                      _buildImpactStat(
                        "Orders Placed",
                        _isLoadingStats ? "..." : _ordersPlaced.toString(),
                        Icons.shopping_bag_outlined,
                      ),
                      _buildImpactStat(
                        "Orders Cancelled",
                        _isLoadingStats ? "..." : _ordersCancelled.toString(),
                        Icons.cancel_outlined,
                      ),
                      _buildImpactStat(
                        "Total Spent",
                        _isLoadingStats
                            ? "..."
                            : "₹${_totalSpent.toStringAsFixed(0)}",
                        Icons.savings_outlined,
                      ),
                    ],
                  ),
                  desktop: Row(
                    children: [
                      Expanded(
                        child: _buildImpactStat(
                          "Orders Placed",
                          _isLoadingStats ? "..." : _ordersPlaced.toString(),
                          Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImpactStat(
                          "Orders Cancelled",
                          _isLoadingStats ? "..." : _ordersCancelled.toString(),
                          Icons.cancel_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImpactStat(
                          "Total Spent",
                          _isLoadingStats
                              ? "..."
                              : "₹${_totalSpent.toStringAsFixed(0)}",
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

  Widget _buildPreferenceChip(String key, String label, IconData icon) {
    final auth = context.watch<AppAuthProvider>();
    final List<String> currentPrefs = List<String>.from(auth.mongoProfile?['dietaryPreferences'] ?? []);
    final bool isSelected = currentPrefs.contains(key);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) => _togglePreference(key, selected),
      avatar: Icon(
        icon, 
        color: isSelected ? Colors.white : AppColors.primary, 
        size: 18
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      showCheckmark: false, // Standard checkmark hidden for cleaner look
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: isSelected ? 8 : 0,
      shadowColor: AppColors.primary.withOpacity(0.4),
      pressElevation: 12,
    );
  }

  Future<void> _setAllPreferences(bool selectAll) async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final List<String> newPrefs = selectAll 
        ? ["vegetarian", "vegan", "non_veg", "jain"] 
        : [];
    
    await _updatePreferences(newPrefs);
  }

  Future<void> _togglePreference(String key, bool selected) async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final List<String> currentPrefs = List<String>.from(auth.mongoProfile?['dietaryPreferences'] ?? []);

    if (selected) {
      if (!currentPrefs.contains(key)) currentPrefs.add(key);
    } else {
      currentPrefs.remove(key);
    }
    
    await _updatePreferences(currentPrefs);
  }

  Future<void> _updatePreferences(List<String> prefs) async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final String? firebaseUid = auth.currentUser?.uid;
    
    if (firebaseUid == null) return;

    try {
      await BackendService.updateBuyerProfile(
        firebaseUid: firebaseUid,
        dietaryPreferences: prefs,
      );
      await auth.refreshMongoUser();
      
      if (mounted) {
        AnimatedToast.show(
          context,
          "Preferences updated!",
          type: ToastType.success,
        );
      }
    } catch (e) {
      debugPrint("Error updating dietary preferences: $e");
      if (mounted) {
        AnimatedToast.show(
          context,
          "Failed to update preferences",
          type: ToastType.error,
        );
      }
    }
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
                          await Provider.of<AppAuthProvider>(
                            context,
                            listen: false,
                          ).logout();
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
