import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/simplified_dashboard_wrapper.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../common/pages/landing_page.dart';
import 'simplified_seller_home.dart';
import 'seller_notifications_page.dart';

class SellerOverviewPage extends StatefulWidget {
  const SellerOverviewPage({super.key});

  @override
  State<SellerOverviewPage> createState() => _SellerOverviewPageState();
}

class _SellerOverviewPageState extends State<SellerOverviewPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      
      // Ensure mongoUser is refreshed if not available
      if (authProvider.mongoUser == null) {
        await authProvider.refreshMongoUser();
      }

      var sellerId = authProvider.mongoUser?['_id'];

      if (sellerId == null) {
        throw Exception("Unable to load user profile. Please log in again.");
      }

      // Fetch stats and orders in parallel
      final statsFuture = BackendService.getSellerStats(sellerId);
      final ordersFuture = BackendService.getSellerOrders(sellerId);

      final stats = await statsFuture;
      final orders = await ordersFuture;

      // Build activities from orders
      final activities = _buildActivitiesFromData(orders);

      if (mounted) {
        setState(() {
          _stats = stats;
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildActivitiesFromData(
    List<Map<String, dynamic>> orders,
  ) {
    final activities = <Map<String, dynamic>>[];

    // Add order-related activities
    for (var order in orders.take(10)) {
      final status = order['status']?.toString().toLowerCase() ?? 'unknown';
      final buyerId = order['buyerId'];
      final buyerName = buyerId is Map ? buyerId['name'] ?? 'Buyer' : 'Buyer';
      final listingId = order['listingId'];
      final listingName =
          listingId is Map ? listingId['name'] ?? 'Item' : 'Item';
      final createdAt = order['createdAt'];
      final DateTime orderDate =
          createdAt is String ? DateTime.parse(createdAt) : DateTime.now();

      if (status == 'pending') {
        activities.add({
          'type': 'order_pending',
          'title': AppLocalizations.of(context)!.translate("new_order_received"),
          'subtitle': '$listingName • ${buyerName ?? "Customer"}',
          'timestamp': orderDate,
          'icon': Icons.shopping_basket_rounded,
          'color': Colors.orange,
        });
      } else if (status == 'completed') {
        activities.add({
          'type': 'order_completed',
          'title': AppLocalizations.of(context)!.translate("order_completed"),
          'subtitle': '$listingName • ₹${order['totalPrice'] ?? "0"}',
          'timestamp': orderDate,
          'icon': Icons.check_circle_outline_rounded,
          'color': Colors.green,
        });
      } else if (status == 'cancelled') {
        activities.add({
          'type': 'order_cancelled',
          'title': AppLocalizations.of(context)!.translate("order_cancelled"),
          'subtitle': '$listingName • ${buyerName ?? "Customer"}',
          'timestamp': orderDate,
          'icon': Icons.cancel_outlined,
          'color': Colors.red,
        });
      }

      // If order has reviews, add review activity
      final reviews = order['reviews'];
      if (reviews is List && reviews.isNotEmpty) {
        final review = reviews.first as Map<String, dynamic>;
        final rating = review['rating'] ?? 0;
        final comment = review['comment'];
        activities.add({
          'type': 'new_feedback',
          'title': AppLocalizations.of(context)!.translate("new_feedback"),
          'subtitle':
              '${'⭐' * rating.toInt()} ${comment ?? "Seller review received"}',
          'timestamp': createdAt is String
              ? DateTime.parse(createdAt)
              : DateTime.now(),
          'icon': Icons.star_rounded,
          'color': Colors.teal,
        });
      }
    }

    // Sort by most recent
    activities.sort(
      (a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp']),
    );

    return activities.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SimplifiedDashboardWrapper(
      simplifiedDashboard: const SimplifiedSellerHome(),
      standardDashboard: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _fetchStats,
          color: AppColors.primary,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),

                      // STATS GRID
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_error != null)
                        _buildErrorState()
                      else
                        _buildStatsGrid(),

                      const SizedBox(height: 32),

                      Text(
                        AppLocalizations.of(context)!.translate("recent_activity"),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivityList(),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final userName = authProvider.mongoUser?['name'] ?? "Seller";
    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').map((s) => s[0]).take(2).join()
        : 'S';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  initials.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate("seller_dashboard"),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${AppLocalizations.of(context)!.translate("welcome_back_user")}, $userName",
                      style: GoogleFonts.inter(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellerNotificationsPage(),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              tooltip: "Notifications",
            ),
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              tooltip: "Logout",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 12),
          Text(
            "Failed to load statistics",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? "Unknown error",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        final double childAspectRatio = constraints.maxWidth > 700 ? 1.6 : 1.4;

        final activeListings = _stats?['activeListings']?.toString() ?? "0";
        final pendingOrders = _stats?['pendingOrders']?.toString() ?? "0";
        final avgRating = _stats?['avgRating']?.toStringAsFixed(1) ?? "0.0";
        final earnings = _stats?['monthlyEarnings'] ?? 0;
        final earningsText = earnings >= 1000 
            ? "₹${(earnings / 1000).toStringAsFixed(1)}k" 
            : "₹$earnings";

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("active_listings"),
              activeListings,
              Icons.inventory_2_rounded,
              const [Color(0xFF6B8E23), Color(0xFF8DB600)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("pending_orders"),
              pendingOrders,
              Icons.pending_actions_rounded,
              const [Color(0xFFCD853F), Color(0xFFD2B48C)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("avg_rating"),
              avgRating,
              Icons.star_rounded,
              const [Color(0xFF2E8B57), Color(0xFF3CB371)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("monthly_earnings"),
              earningsText,
              Icons.account_balance_wallet_rounded,
              const [Color(0xFF4682B4), Color(0xFF5F9EA0)],
            ),
          ],
        );
      },
    );
  }

  String _getCurrentMonthLabel() {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildRecentActivityList() {
    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            AppLocalizations.of(context)!.translate("no_recent_activity"),
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _activities.map((activity) {
        final timeString = _getTimeAgoString(activity['timestamp'] as DateTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: AppColors.textLight.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activity['color'].withOpacity(0.18),
                      activity['color'].withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activity['color'].withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  activity['icon'],
                  color: activity['color'].shade700 ?? activity['color'],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity['subtitle'],
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textLight.withOpacity(0.35),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getTimeAgoString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.translate("just_now") ?? "Just now";
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${AppLocalizations.of(context)!.translate("mins_ago") ?? "mins ago"}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${AppLocalizations.of(context)!.translate("hours_ago") ?? "hours ago"}';
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.translate("yesterday") ?? "Yesterday";
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${AppLocalizations.of(context)!.translate("days_ago") ?? "days ago"}';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: -6,
              child: Icon(
                icon,
                size: 56,
                color: gradientColors[0].withOpacity(0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textLight.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getCurrentMonthLabel(),
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
