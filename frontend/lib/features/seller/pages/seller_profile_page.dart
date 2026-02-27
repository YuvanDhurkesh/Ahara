import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../common/pages/landing_page.dart';
import '../../../core/localization/language_provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import 'seller_business_details_page.dart';
import 'seller_verification_page.dart';
import 'seller_notifications_page.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  bool _isLoading = true;
  int? _localTrustScore;
  int? _lastSeenTrust;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final newTrust = auth.mongoUser?['trustScore'];
    if (newTrust != _lastSeenTrust) {
      _lastSeenTrust = newTrust;
      // whenever trust changes we want to recompute local fallback
      _fetchSellerData();
    }
  }

  Future<void> _fetchSellerData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      // Ensure mongoProfile is refreshed
      if (authProvider.mongoProfile == null &&
          authProvider.currentUser != null) {
        await authProvider.refreshMongoUser();
      }

      // compute local trust score continuously for dynamic latest value
      final sellerId = authProvider.mongoUser?['_id'];
      if (sellerId != null) {
        try {
          final orders = await BackendService.getSellerOrders(sellerId.toString());
          final computed = _computeLocalTrustFromOrders(orders);
          if (mounted) {
            setState(() {
              _localTrustScore = computed;
            });
          }
        } catch (e) {
          debugPrint("failed to compute local trust: $e");
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Error fetching seller data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        final mongoProfile = authProvider.mongoProfile;
        final backendTrust = authProvider.mongoUser?['trustScore'];

        // Fallback values if data isn't loaded
        final businessName = mongoProfile?['orgName'] ?? "Your Business";
        final rating = mongoProfile?['stats']?['avgRating'] ?? 0.0;
        final mealsShared =
            mongoProfile?['stats']?['totalOrdersCompleted'] ?? 0;

        // Calculate CO2 offset (rough estimate: ~2kg CO2 per meal)
        final co2Offset = mealsShared * 2;

        // decide which value to show
        final displayTrust = (_localTrustScore ?? backendTrust) ?? 0;
        final showBackend = _localTrustScore == null && backendTrust != null;

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
                          "Hello, $businessName",
                          style: GoogleFonts.inter(
                            fontSize: 22,
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

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: "Trust Score",
                            value: displayTrust.toString(),
                            subtext: showBackend
                                ? "From backend"
                                : (_localTrustScore != null
                                    ? "Earn Trust"
                                    : "Not available"),
                            icon: Icons.shield_outlined,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: "Rating",
                            value: "${rating.toStringAsFixed(1)}/5",
                            subtext: "From customers",
                            icon: Icons.star_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Text(
                      "Business Impact",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildImpactStat(
                          "Meals Shared",
                          "$mealsShared",
                          Icons.lunch_dining,
                        ),
                        _buildImpactStat(
                          "CO2 Saved",
                          "${co2Offset.toStringAsFixed(0)} kg",
                          Icons.eco,
                        ),
                        _buildImpactStat(
                          "Total Listings",
                          (mongoProfile?['stats']?['totalListings'] ?? 0)
                              .toString(),
                          Icons.list_alt_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              fontSize: 22,
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
              fontSize: 11,
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

  // local trust computation utility
  int _computeLocalTrustFromOrders(List<Map<String, dynamic>> orders) {
    int total = orders.length;
    if (total == 0) return 50;

    int completed = 0;
    int cancelled = 0;
    int onTime = 0;

    for (var o in orders) {
      final status = o['status']?.toString() ?? '';
      if (status == 'delivered' || status == 'completed') {
        completed += 1;
        
        DateTime? scheduled;
        DateTime? delivered;
        final pickup = o['pickup'];
        final timeline = o['timeline'];
        
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
            if (diff <= 60) onTime += 1;
          } else {
            onTime += 1;
          }
        }
      }
      if (status == 'cancelled' && o['cancellation'] != null && o['cancellation']['cancelledBy'] == 'seller') {
        cancelled += 1;
      }
    }

    final completionRate = completed / total;
    final cancelRate = cancelled / total;
    final onTimeRate = completed > 0 ? onTime / completed : 0;

    int score = 50 + (completionRate * 30).round() - (cancelRate * 30).round() + (onTimeRate * 20).round();
    if (score > 100) score = 100;
    if (score < 0) score = 0;
    return score;
  }

  void _showManageAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildSectionHeader("SETTINGS"),
                    _buildMenuItem(
                      context,
                      Icons.business_outlined,
                      "Business details",
                    ),
                    _buildMenuItem(
                      context,
                      Icons.notifications_outlined,
                      "Notifications",
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader("ACCESSIBILITY"),
                    Consumer<LanguageProvider>(
                      builder: (context, langProvider, child) {
                        return SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          title: Text(
                            "Easy Mode (Simplified)",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            "Large icons and simple flow",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          value: langProvider.isSimplified,
                          activeColor: AppColors.primary,
                          onChanged: (val) async {
                            final mode = val ? 'simplified' : 'standard';
                            await langProvider.setUiMode(mode);

                            // Persist to backend
                            final auth = Provider.of<AppAuthProvider>(
                              context,
                              listen: false,
                            );
                            if (auth.currentUser != null) {
                              try {
                                await BackendService.updateUserPreferences(
                                  firebaseUid: auth.currentUser!.uid,
                                  uiMode: mode,
                                );
                              } catch (e) {
                                debugPrint("Failed to sync UI mode: $e");
                              }
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("TRUST & VERIFICATION"),
                    _buildMenuItem(
                      context,
                      Icons.verified_user_outlined,
                      "Get Verified",
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("SUPPORT"),
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      "Help with orders",
                    ),
                    _buildMenuItem(context, Icons.info_outline, "How it works"),

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
                                builder: (context) => const LandingPage(),
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
                        child: const Text("Log out"),
                      ),
                    ),
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
        if (title == "Business details") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SellerBusinessDetailsPage(),
            ),
          );
        } else if (title == "Get Verified") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SellerVerificationPage(),
            ),
          );
        } else if (title == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SellerNotificationsPage(),
            ),
          );
        }
      },
    );
  }
}
