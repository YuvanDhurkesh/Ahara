import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

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

  // Map state
  Offset _markerPosition = const Offset(150, 150);
  bool _isLoadingLocation = false;

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
    if (_tabController.index == 0) {
      if (_formKey.currentState!.validate()) {
        final address =
            "${_houseController.text}, ${_streetController.text}, ${_areaController.text}, Bangalore - ${_pincodeController.text}";
        Navigator.pop(context, address);
      }
    } else {
      // For mock map, return a static address based on "selection"
      Navigator.pop(context, "Selected Location, Whitefield, Bangalore");
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    _houseController.text = "Flat 402, Green Meadows";
    _streetController.text = "12th Cross, 8th Main";
    _areaController.text = "Koramangala";
    _pincodeController.text = "560034";
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Location auto-filled!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Address",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
              children: [_buildForm(), _buildMapSelector()],
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
            _buildTextField(
              "House/Flat Number",
              _houseController,
              "e.g. 123, 4th Floor",
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Street / Landmark",
              _streetController,
              "e.g. Near Rose Park",
            ),
            const SizedBox(height: 20),
            _buildTextField("Area", _areaController, "e.g. Koramangala"),
            const SizedBox(height: 20),
            _buildTextField(
              "Pincode",
              _pincodeController,
              "e.g. 560034",
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return InkWell(
      onTap: _useCurrentLocation,
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
            _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
            const SizedBox(width: 12),
            Text(
              "Use Current Location",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildMapSelector() {
    return Stack(
      children: [
        // Mock Map Background (Grid)
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF9F6F1),
            child: CustomPaint(painter: MapGridPainter()),
          ),
        ),
        // Draggable Marker
        Positioned(
          left: _markerPosition.dx - 20,
          top: _markerPosition.dy - 40,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _markerPosition += details.delta;
              });
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Pick Location",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
        // Map Overlay Info
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Move the pin to select location",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Confirm Selected Address",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some mock buildings
    final blockPaint = Paint()..color = Colors.grey.withOpacity(0.05);
    canvas.drawRect(const Rect.fromLTWH(80, 80, 80, 60), blockPaint);
    canvas.drawRect(const Rect.fromLTWH(200, 150, 60, 100), blockPaint);
    canvas.drawRect(const Rect.fromLTWH(40, 300, 120, 40), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
