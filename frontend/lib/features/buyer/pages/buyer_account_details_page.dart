import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';

class BuyerAccountDetailsPage extends StatefulWidget {
  const BuyerAccountDetailsPage({super.key});

  @override
  State<BuyerAccountDetailsPage> createState() =>
      _BuyerAccountDetailsPageState();
}

class _BuyerAccountDetailsPageState extends State<BuyerAccountDetailsPage> {
  // Editable controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _genderController = TextEditingController();
  final _dietaryController = TextEditingController();
  final _birthdayController = TextEditingController();

  // Read-only display values (email & phone)
  String _emailDisplay = '';
  String _phoneDisplay = '';

  String? _lastHydratedUserId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AppAuthProvider>();
      if (auth.mongoUser == null && auth.currentUser != null) {
        auth.refreshMongoUser();
      }
    });
  }

  void _hydrateFromBackend(AppAuthProvider auth) {
    final mongoUser = auth.mongoUser;
    final mongoProfile = auth.mongoProfile;
    final currentUserId = mongoUser?['_id']?.toString();

    if (currentUserId == null || currentUserId == _lastHydratedUserId) {
      return;
    }

    _nameController.text = (mongoUser?['name'] ?? '').toString();
    _locationController.text = (mongoUser?['addressText'] ?? '').toString();
    _genderController.text = (mongoUser?['gender'] ?? '').toString();

    _emailDisplay = (mongoUser?['email'] ?? auth.currentUser?.email ?? '')
        .toString();
    _phoneDisplay = (mongoUser?['phone'] ?? '').toString();

    final dietary = mongoProfile?['dietaryPreferences'];
    if (dietary is List) {
      _dietaryController.text = dietary.map((e) => e.toString()).join(', ');
    }

    _lastHydratedUserId = currentUserId;
  }

  Future<void> _save() async {
    final auth = context.read<AppAuthProvider>();
    final firebaseUid = auth.currentUser?.uid;
    if (firebaseUid == null) return;

    setState(() => _isSaving = true);

    try {
      final rawDietary = _dietaryController.text.trim();
      final List<String> dietaryList = rawDietary.isEmpty
          ? []
          : rawDietary
                .split(',')
                .map((e) => e.trim().toLowerCase().replaceAll(' ', '_'))
                .where((e) => e.isNotEmpty)
                .toList();

      await BackendService.updateBuyerProfile(
        firebaseUid: firebaseUid,
        name: _nameController.text.trim(),
        addressText: _locationController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        dietaryPreferences: dietaryList,
      );

      // Force re-hydration on next build
      _lastHydratedUserId = null;
      await auth.refreshMongoUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Profile saved successfully",
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save: ${e.toString()}",
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _genderController.dispose();
    _dietaryController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    _hydrateFromBackend(auth);

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
              _buildEditableRow("Name", _nameController),
              _buildDivider(),
              _buildReadOnlyRow("Email", _emailDisplay),
              _buildDivider(),
              _buildReadOnlyRow("Phone number", _phoneDisplay),
              _buildDivider(),
              _buildEditableRow("Location", _locationController),
              _buildDivider(),
              _buildEditableRow("Gender", _genderController, optional: true),
              _buildDivider(),
              _buildEditableRow(
                "Dietary preferences",
                _dietaryController,
                optional: true,
                hint: "e.g. vegetarian, vegan",
              ),
              _buildDivider(),
              _buildEditableRow(
                "Birthday",
                _birthdayController,
                optional: true,
                readOnly: true,
              ),
            ]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Email and phone number cannot be changed here.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionLabel("DELIVERY ADDRESSES"),
            _buildSectionCard([
              _buildAddressRow("Home"),
              _buildDivider(),
              _buildAddressRow("Work"),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Save changes",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
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

  /// A fully editable text field row.
  Widget _buildEditableRow(
    String label,
    TextEditingController controller, {
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
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
                hintText: hint ?? (optional ? "Add" : "Enter $label"),
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

  /// A non-editable display row for locked fields (email, phone).
  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textDark.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: AppColors.textLight.withOpacity(0.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? "—" : value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textDark.withOpacity(0.4),
                fontWeight: FontWeight.w600,
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
