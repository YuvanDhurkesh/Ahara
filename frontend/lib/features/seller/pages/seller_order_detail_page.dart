/// File: seller_order_detail_page.dart
/// Purpose: Granular view and lifecycle management for individual food orders.
/// 
/// Responsibilities:
/// - Displays comprehensive order metadata (Items, Buyer, Timing)
/// - Implements a status transformation stepper for fulfillment tracking
/// - Provides contextual actions based on the current order state
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/styles/app_colors.dart';

/// Detailed inspection and management interface for a specific order.
/// 
/// Features:
/// - Reactive status synchronization logic
/// - Visual stepper for fulfillment progress
/// - Contextual action triggers (Confirm, Cancel, Logistics)
class SellerOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const SellerOrderDetailPage({super.key, required this.order});

  @override
  State<SellerOrderDetailPage> createState() => _SellerOrderDetailPageState();
}

class _SellerOrderDetailPageState extends State<SellerOrderDetailPage> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'pending';
  }

  /// Dispatcher for updating order status and notifying relevant telemetry services.
  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    // TODO: Call service to update status in backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Order status updated to ${newStatus.replaceAll('_', ' ')}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: 24),
            _buildStatusStepper(),
            const SizedBox(height: 24),
            _buildBuyerInfo(),
            const SizedBox(height: 16),
            _buildPickupInstructions(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final foodName = widget.order['listingId']?['foodName'] ?? "Unknown Item";
    final orderId = widget.order['_id'].toString();
    final createdAt = DateTime.parse(widget.order['createdAt']);
    final totalAmount = widget.order['pricing']?['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order #${orderId.substring(orderId.length - 6).toUpperCase()}",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    foodName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentStatus.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: _getStatusColor(_currentStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat(
                "Amount",
                "₹${totalAmount.toString()}",
              ),
              _buildHeaderStat(
                "Date",
                DateFormat('MMM dd, yyyy').format(createdAt),
              ),
              _buildHeaderStat(
                "Time",
                DateFormat('hh:mm a').format(createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textLight.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStepper() {
    final List<String> stages = [
      "placed",
      "awaiting_volunteer",
      "volunteer_assigned",
      "picked_up",
      "delivered",
    ];

    int currentIndex = stages.indexOf(_currentStatus);
    if (_currentStatus == "cancelled") currentIndex = -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Progress",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(stages.length, (index) {
            bool isLast = index == stages.length - 1;
            bool isCompleted = index <= currentIndex;
            bool isCurrent = index == currentIndex;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.textLight.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: 14,
                          color: isCompleted
                              ? Colors.white
                              : AppColors.textLight.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStageLabel(stages[index]),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isCompleted
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCompleted
                              ? AppColors.textDark
                              : AppColors.textLight.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        color: (index < currentIndex)
                            ? AppColors.primary
                            : AppColors.textLight.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBuyerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buyer Information",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.order['buyerId']?['name'] ?? "Unknown Buyer",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Pickup Instructions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            (widget.order['specialInstructions'] ?? "").isEmpty
                ? "No specific instructions provided. Please wait at the specified location."
                : widget.order['specialInstructions'],
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == "delivered" ||
        _currentStatus == "cancelled") {
      return const SizedBox.shrink();
    }

    String nextButtonText = "";
    String? nextStatus;

    switch (_currentStatus) {
      case "placed":
      case "pending":
        nextButtonText = "Confirm Order";
        nextStatus = "awaiting_volunteer";
        break;
      case "awaiting_volunteer":
        nextButtonText = "Volunteer Requested";
        nextStatus = null; 
        break;
      case "volunteer_assigned":
        nextButtonText = "Mark as Picked Up";
        nextStatus = "picked_up";
        break;
      case "picked_up":
        nextButtonText = "Mark as Delivered";
        nextStatus = "delivered";
        break;
      default:
        break;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: nextStatus != null
                ? () => _updateStatus(nextStatus!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              nextButtonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_currentStatus == "placed" || _currentStatus == "pending") ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () => _updateStatus("cancelled"),
              child: const Text(
                "Cancel Order",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "placed":
      case "pending":
        return Colors.orange;
      case "awaiting_volunteer":
        return Colors.blue;
      case "volunteer_assigned":
        return Colors.indigo;
      case "picked_up":
        return Colors.purple;
      case "delivered":
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStageLabel(String status) {
    switch (status) {
      case "placed":
      case "pending":
        return "Placed";
      case "awaiting_volunteer":
        return "Requested";
      case "volunteer_assigned":
        return "Assigned";
      case "picked_up":
        return "Picked Up";
      case "delivered":
        return "Delivered";
      default:
        return "";
    }
  }
}
