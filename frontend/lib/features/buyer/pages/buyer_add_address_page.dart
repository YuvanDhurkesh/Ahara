import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../location/pages/location_picker_page.dart';

class BuyerAddAddressPage extends StatefulWidget {
  const BuyerAddAddressPage({super.key});

  @override
  State<BuyerAddAddressPage> createState() => _BuyerAddAddressPageState();
}

class _BuyerAddAddressPageState extends State<BuyerAddAddressPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  Map<String, double>? _coordinates;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      final addressText =
          "${_houseController.text}, ${_streetController.text}, ${_areaController.text}, Bangalore - ${_pincodeController.text}";
      
      Navigator.pop(context, {
        "addressText": addressText,
        "geo": {
          "type": "Point",
          "coordinates": _coordinates != null 
              ? [_coordinates!['longitude'], _coordinates!['latitude']]
              : [77.5946, 12.9716] // Fallback to Bangalore center
        }
      });
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _streetController.text = result.address;
        _pincodeController.text = result.pincode;
        _coordinates = {
          'latitude': result.latitude,
          'longitude': result.longitude,
        };
        // Switch to form tab to show auto-filled results
        _tabController.animateTo(0);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location updated from map!")),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Address",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Address Form"),
                Tab(text: "Select on Map"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForm(),
                _buildMapSelector(),
              ],
            ),
          ),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildLocationButton(),
            const SizedBox(height: 32),
            _buildTextField("House/Flat Number", _houseController, "e.g. 123, 4th Floor"),
            const SizedBox(height: 20),
            _buildTextField("Street / Landmark", _streetController, "e.g. Near Rose Park"),
            const SizedBox(height: 20),
            _buildTextField("Area", _areaController, "e.g. Koramangala"),
            const SizedBox(height: 20),
            _buildTextField("Pincode", _pincodeController, "e.g. 560034", keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return InkWell(
      onTap: _openMapPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              "Pin Location on Map",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight.withOpacity(0.6))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildMapSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 80, color: AppColors.primary.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              "Precise Address Selection",
              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Pin your exact location on the map to help our volunteers find you easily.",
              style: GoogleFonts.inter(color: AppColors.textLight, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text("Open Interactive Map", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: ElevatedButton(
        onPressed: _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text("Save Address", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
