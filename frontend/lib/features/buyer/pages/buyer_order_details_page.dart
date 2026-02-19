import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_order_rate_page.dart';
import 'buyer_order_track_page.dart';
import '../data/mock_orders.dart';
import '../data/mock_stores.dart';

class BuyerOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyerOrderDetailsPage({super.key, required this.order});

  @override
  State<BuyerOrderDetailsPage> createState() => _BuyerOrderDetailsPageState();
}

class _BuyerOrderDetailsPageState extends State<BuyerOrderDetailsPage> {
  late Map<String, dynamic> _localOrder;
  bool _isCancelled = false;
  int _otpExpirySeconds = 492; // Mock 8:12
  Timer? _otpTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _localOrder = widget.order;
    _isCancelled = _localOrder['status'] == 'cancelled';
    _startOtpTimer();
  }

  void _startOtpTimer() {
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpExpirySeconds > 0) {
        setState(() => _otpExpirySeconds--);
      } else {
        _otpTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final status = _localOrder['status'] ?? "placed";
    final listing = _localOrder['listingId'] ?? {};
    final seller = _localOrder['sellerId'] ?? {};
    final volunteer = _localOrder['volunteerId'];
    final isDelivery = _localOrder['fulfillment'] == 'volunteer_delivery';
    final isCompleted = status == "delivered" || status == "completed";
    final isCancelled = status == "cancelled";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: AppColors.textLight),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBanner(status),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 12),
                _buildOrderIdentity(_localOrder),
                const SizedBox(height: 24),
                _buildModeIndicator(isDelivery),
                const SizedBox(height: 24),
                if (!isDelivery && !isCompleted && !isCancelled) ...[
                  _buildPickupMap(listing),
                  const SizedBox(height: 24),
                ],
                _buildSellerCard(seller, listing),
                const SizedBox(height: 24),
                if (!isCompleted && !isCancelled) ...[
                  _buildOtpSection(_localOrder['handoverOtp']),
                  const SizedBox(height: 24),
                ],
                _buildVolunteerSection(isDelivery, volunteer, status),
                const SizedBox(height: 24),
                _buildOrderSummary(_localOrder, listing),
                const SizedBox(height: 24),
                _buildTimelineCard(_localOrder),
                const SizedBox(height: 24),
                _buildFoodSafetyCard(listing),
                const SizedBox(height: 32),
                _buildActionButtons(status, isDelivery),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupMap(Map<String, dynamic> listing) {
    final geo = listing['geo']?['coordinates'] as List?;
    final LatLng pickupPos = (geo != null && geo.length == 2) 
        ? LatLng(geo[1].toDouble(), geo[0].toDouble()) 
        : const LatLng(12.9716, 77.5946); // Default Bangalore

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pickupPos,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ahara.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pickupPos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                onPressed: () => _mapController.move(pickupPos, 15),
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.primary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final bannerConfig = {
      'placed': {'color': Colors.blue, 'msg': 'Order placed successfully!'},
      'awaiting_volunteer': {'color': Colors.orange, 'msg': 'Finding a volunteer hero...'},
      'volunteer_assigned': {'color': Colors.indigo, 'msg': 'Volunteer assigned & on the way!'},
      'picked_up': {'color': Colors.purple, 'msg': 'Food picked up! Arriving soon.'},
      'delivered': {'color': Colors.green, 'msg': 'Food delivered. Enjoy!'},
      'completed': {'color': Colors.green, 'msg': 'Hope you enjoyed the meal!'},
      'cancelled': {'color': Colors.red, 'msg': 'This order was cancelled.'},
    };

    final config = bannerConfig[status] ?? bannerConfig['placed']!;
    final color = config['color'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: color.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            config['msg'] as String,
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderIdentity(Map<String, dynamic> order) {
    final date = order['createdAt'] != null ? DateTime.parse(order['createdAt']) : DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${order['_id']?.toString().substring(order['_id'].length - 7).toUpperCase() ?? 'N/A'}",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              "Placed: ${DateFormat('dd MMM').format(date)} • ${DateFormat('hh:mm a').format(date)}",
              style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? "PLACED",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildModeIndicator(bool isDelivery) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(isDelivery ? Icons.moped : Icons.directions_walk, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            isDelivery ? "Volunteer Delivery" : "Self-Pickup",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          Text(
            "Fulfillment Mode",
            style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller, Map<String, dynamic> listing) {
    final trustScore = seller['trustScore'] ?? 90;
    final rating = (trustScore / 20).toStringAsFixed(1); // 100 -> 5.0, 80 -> 4.0

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildListingImage(listing, size: 50),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller['name'] ?? "Unknown Donor",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "$rating • 1.2 km away",
                          style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 18,
                  child: Icon(Icons.phone, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  listing['pickupAddressText'] ?? "No address provided",
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                "Pickup before: ${listing['pickupWindow']?['to'] != null ? DateFormat('hh:mm a').format(DateTime.parse(listing['pickupWindow']['to'])) : '7:00 AM'}",
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection(dynamic otp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "HANDOVER OTP",
                    style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  "Expires in ${_formatTimer(_otpExpirySeconds)}",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            otp?.toString() ?? "----",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 16),
          ),
          const SizedBox(height: 16),
          Text(
            "Share only after receiving and checking food.",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: Text(
              "Regenerate if expired",
              style: GoogleFonts.inter(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerSection(bool isDelivery, dynamic volunteer, String status) {
    if (!isDelivery) return const SizedBox.shrink();

    if (volunteer == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              "Looking for nearby volunteers...",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 4),
            Text(
              "You'll be notified once assigned.",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer['name'] ?? "Volunteer Hero",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Bike • ⭐ 4.8",
                      style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text("Call"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text("Track Live"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order, Map<String, dynamic> listing) {
    final pricing = order['pricing'] ?? {};
    final isDelivery = order['fulfillment'] == 'volunteer_delivery';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORDER SUMMARY", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 16),
          _buildSummaryLine("${order['quantityOrdered'] ?? 1} × ${listing['foodName'] ?? 'Items'}", "₹${pricing['itemTotal'] ?? 0}"),
          if (isDelivery) _buildSummaryLine("Delivery Fee", "₹${pricing['deliveryFee'] ?? 0}"),
          _buildSummaryLine("Platform Fee", "₹${pricing['platformFee'] ?? 0}"),
          const Divider(height: 24),
          _buildSummaryLine("Total", "₹${pricing['total'] ?? 0}", isTotal: true),
          if (order['specialInstructions'] != null && order['specialInstructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['specialInstructions'],
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: isTotal ? 18 : 13, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> order) {
    final timeline = order['timeline'] ?? {};
    final status = order['status'] ?? "placed";
    final stages = [
      {'key': 'placed', 'label': 'Order Received', 'time': timeline['placedAt']},
      {'key': 'volunteer_assigned', 'label': 'Volunteer Assigned', 'time': order['volunteerAssignedAt']},
      {'key': 'picked_up', 'label': 'Food Picked Up', 'time': timeline['pickedUpAt']},
      {'key': 'delivered', 'label': 'Food Delivered', 'time': timeline['deliveredAt']},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("LIVE TRACKING", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 20),
          ...stages.map((stage) {
            int idx = stages.indexOf(stage);
            bool isLast = idx == stages.length - 1;
            bool isDone = _isStageDone(status, stage['key'] as String);
            bool isCurrent = status == stage['key'];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? Colors.green : (isCurrent ? Colors.orange : Colors.grey.shade200),
                      ),
                      child: isDone ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                    ),
                    if (!isLast)
                      Container(width: 2, height: 30, color: isDone ? Colors.green : Colors.grey.shade200),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['label'] as String,
                        style: GoogleFonts.inter(
                            fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isDone ? Colors.green : (isCurrent ? Colors.orange : AppColors.textLight),
                            fontSize: 14),
                      ),
                      if (stage['time'] != null)
                        Text(
                          DateFormat('hh:mm a').format(DateTime.parse(stage['time'])),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                        )
                      else if (isCurrent || !isDone)
                        Text("Pending", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFoodSafetyCard(Map<String, dynamic> listing) {
    final preparedAt = listing['createdAt'] != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(listing['createdAt'])) 
        : "4:30 AM";
    final consumeBefore = listing['safetyThreshold'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(listing['safetyThreshold']))
        : (listing['pickupWindow']?['to'] != null 
            ? DateFormat('hh:mm a').format(DateTime.parse(listing['pickupWindow']['to'])) 
            : "10:30 AM");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                "FOOD SAFETY INFO",
                style: GoogleFonts.inter(color: Colors.red.shade800, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSafetyRow("Prepared at:", "$preparedAt (Today)"),
          const SizedBox(height: 4),
          _buildSafetyRow("Consume before:", "$consumeBefore (Strictly)"),
          const SizedBox(height: 12),
          Row(
            children: [
              if (listing['isSafetyValidated'] == true) ...[
                _buildSafetyBadge("Verified Safe"),
                const SizedBox(width: 8),
              ],
              _buildSafetyBadge("Quality Checked"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700)),
        Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
      ],
    );
  }

  Widget _buildSafetyBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButtons(String status, bool isDelivery) {
    final isCompleted = status == 'delivered' || status == 'completed';
    final isPlaced = status == 'placed' || status == 'awaiting_volunteer';

    return Column(
      children: [
        if (isPlaced) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Cancel Order"),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Contact Support"),
            ),
          ),
        ],
        if (isDelivery && (status == 'volunteer_assigned' || status == 'picked_up')) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerOrderTrackPage(
                      order: MockOrder(
                        id: _localOrder['_id'],
                        store: allMockStores[0],
                        status: OrderStatus.active,
                        type: OrderType.delivery,
                        date: "Today",
                        total: "₹${_localOrder['pricing']?['total'] ?? 0}",
                        itemsSummary: _localOrder['listingId']?['foodName'] ?? "Items",
                        volunteerName: _localOrder['volunteerId']?['name'] ?? "Volunteer",
                        volunteerRating: 4.8,
                        deliveryTime: "30 mins",
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Live Tracking"),
            ),
          ),
        ],
        if (isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerOrderRatePage(order: _localOrder)));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Rate & Review Experience"),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Report an Issue"),
            ),
          ),
        ],
      ],
    );
  }

  bool _isStageDone(String currentStatus, String stage) {
    const sequence = ['placed', 'awaiting_volunteer', 'volunteer_assigned', 'volunteer_accepted', 'picked_up', 'in_transit', 'delivered', 'completed'];
    int currentIdx = sequence.indexOf(currentStatus);
    int stageIdx = sequence.indexOf(stage);
    return currentIdx > stageIdx || (currentIdx == stageIdx && currentStatus == 'delivered'); // delivered is effectively completion for UI
  }

  Widget _buildListingImage(Map<String, dynamic> listing, {double size = 50}) {
    final images = listing['images'] as List?;
    final imageUrl = (images != null && images.isNotEmpty) ? BackendService.formatImageUrl(images.first) : null;

    if (imageUrl == null) {
      return Container(width: size, height: size, color: Colors.grey.shade100, child: Icon(Icons.fastfood, size: size * 0.4, color: Colors.grey));
    }
    return Image.network(imageUrl, width: size, height: size, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: size, height: size, color: Colors.grey.shade100, child: Icon(Icons.error_outline, size: size * 0.4, color: Colors.grey)));
  }
}
