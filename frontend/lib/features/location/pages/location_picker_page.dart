import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/styles/app_colors.dart';

class LocationResult {
  final String address;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? locality;
  final String? subLocality;

  LocationResult({
    required this.address,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.locality,
    this.subLocality,
  });
}

class LocationPickerPage extends StatefulWidget {
  final String? initialAddress;
  final String? initialPincode;

  const LocationPickerPage({
    super.key,
    this.initialAddress,
    this.initialPincode,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final MapController _mapController = MapController();
  
  LatLng _currentSelectedPos = const LatLng(12.9716, 77.5946); // Bengaluru
  bool _isLocating = false;
  bool _isReverseGeocoding = false;
  String? _lastLocality;
  String? _lastSubLocality;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? "";
    _pincodeController.text = widget.initialPincode ?? "";
    _determinePosition();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Denied';
      }
      
      Position position = await Geolocator.getCurrentPosition();
      final newPos = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentSelectedPos = newPos;
        _isLocating = false;
      });

      _mapController.move(newPos, 16);
      _reverseGeocode(newPos.latitude, newPos.longitude);
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    
    _addressController.text = "Locating...";
    _pincodeController.text = "...";

    try {
      debugPrint("Reverse Geocoding: $lat, $lon");
      
      // Try native geocoding first
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          debugPrint("Native Placemark: ${p.toString()}");
          
          List<String> parts = [];
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street) parts.add(p.name!);
          if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
          
          final address = parts.where((s) => s.isNotEmpty).join(", ");
          if (address.isNotEmpty) {
            if (mounted) {
              setState(() {
                _addressController.text = address;
                _pincodeController.text = p.postalCode ?? "";
                _lastLocality = p.locality;
                _lastSubLocality = p.subLocality;
              });
              return; // Success
            }
          }
        }
      } catch (e) {
        debugPrint("Native Geocoding failed, trying Nominatim: $e");
      }

      // Fallback: Use Nominatim (OSM Geocoder)
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'AharaApp/1.0 (com.ahara.app)',
        'Accept-Language': 'en',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        final addressData = data['address'] as Map<String, dynamic>?;
        final postcode = addressData?['postcode'] as String?;

        if (mounted && displayName != null) {
          setState(() {
            _addressController.text = displayName.split(", ").take(4).join(", ");
            _pincodeController.text = postcode ?? "";
            _lastLocality = addressData?['suburb'] ?? addressData?['city_district'];
            _lastSubLocality = addressData?['neighbourhood'] ?? addressData?['allotments'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
             _addressController.text = "Location Selected (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})";
             _pincodeController.text = "";
          });
        }
      }
    } catch (e) {
      debugPrint("All Geocoding methods failed: $e");
      if (mounted) {
        setState(() {
          _addressController.text = "Location Selected";
          _pincodeController.text = "";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Select Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentSelectedPos,
                    initialZoom: 15,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        _currentSelectedPos = position.center!;
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _reverseGeocode(_currentSelectedPos.latitude, _currentSelectedPos.longitude);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ahara.app',
                    ),
                  ],
                ),
                
                // Static Center Pin
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_on, color: AppColors.primary, size: 45),
                  ),
                ),

                // Loader for Geocoding
                if (_isReverseGeocoding)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text("Fetching address...", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),

                // My Location Button
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    onPressed: _determinePosition,
                    backgroundColor: Colors.white,
                    mini: true,
                    child: _isLocating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Input Sheet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "Address",
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pincodeController,
                  decoration: InputDecoration(
                    labelText: "Pincode",
                    prefixIcon: const Icon(Icons.pin_drop_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, LocationResult(
                        address: _addressController.text,
                        pincode: _pincodeController.text,
                        latitude: _currentSelectedPos.latitude,
                        longitude: _currentSelectedPos.longitude,
                        locality: _lastLocality,
                        subLocality: _lastSubLocality,
                      ));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Confirm Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
