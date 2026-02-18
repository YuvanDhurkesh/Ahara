/// File: volunteer_profile_page.dart
/// Purpose: Account management and preference configuration for field agents.
/// 
/// Responsibilities:
/// - Manages personal metadata (Name, Vehicle Type, Address)
/// - Implements security protocols for password rotation
/// - Orchestrates session termination and authentication state cleanup
import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../common/pages/landing_page.dart';
import 'package:provider/provider.dart';

/// Profile hub for operational and personal configuration of a volunteer account.
/// 
/// Components:
/// - Interactive form for logistical metadata (Vehicle Type)
/// - Security sub-section for credential management
/// - Logout synchronization via [AppAuthProvider]
class VolunteerProfilePage extends StatefulWidget {
  const VolunteerProfilePage({super.key});

  @override
  State<VolunteerProfilePage> createState() => _VolunteerProfilePageState();
}

class _VolunteerProfilePageState extends State<VolunteerProfilePage> {
  final _nameController = TextEditingController(text: 'Demo Volunteer');
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _vehicleType = 'Bicycle';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.translate('my_profile'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _personalInfoCard(localizations),
                const SizedBox(height: 20),
                _securityCard(localizations),
                const SizedBox(height: 30),
                _logoutButton(context, localizations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Personal Info ─────────────────────────

  Widget _personalInfoCard(AppLocalizations localizations) {
    return _CardWrapper(
      title: localizations.translate('personal_info'),
      child: Column(
        children: [
          _textField(
            label: localizations.translate('full_name'), 
            controller: _nameController
          ),
          const SizedBox(height: 12),
          _textField(
            label: localizations.translate('phone_number'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _textField(
            label: localizations.translate('address'),
            controller: _addressController,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: InputDecoration(
              labelText: localizations.translate('vehicle_type'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'Bicycle', 
                child: Text(localizations.translate('bicycle'))
              ),
              DropdownMenuItem(
                value: 'Bike', 
                child: Text(localizations.translate('bike'))
              ),
              DropdownMenuItem(
                value: 'Car', 
                child: Text(localizations.translate('car'))
              ),
            ],
            onChanged: (value) {
              setState(() {
                _vehicleType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(localizations.translate('save_changes')),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Security ─────────────────────────

  Widget _securityCard(AppLocalizations localizations) {
    return _CardWrapper(
      title: localizations.translate('security'),
      child: Column(
        children: [
          _textField(
            label: localizations.translate('new_password'),
            controller: _newPasswordController,
            obscureText: true,
            hint: 'Min 6 characters',
          ),
          const SizedBox(height: 12),
          _textField(
            label: localizations.translate('confirm_new_password'),
            controller: _confirmPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: Text(localizations.translate('change_password')),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Logout ─────────────────────────

  Widget _logoutButton(BuildContext context, AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          await Provider.of<AppAuthProvider>(context, listen: false).logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            );
          }
        },
        child: Text(
          localizations.translate('logout_btn'),
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ───────────────────────── Card Wrapper ─────────────────────────

class _CardWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
