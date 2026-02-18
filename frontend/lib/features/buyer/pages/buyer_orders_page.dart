/// File: buyer_orders_page.dart
/// Purpose: Historical and active order management for buyers.
/// 
/// Responsibilities:
/// - Fetches and categorizes orders (Active vs History)
/// - Displays live order status with progress indicators
/// - Links to deep-level order tracking and details
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_order_track_page.dart';
import 'buyer_order_details_page.dart';

/// Tabbed interface for monitoring order lifecycles.
class BuyerOrdersPage extends StatefulWidget {
  const BuyerOrdersPage({super.key});

  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

/// Manages order synchronization, tab filtering, and status rendering.
class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  /// Synchronizes the order list with the [BackendService].
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final buyerId = authProvider.mongoUser?['_id'];
      if (buyerId != null) {
        final orders = await BackendService.getBuyerOrders(buyerId);
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = "User not logged in";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error: $_error", style: GoogleFonts.inter(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchOrders, child: const Text("Retry")),
                    ],
                  ),
                )
              : _buildTabbedView(),
    );
  }

  Widget _buildTabbedView() {
    // Filter orders
    final activeStatusList = ["placed", "awaiting_volunteer", "volunteer_assigned", "picked_up"];
    final activeOrders = _orders
        .where((o) => activeStatusList.contains(o['status']))
        .toList();
    final historicalOrders = _orders
        .where((o) => !activeStatusList.contains(o['status']))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "History"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: _buildOrderList(context, activeOrders),
                ),
                RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: _buildOrderList(context, historicalOrders),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          "No orders found",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  /// Constructs a summarized order card with status chips and progress bars.
  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? "unknown";
    final isDelivery = order['fulfillment'] == 'volunteer_delivery';
    final hasOtp = order['handoverOtp'] != null && (status == 'volunteer_assigned' || status == 'picked_up');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerOrderDetailsPage(order: order),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildOrderImage(order),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order['listingId']?['foodName'] ?? "Unknown Item",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            _buildFulfillmentBadge(isDelivery),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quantity: ${order['quantityOrdered']} • ₹${order['pricing']?['total'] ?? 0}",
                          style: GoogleFonts.inter(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip(order),
                            const Spacer(),
                            if (hasOtp) _buildOtpBadge(order['handoverOtp']),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (status != 'delivered' && status != 'cancelled') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildLiveProgressBar(status),
              ),
              if (isDelivery && status != 'placed') 
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to Tracking Page
                      },
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: const Text("Track Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderImage(Map<String, dynamic> order) {
    final images = order['listingId']?['images'] as List?;
    final imageUrl = (images != null && images.isNotEmpty) ? BackendService.formatImageUrl(images.first) : null;

    if (imageUrl == null) {
      return Container(
        width: 70,
        height: 70,
        color: Colors.grey.shade100,
        child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 24),
      );
    }

    return Image.network(
      imageUrl,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 70,
          height: 70,
          color: Colors.grey.shade100,
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24),
        );
      },
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> order) {
    final status = order['status'] ?? "unknown";
    Color color = Colors.blue;
    String label = status.toUpperCase().replaceAll("_", " ");

    if (status == "delivered" || status == "completed") {
      color = Colors.green;
    } else if (status == "cancelled") {
      color = Colors.red;
    } else if (status == "volunteer_assigned" || status == "picked_up") {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildFulfillmentBadge(bool isDelivery) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDelivery ? Colors.purple.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDelivery ? Icons.moped_rounded : Icons.directions_walk_rounded,
            size: 14,
            color: isDelivery ? Colors.purple : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            isDelivery ? "Delivery" : "Pickup",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDelivery ? Colors.purple : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBadge(dynamic otp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            "OTP: $otp",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders a multi-stage dot-and-line progress indicator based on order status.
  Widget _buildLiveProgressBar(String status) {
    final List<String> stages = ['placed', 'volunteer_assigned', 'picked_up', 'delivered'];
    int currentIndex = stages.indexOf(status);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            bool isLast = index == stages.length - 1;
            bool isCompleted = index <= currentIndex;
            
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: (index < currentIndex) ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Placed", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
            Text("Assigned", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
            Text("Picked Up", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
            Text("Delivered", style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
