import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/styles/app_colors.dart';

class VolunteerOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic>? order;

  const VolunteerOrderDetailPage({super.key, this.order});

  @override
  State<VolunteerOrderDetailPage> createState() =>
      _VolunteerOrderDetailPageState();
}

class _VolunteerOrderDetailPageState extends State<VolunteerOrderDetailPage> {
  late GoogleMapController _mapController;

  // Dummy coordinates (replace later with real ones)
  LatLng pickupLocation = const LatLng(28.6139, 77.2090); // Delhi
  LatLng deliveryLocation = const LatLng(28.5355, 77.3910); // Noida

  @override
  void initState() {
    super.initState();
    _loadLocations();
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
    final order = widget.order;
    final listing = order?['listingId'] as Map<String, dynamic>?;
    final foodName = listing?['foodName'] ?? 'Order';
    final quantity = order?['quantityOrdered']?.toString() ?? '-';
    final idText = order?['_id']?.toString();
    final shortId = idText == null
        ? null
        : (idText.length > 8 ? idText.substring(0, 8) : idText);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shortId != null ? 'Order $shortId' : 'Order Details',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Items: $foodName ($quantity)',
            style: const TextStyle(color: AppColors.textLight),
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
