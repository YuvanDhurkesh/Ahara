import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../shared/styles/app_colors.dart';
import 'seller_order_detail_page.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Orders for demonstration
    final List<Order> mockOrders = [
      Order(
        id: "ORD001",
        listingId: "1",
        listingName: "Mixed Veg Curry",
        buyerId: "B001",
        buyerName: "Rahul Sharma",
        status: OrderStatus.pending,
        totalAmount: 0,
        pickupInstructions: "Please pack in eco-friendly containers.",
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Order(
        id: "ORD002",
        listingId: "2",
        listingName: "Organic Carrots",
        buyerId: "B002",
        buyerName: "Sneha Kapur",
        status: OrderStatus.confirmed,
        totalAmount: 45.0,
        pickupInstructions: "Leave near the gate.",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Order(
        id: "ORD003",
        listingId: "3",
        listingName: "Whole Wheat Bread",
        buyerId: "B003",
        buyerName: "Amit Patel",
        status: OrderStatus.picked_up,
        totalAmount: 0,
        pickupInstructions: "",
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mockOrders.length,
          itemBuilder: (context, index) {
            final order = mockOrders[index];
            return _buildOrderCard(context, order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
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
                    "Order #${order.id.substring(order.id.length - 6).toUpperCase()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.listingName,
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
                    order.buyerName,
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
                    DateFormat('MMM dd, hh:mm a').format(order.createdAt),
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

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.picked_up:
        color = Colors.indigo;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase().replaceAll('_', ' '),
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
