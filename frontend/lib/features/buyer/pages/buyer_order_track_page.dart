import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_orders.dart';

class BuyerOrderTrackPage extends StatefulWidget {
  final MockOrder order;

  const BuyerOrderTrackPage({super.key, required this.order});

  @override
  State<BuyerOrderTrackPage> createState() => _BuyerOrderTrackPageState();
}

class _BuyerOrderTrackPageState extends State<BuyerOrderTrackPage> {
  final MapController _mapController = MapController();
  late LatLng _volunteerPos;
  final LatLng _deliveryPos = const LatLng(12.9352, 77.6309); // Koramangala
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start volunteer somewhere nearby
    _volunteerPos = const LatLng(12.9452, 77.6209);
    _startLiveTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Slowly move volunteer towards delivery position
          double newLat = _volunteerPos.latitude + (_deliveryPos.latitude - _volunteerPos.latitude) * 0.1;
          double newLon = _volunteerPos.longitude + (_deliveryPos.longitude - _volunteerPos.longitude) * 0.1;
          _volunteerPos = LatLng(newLat, newLon);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Track Order",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // OSM Map
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _volunteerPos,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ahara.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_volunteerPos, _deliveryPos],
                        color: AppColors.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _deliveryPos,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                      Marker(
                        point: _volunteerPos,
                        width: 50,
                        height: 50,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                          child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Estimated Delivery",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.deliveryTime ?? "Unknown",
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 32),

                  _buildTimelineTile(
                    title: "Order Confirmed",
                    subtitle: "Your order has been received",
                    time: "12:30 PM",
                    isActive: true,
                    isCompleted: true,
                    isFirst: true,
                  ),
                  _buildTimelineTile(
                    title: "Preparing",
                    subtitle: "Restaurant is packing your food",
                    time: "12:45 PM",
                    isActive: true,
                    isCompleted: true,
                  ),
                  _buildTimelineTile(
                    title: "Out for Delivery",
                    subtitle: "${widget.order.volunteerName} is on the way",
                    time: "1:00 PM",
                    isActive: true,
                    isCompleted: false,
                  ),
                  _buildTimelineTile(
                    title: "Arrived",
                    subtitle: "Enjoy your food!",
                    time: "",
                    isActive: false,
                    isCompleted: false,
                    isLast: true,
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Delivery Partner",
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.order.volunteerName ?? "Volunteer",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.order.volunteerRating}",
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.phone, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required String time,
    bool isActive = false,
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: isCompleted ? Colors.black : Colors.grey.shade200),
                  ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted ? Colors.black : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive || isCompleted ? Colors.black : Colors.grey.shade300, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: isCompleted ? Colors.black : Colors.grey.shade200),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isActive || isCompleted ? Colors.black : Colors.grey)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
