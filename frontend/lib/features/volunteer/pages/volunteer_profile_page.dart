import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _personalInfoCard(),
            const SizedBox(height: 20),
            _securityCard(),
            const SizedBox(height: 30),
            _logoutButton(context),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Personal Info ─────────────────────────

  Widget _personalInfoCard() {
    return _CardWrapper(
      title: 'Personal Information',
      child: Column(
        children: [
          _textField(label: 'Full Name', controller: _nameController),
          const SizedBox(height: 12),
          _textField(
            label: 'Phone Number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _textField(
            label: 'Address',
            controller: _addressController,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Bicycle', child: Text('Bicycle')),
              DropdownMenuItem(value: 'Bike', child: Text('Bike')),
              DropdownMenuItem(value: 'Car', child: Text('Car')),
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
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Security ─────────────────────────

  Widget _securityCard() {
    return _CardWrapper(
      title: 'Security',
      child: Column(
        children: [
          _textField(
            label: 'New Password',
            controller: _newPasswordController,
            obscureText: true,
            hint: 'Min 6 characters',
          ),
          const SizedBox(height: 12),
          _textField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Change Password'),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Logout ─────────────────────────

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          // Clear session here later (Provider / SecureStorage)

          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // 👈 your app default / landing route
            (route) => false,
          );
        },
        child: const Text(
          'Logout',
          style: TextStyle(
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
