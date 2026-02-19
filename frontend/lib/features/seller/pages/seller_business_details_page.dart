import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';

class SellerBusinessDetailsPage extends StatefulWidget {
  const SellerBusinessDetailsPage({super.key});

  @override
  State<SellerBusinessDetailsPage> createState() =>
      _SellerBusinessDetailsPageState();
}

class _SellerBusinessDetailsPageState extends State<SellerBusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _fssaiController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;

  bool _isFssaiValid = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _fssaiController = TextEditingController();
    _contactController = TextEditingController();
    _addressController = TextEditingController();
    _hoursController = TextEditingController();

    _fssaiController.addListener(_validateFssai);
    _hydrateFromBackend();
  }

  void _hydrateFromBackend() {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final mongoProfile = authProvider.mongoProfile;
    final mongoUser = authProvider.mongoUser;

    if (mongoProfile != null) {
      _businessNameController.text = mongoProfile['orgName'] ?? '';
      _fssaiController.text = mongoProfile['fssai']?['number'] ?? '';
      _hoursController.text =
          mongoProfile['pickupHours'] ?? '09:00 AM - 09:00 PM';
      _validateFssai();
    }

    if (mongoUser != null) {
      _contactController.text = mongoUser['phone'] ?? '';
      _addressController.text = mongoUser['addressText'] ?? '';
    }
  }

  void _validateFssai() {
    setState(() {
      _isFssaiValid =
          _fssaiController.text.isEmpty || _fssaiController.text.length == 14;
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _fssaiController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isFssaiValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("FSSAI must be 14 digits")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final firebaseUid = authProvider.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception("User not authenticated");
      }

      await BackendService.updateSellerProfile(
        firebaseUid: firebaseUid,
        name: _businessNameController.text.isNotEmpty
            ? _businessNameController.text
            : null,
        phone: _contactController.text.isNotEmpty
            ? _contactController.text
            : null,
        addressText: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        orgName: _businessNameController.text.isNotEmpty
            ? _businessNameController.text
            : null,
        fssaiNumber: _fssaiController.text.isNotEmpty
            ? _fssaiController.text
            : null,
        pickupHours: _hoursController.text.isNotEmpty
            ? _hoursController.text
            : null,
      );

      if (mounted) {
        // Refresh profile data
        await authProvider.refreshMongoUser();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Business details updated successfully"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Business Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCard([
                    _buildTextField(
                      controller: _businessNameController,
                      label: "Business Name",
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildFssaiField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactController,
                      label: "Contact Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: "Office Address",
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hoursController,
                      label: "Pickup Hours",
                      icon: Icons.access_time_rounded,
                      hint: "e.g. 09:00 AM - 09:00 PM",
                    ),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.textLight.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: AppColors.primary.withOpacity(0.7),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFssaiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FSSAI License Number",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fssaiController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Enter 14-digit number",
            prefixIcon: Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: AppColors.primary.withOpacity(0.7),
            ),
            suffixIcon: _isFssaiValid && _fssaiController.text.isNotEmpty
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
