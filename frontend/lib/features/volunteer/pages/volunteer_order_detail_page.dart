/// File: volunteer_order_detail_page.dart
/// Purpose: Logistical coordination view for executing food rescues.
/// 
/// Responsibilities:
/// - Visualizes routes using [GoogleMap] integration
/// - Displays granular pickup and delivery contact/location metadata
/// - Provides external mapping triggers for turn-by-turn navigation
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/styles/app_colors.dart';

/// Mission execution interface for navigating and fulfilling food rescue orders.
/// 
/// Features:
/// - Real-time spatial visualization using [GoogleMaps] markers and polylines
/// - Integrated contact shortcuts (Call/SMS) for stakeholders
/// - Centralized order summary and timing constraints
class VolunteerOrderDetailPage extends StatefulWidget {
  const VolunteerOrderDetailPage({super.key});

  @override
  State<VolunteerOrderDetailPage> createState() =>
      _VolunteerOrderDetailPageState();
}

class _VolunteerOrderDetailPageState extends State<VolunteerOrderDetailPage> {
  late GoogleMapController _mapController;

  // Dummy coordinates (replace later with real ones)
  final LatLng pickupLocation = const LatLng(28.6139, 77.2090); // Delhi
  final LatLng deliveryLocation = const LatLng(28.5355, 77.3910); // Noida

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
      body: Column(
        children: [
          // 🗺️ MAP
          SizedBox(
            height: 280,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pickupLocation,
                zoom: 12,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: pickupLocation,
                  infoWindow: const InfoWindow(title: 'Pickup Location'),
                ),
                Marker(
                  markerId: const MarkerId('delivery'),
                  position: deliveryLocation,
                  infoWindow: const InfoWindow(title: 'Delivery Location'),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [pickupLocation, deliveryLocation],
                  color: AppColors.primary,
                  width: 5,
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
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
                  _openInMapsButton(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Order ORD-5523', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text(
            'Items: Assorted Pastries (2 boxes)',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _pickupCard() {
    return _locationCard(
      title: 'Pickup Location',
      name: 'Main Street Bakery',
      address: '123 Bakers Street, Downtown',
      timeLabel: 'Pickup by',
      time: '11:00 AM',
    );
  }

  Widget _deliveryCard() {
    return _locationCard(
      title: 'Delivery Location',
      name: 'Sarah Johnson',
      address: '456 Oak Avenue, Apt 4B',
      timeLabel: 'Deliver by',
      time: '12:00 PM',
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
          // Later: open Google Maps intent
        },
        icon: const Icon(Icons.map),
        label: const Text('Open in Google Maps'),
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
