import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../../data/services/backend_service.dart';
import '../../../../data/services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic>? order;

  const VolunteerOrderDetailPage({super.key, this.order});

  @override
  State<VolunteerOrderDetailPage> createState() =>
      _VolunteerOrderDetailPageState();
}

class _VolunteerOrderDetailPageState extends State<VolunteerOrderDetailPage> {
  final MapController _mapController = MapController();
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  late String _currentStatus;
  StreamSubscription<Position>? _positionStream;

  // LatLng from latlong2
  LatLng pickupLocation = const LatLng(20.5937, 78.9629); // India center
  LatLng deliveryLocation = const LatLng(20.5937, 78.9629); // India center
  LatLng _currentVolunteerPos = const LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _currentStatus = widget.order?['status'] ?? 'placed';
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() async {
    // Only track if in transit
    if (!['picked_up', 'in_transit'].contains(_currentStatus)) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentVolunteerPos = LatLng(position.latitude, position.longitude);
        });
      }

      // Update Socket
      if (widget.order?['_id'] != null) {
        SocketService.updateLocation(
          widget.order!['_id'],
          position.latitude,
          position.longitude,
        );
      }
    });
  }

  Future<void> _handleEmergencyReport() async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "⚠️ Report Emergency",
          style: GoogleFonts.ebGaramond(
              fontWeight: FontWeight.w800, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you facing an issue? This will notify the buyer and seller of a potential delay.",
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Reason (Accident, Bike issue, etc.)",
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Report",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackendService.reportEmergency(
          orderId: widget.order!['_id'],
          volunteerId: widget.order!['volunteerId']['_id'] ?? "",
          lat: _currentVolunteerPos.latitude,
          lng: _currentVolunteerPos.longitude,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.red,
                content: Text("Emergency reported. Assistance is notified.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to report: $e")),
          );
        }
      }
    }
  }

  Future<void> _handleOtpVerification() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a 4-digit OTP")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await BackendService.verifyOtp(
        widget.order?['_id'],
        otp,
      );

      if (mounted) {
        setState(() {
          _currentStatus = response['order']['status'];
          _isVerifying = false;
          _otpController.clear();
          if (_currentStatus == 'delivered') {
            _positionStream?.cancel();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Delivery verified. Order completed!"),
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

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Cancel Rescue",
          style: GoogleFonts.ebGaramond(
              fontWeight: FontWeight.w800, color: Colors.red),
        ),
        content: Text(
          "Are you sure you want to cancel this rescue? This will return the order to the pool and notify everyone.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Keep It",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Cancel",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackendService.cancelOrder(
          widget.order!['_id'],
          "volunteer",
          "Cancelled by volunteer",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Rescue cancelled"), backgroundColor: Colors.red),
          );
          Navigator.pop(context, true);
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

  void _loadLocations() {
    final order = widget.order;
    final listing = order?['listingId'] as Map<String, dynamic>?;

    // Pickup: check order.pickup.geo, then listing.pickupGeo
    final pickupCoords = order?['pickup']?['geo']?['coordinates']
        ?? listing?['pickupGeo']?['coordinates'];
    // Drop: check order.drop.geo, then buyer's geo from order
    final dropCoords = order?['drop']?['geo']?['coordinates'];

    if (pickupCoords is List && pickupCoords.length == 2) {
      pickupLocation = LatLng(
        (pickupCoords[1] as num).toDouble(),
        (pickupCoords[0] as num).toDouble(),
      );
    }

    if (dropCoords is List && dropCoords.length == 2) {
      deliveryLocation = LatLng(
        (dropCoords[1] as num).toDouble(),
        (dropCoords[0] as num).toDouble(),
      );
    }
    _currentVolunteerPos = pickupLocation;
  }

  Future<void> _launchNavigation(LatLng destination) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch navigation")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rescue Details',
          style: GoogleFonts.ebGaramond(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      floatingActionButton: ['picked_up', 'in_transit'].contains(_currentStatus)
          ? FloatingActionButton.extended(
              onPressed: _handleEmergencyReport,
              backgroundColor: Colors.red,
              elevation: 4,
              icon:
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: Text("GET HELP",
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            )
          : null,
      body: Column(
        children: [
          // 🗺️ MAP SECTION
          Container(
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9E7E6B).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentVolunteerPos,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ahara.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickupLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.store,
                          color: Color(0xFFE67E22), size: 30),
                    ),
                    Marker(
                      point: deliveryLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 30),
                    ),
                    Marker(
                      point: _currentVolunteerPos,
                      width: 40,
                      height: 40,
                      child:
                          const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 DETAILS
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _orderSummary(),
                  const SizedBox(height: 24),
                  _pickupCard(),
                  const SizedBox(height: 16),
                  _deliveryCard(),
                  const SizedBox(height: 32),
                  _buildDeliveryOtpSection(),
                  const SizedBox(height: 32),
                  _openInMapsButton(),
                  if (_currentStatus != 'delivered' &&
                      _currentStatus != 'cancelled') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _cancelOrder,
                        child: Text(
                          "Cancel This Rescue",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── UI Sections ─────────────────────────

  Widget _orderSummary() {
    final order = widget.order;
    final listing = order?['listingId'] as Map<String, dynamic>?;
    final foodName = listing?['foodName'] ?? 'Order';
    final quantity = order?['quantityOrdered']?.toString() ?? '-';
    final idText = order?['_id']?.toString();
    final shortId = idText == null
        ? null
        : (idText.length > 8 ? idText.substring(0, 8) : idText);

    final pickupOtp = order?['pickupOtp']?.toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortId != null ? 'RESCUE #$shortId' : 'RESCUE DETAILS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    foodName,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              if (_currentStatus != 'delivered' &&
                  _currentStatus != 'cancelled' &&
                  pickupOtp != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEBD8)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PICKUP CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE67E22),
                        ),
                      ),
                      Text(
                        pickupOtp,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSmallBadge(
                  _currentStatus.replaceAll('_', ' ').toUpperCase(),
                  const Color(0xFFE8F5E9),
                  Colors.green.shade700),
              const SizedBox(width: 12),
              _buildSmallBadge('$quantity ITEMS', const Color(0xFFF3E5F5),
                  Colors.purple.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _pickupCard() {
    final seller = widget.order?['sellerId'];
    final name = seller?['name'] ?? 'The Provider';
    final address =
        widget.order?['pickup']?['addressText'] ?? 'Pickup Address';
    final phone = seller?['phoneNumber'] ?? '-';

    return _addressDetailCard(
      title: "PICKUP FROM",
      name: name,
      address: address,
      phone: phone,
      icon: Icons.store_rounded,
      iconColor: const Color(0xFFE67E22),
    );
  }

  Widget _deliveryCard() {
    final buyer = widget.order?['buyerId'];
    final name = buyer?['name'] ?? 'Recipient';
    final address =
        widget.order?['drop']?['addressText'] ?? 'Delivery Address';
    final phone = buyer?['phoneNumber'] ?? '-';

    return _addressDetailCard(
      title: "DELIVER TO",
      name: name,
      address: address,
      phone: phone,
      icon: Icons.home_rounded,
      iconColor: Colors.green,
    );
  }

  Widget _addressDetailCard({
    required String title,
    required String name,
    required String address,
    required String phone,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "Call Contact",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
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

  Widget _buildDeliveryOtpSection() {
    if (!['picked_up', 'in_transit'].contains(_currentStatus)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ORDER VERIFICATION",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Enter Delivery OTP",
            style: GoogleFonts.ebGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
                  style: GoogleFonts.ebGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: "••••",
                    hintStyle: const TextStyle(
                        color: Colors.white30, letterSpacing: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleOtpVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openInMapsButton() {
    final dest = _currentStatus == 'picked_up' || _currentStatus == 'in_transit'
        ? deliveryLocation
        : pickupLocation;
    final label = _currentStatus == 'picked_up' || _currentStatus == 'in_transit'
        ? "Navigate to Dropoff"
        : "Navigate to Pickup";

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchNavigation(dest),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        icon: const Icon(Icons.directions_rounded),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF9E7E6B).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

