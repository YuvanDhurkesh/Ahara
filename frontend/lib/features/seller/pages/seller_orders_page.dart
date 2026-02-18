/// File: seller_orders_page.dart
/// Purpose: Order management dashboard for tracking donation fulfillment.
/// 
/// Responsibilities:
/// - Retrieves order history and active claims from the backend
/// - Displays reactive status indicators for multi-stage fulfillment
/// - Facilitates navigation to granular order details and actions
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'seller_order_detail_page.dart';

/// Interface for monitors and processing claims on food listings.
/// 
/// Features:
/// - Dynamic order status tracking with color-coded chips
/// - Pull-to-refresh synchronization with Node.js backend
/// - Responsive order history visualization
class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

/// Manages order state, asynchronous fetching, and error handling for the seller.
class _SellerOrdersPageState extends State<SellerOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  /// Synchronizes the seller's order list with the database.
  /// 
  /// Flow:
  /// 1. Set loading state
  /// 2. Fetch authenticated seller ID from [AppAuthProvider]
  /// 3. Invoke [BackendService.getSellerOrders]
  /// 4. Handle success/error and update UI
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final sellerId = authProvider.mongoUser?['_id'];
      if (sellerId != null) {
        final orders = await BackendService.getSellerOrders(sellerId);
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
        title: const Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                      Text("Error: $_error", style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchOrders, child: const Text("Retry")),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(context, order);
                        },
                      ),
                    ),
                  ),
                ),
    );
  }

  /// Builds a descriptive card for an individual order.
  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final foodName = order['listingId']?['foodName'] ?? "Unknown Item";
    final buyerName = order['buyerId']?['name'] ?? "Unknown Buyer";
    final createdAt = DateTime.parse(order['createdAt']);
    final status = order['status'] ?? "pending";
    final orderId = order['_id'].toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SellerOrderDetailPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${orderId.substring(orderId.length - 6).toUpperCase()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                foodName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buyerName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.5),
                    ),
                  ),
                  const Text(
                    "View Details",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates reactive status chips with domain-specific color coding.
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case "placed":
      case "pending":
        color = Colors.orange;
        break;
      case "awaiting_volunteer":
        color = Colors.blue;
        break;
      case "volunteer_assigned":
        color = Colors.indigo;
        break;
      case "picked_up":
        color = Colors.purple;
        break;
      case "delivered":
      case "completed":
        color = Colors.green;
        break;
      case "cancelled":
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
