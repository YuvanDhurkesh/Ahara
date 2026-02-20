import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
  LatLng pickupLocation = const LatLng(28.6139, 77.2090); // Delhi
  LatLng deliveryLocation = const LatLng(28.5355, 77.3910); // Noida
  LatLng _currentVolunteerPos = const LatLng(28.6139, 77.2090);

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
      setState(() {
        _currentVolunteerPos = LatLng(position.latitude, position.longitude);
      });
      
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
        title: const Text("⚠️ Report Emergency"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you facing an issue? This will notify the buyer and seller of a potential delay."),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Reason (Accident, Bike issue, etc.)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Report", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackendService.reportEmergency(
          orderId: widget.order!['_id'],
          volunteerId: widget.order!['volunteerId']['_id'] ?? "", // Assuming it's populated or we have it
          lat: _currentVolunteerPos.latitude,
          lng: _currentVolunteerPos.longitude,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text("Emergency reported. Assistance is being notified.")),
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
        title: const Text("Cancel Rescue", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to cancel this rescue? This will return the order to the pool and notify the buyer/seller."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep Rescue")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cancel Anyway", style: TextStyle(color: Colors.white)),
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
            const SnackBar(content: Text("Rescue cancelled"), backgroundColor: Colors.red),
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
    final pickupCoords = order?['pickup']?['geo']?['coordinates'];
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
    _currentVolunteerPos = pickupLocation; // Start at pickup
  }

  Future<void> _launchNavigation(LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: ['picked_up', 'in_transit'].contains(_currentStatus) 
        ? FloatingActionButton.extended(
            onPressed: _handleEmergencyReport,
            backgroundColor: Colors.red,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            label: const Text("HELP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
      body: Column(
        children: [
          // 🗺️ OPEN STREET MAP
          SizedBox(
            height: 280,
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
                      child: const Icon(Icons.store, color: AppColors.primary, size: 30),
                    ),
                    Marker(
                      point: deliveryLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.home, color: Colors.red, size: 30),
                    ),
                    Marker(
                      point: _currentVolunteerPos,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 DETAILS
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _orderSummary(),
                  const SizedBox(height: 16),
                  _pickupCard(),
                  const SizedBox(height: 16),
                  _deliveryCard(),
                  const SizedBox(height: 24),
                  _buildDeliveryOtpSection(),
                  const SizedBox(height: 24),
                  _openInMapsButton(),
                  if (_currentStatus != 'delivered' && _currentStatus != 'cancelled') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _cancelOrder,
                        child: const Text(
                          "Cancel Rescue",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(16),
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
                    shortId != null ? 'Order $shortId' : 'Order Details',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items: $foodName ($quantity)',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ],
              ),
              if (['placed', 'volunteer_assigned', 'volunteer_accepted'].contains(_currentStatus) && pickupOtp != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "PICKUP OTP",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        pickupOtp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
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
              const Text(
                "Secure Delivery",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Ask the Buyer for their 4-digit Delivery OTP once you reach the drop location.",
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
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
                    hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Verify", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickupCard() {
    final order = widget.order;
    final listing = order?['listingId'] as Map<String, dynamic>?;
    final seller = order?['sellerId'] as Map<String, dynamic>?;
    final pickupAddress =
        order?['pickup']?['addressText'] ?? listing?['pickupAddressText'];

    return _locationCard(
      title: 'Pickup Location',
      name: seller?['name']?.toString() ?? 'Pickup Point',
      address: pickupAddress?.toString() ?? 'Pickup address',
      timeLabel: 'Pickup by',
      time: listing?['pickupWindow']?['to']?.toString() ?? 'Scheduled time',
    );
  }

  Widget _deliveryCard() {
    final order = widget.order;
    final buyer = order?['buyerId'] as Map<String, dynamic>?;
    final dropAddress = order?['drop']?['addressText'];

    return _locationCard(
      title: 'Delivery Location',
      name: buyer?['name']?.toString() ?? 'Recipient',
      address: dropAddress?.toString() ?? 'Delivery address',
      timeLabel: 'Deliver by',
      time: order?['timeline']?['deliveredAt']?.toString() ?? 'Scheduled time',
    );
  }

  Widget _locationCard({
    required String title,
    required String name,
    required String address,
    required String timeLabel,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(address, style: const TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text('$timeLabel: $time'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _contactButton(Icons.call, 'Call'),
              const SizedBox(width: 12),
              _contactButton(Icons.message, 'Text'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _openInMapsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final target = ['placed', 'volunteer_assigned', 'volunteer_accepted'].contains(_currentStatus)
              ? pickupLocation
              : deliveryLocation;
          _launchNavigation(target);
        },
        icon: const Icon(Icons.navigation, color: Colors.white),
        label: const Text('Open in Navigation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
      ],
    );
  }
}

