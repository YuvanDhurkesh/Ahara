import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';

class SellerNotificationsPage extends StatefulWidget {
  const SellerNotificationsPage({super.key});

  @override
  State<SellerNotificationsPage> createState() =>
      _SellerNotificationsPageState();
}

class _SellerNotificationsPageState extends State<SellerNotificationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final sellerId = authProvider.mongoUser?['_id'];

      if (sellerId == null) throw Exception("Seller ID not found");

      // Fetch recent orders
      final orders = await BackendService.getSellerOrders(sellerId);
      
      // Fetch active listings for inventory alerts
      final listings = await BackendService.getActiveListings(sellerId);

      if (mounted) {
        setState(() {
          _orders = (orders as List)
              .cast<Map<String, dynamic>>()
              .take(5)
              .toList();
          _listings = (listings as List)
              .cast<Map<String, dynamic>>()
              .where((l) => (l['remainingQuantity'] ?? 0) < 5)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_orders.isNotEmpty)
                    _buildNotificationGroup("Orders", [
                      for (final order in _orders)
                        _buildOrderNotification(order),
                    ])
                  else
                    _buildEmptyState("No recent orders"),
                  const SizedBox(height: 32),
                  if (_listings.isNotEmpty)
                    _buildNotificationGroup("Inventory", [
                      for (final listing in _listings)
                        _buildInventoryAlert(listing),
                    ])
                  else
                    _buildEmptyState("All items well-stocked"),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderNotification(Map<String, dynamic> order) {
    final orderId = order['_id'] ?? 'N/A';
    final status = order['status'] ?? 'pending';
    final total = order['pricing']?['total'] ?? 0;
    final createdAt = order['createdAt'] != null
        ? DateTime.parse(order['createdAt']).toString().split('.')[0]
        : 'N/A';

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_basket_outlined,
                color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order #${orderId.toString().substring(0, 8)}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹$total - $statusLabel",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  createdAt,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textLight.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAlert(Map<String, dynamic> listing) {
    final foodName = listing['foodName'] ?? 'Item';
    final remaining = listing['remainingQuantity'] ?? 0;
    final total = listing['totalQuantity'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stock Alert",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$foodName running low ($remaining/$total left)",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.orange.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Updated just now",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textLight.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textLight.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textLight.withOpacity(0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
      case 'awaiting_volunteer':
        return Colors.blue;
      case 'volunteer_assigned':
      case 'picked_up':
      case 'in_transit':
        return Colors.amber;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'placed':
        return 'New Order';
      case 'awaiting_volunteer':
        return 'Awaiting Volunteer';
      case 'volunteer_assigned':
        return 'Volunteer Assigned';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}