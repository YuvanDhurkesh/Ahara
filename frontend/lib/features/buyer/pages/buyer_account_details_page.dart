import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

class BuyerAccountDetailsPage extends StatefulWidget {
  const BuyerAccountDetailsPage({super.key});

  @override
  State<BuyerAccountDetailsPage> createState() =>
      _BuyerAccountDetailsPageState();
}

class _BuyerAccountDetailsPageState extends State<BuyerAccountDetailsPage> {
  // Controllers
  final _nameController = TextEditingController(text: "");
  final _emailController = TextEditingController(
    text: "harishreedevi58@gmail.com",
  );
  final _phoneController = TextEditingController(text: "");
  final _countryController = TextEditingController(text: "United States");
  final _genderController = TextEditingController(text: "");
  final _dietaryController = TextEditingController(text: "");
  final _birthdayController = TextEditingController(
    text: "",
  ); // Could use DatePicker

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _genderController.dispose();
    _dietaryController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Slightly warmer cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Account details",
          style: GoogleFonts.lora(
            // Changed to Lora for consistent "warm/fancy" header
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("PERSONAL INFO"),
            _buildSectionCard([
              _buildInputRow("Name", _nameController),
              _buildDivider(),
              _buildInputRow(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildDivider(),
              _buildInputRow(
                "Phone number",
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildDivider(),
              _buildInputRow("Country", _countryController),
              _buildDivider(),
              _buildInputRow("Gender", _genderController, optional: true),
              _buildDivider(),
              _buildInputRow(
                "Dietary preferences",
                _dietaryController,
                optional: true,
              ),
              _buildDivider(),
              _buildInputRow("Birthday", _birthdayController, readOnly: true),
            ]),
            const SizedBox(height: 32),
            _buildSectionLabel("DELIVERY ADDRESSES"),
            _buildSectionCard([
              _buildAddressRow("Home"),
              _buildDivider(),
              _buildAddressRow("Work"),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0A080).withOpacity(0.08), // Warmer shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.background,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller, {
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textDark.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: optional ? "Add" : "Enter $label",
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textLight.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textLight.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
