import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../../data/services/backend_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/language_provider.dart';

class SellerOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const SellerOrderDetailPage({super.key, required this.order});

  @override
  State<SellerOrderDetailPage> createState() => _SellerOrderDetailPageState();
}

class _SellerOrderDetailPageState extends State<SellerOrderDetailPage> {
  late String _currentStatus;
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'pending';
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleOtpVerification() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 4-digit OTP")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await BackendService.verifyOtp(
        widget.order['_id'],
        otp,
      );

      if (mounted) {
        setState(() {
          _currentStatus = response['order']['status'];
          _isVerifying = false;
          _otpController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(response['message'] ?? "Verified successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString().replaceAll("Exception: ", "")),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await BackendService.updateOrderStatus(widget.order['_id'], newStatus);
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Order status updated to ${newStatus.replaceAll('_', ' ')}",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to cancel this order? This will restore listing quantity and notify the buyer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No, Keep it")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackendService.cancelOrder(
          widget.order['_id'],
          "seller",
          "Cancelled by seller",
        );
        if (mounted) {
          setState(() => _currentStatus = "cancelled");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled"), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to cancel: $e")),
          );
        }
      }
    }
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
            const SizedBox(height: 24),
            _buildOtpVerificationSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final foodName = widget.order['listingId'] != null ? Provider.of<LanguageProvider>(context, listen: false).getTranslatedText(context, widget.order['listingId'], 'foodName') : "Unknown Item";
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

  Widget _buildOtpVerificationSection() {
    bool isSelfPickup = widget.order['fulfillment'] == 'self_pickup';
    bool canVerify = false;
    String helperText = "";

    if (isSelfPickup) {
      if (_currentStatus == 'placed') {
        canVerify = true;
        helperText = "Enter Buyer's Handover OTP once they arrive for pickup.";
      }
    } else {
      // Volunteer Delivery
      if (['placed', 'volunteer_assigned', 'volunteer_accepted'].contains(_currentStatus)) {
        canVerify = true;
        helperText = "Enter Volunteer's Pickup OTP to record the collection.";
      }
    }

    if (!canVerify) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                "Secure Handover",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "0000",
                    hintStyle: TextStyle(
                      color: AppColors.textLight.withOpacity(0.2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleOtpVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Verify",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == "delivered" ||
        _currentStatus == "cancelled" ||
        _currentStatus == "picked_up") {
      return const SizedBox.shrink();
    }

    String nextButtonText = "";
    String? nextStatus;

    switch (_currentStatus) {
      case "placed":
      case "pending":
        // For seller, if it's self-pickup, they verify OTP. 
        // If it's delivery, they should wait for a volunteer matching.
        if (widget.order['fulfillment'] == 'volunteer_delivery') {
          nextButtonText = "Awaiting Volunteer...";
          nextStatus = null;
        } else {
          // Self pickup? They can use the OTP section. 
          return const SizedBox.shrink();
        }
        break;
      case "awaiting_volunteer":
        nextButtonText = "Broadcast Sent...";
        nextStatus = null; 
        break;
      case "volunteer_assigned":
      case "volunteer_accepted":
        // Use OTP section
        return const SizedBox.shrink();
      default:
        break;
    }

    if (nextButtonText.isEmpty) return const SizedBox.shrink();

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
        if (_currentStatus == "placed" || _currentStatus == "pending" || _currentStatus == "awaiting_volunteer" || _currentStatus == "volunteer_assigned") ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: _cancelOrder,
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
