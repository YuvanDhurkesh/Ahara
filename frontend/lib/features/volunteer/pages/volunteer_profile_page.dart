import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../common/pages/landing_page.dart';
import 'package:provider/provider.dart';

class VolunteerProfilePage extends StatefulWidget {
  const VolunteerProfilePage({super.key});

  @override
  State<VolunteerProfilePage> createState() => _VolunteerProfilePageState();
}

class _VolunteerProfilePageState extends State<VolunteerProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _transportMode = 'walk';
  bool _isSaving = false;
  bool _isChangingPassword = false;
  String? _hydratedUserId;

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    _hydrateProfile(auth);

    final mongoUser = auth.mongoUser;
    final mongoProfile = auth.mongoProfile;
    final name = (mongoUser?['name'] ?? 'Volunteer').toString();
    final rating = (mongoProfile?['stats']?['avgRating'] ?? 0).toDouble();
    final totalDeliveries =
        (mongoProfile?['stats']?['totalDeliveriesCompleted'] ?? 0).toString();
    final addressText = _addressController.text.isNotEmpty
        ? _addressController.text
        : (mongoUser?['addressText'] ?? 'Not set').toString();
    final transportLabel = _transportModeLabel(_transportMode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hello, $name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettingsSheet,
                        icon: const Icon(Icons.settings_outlined, size: 28),
                        color: AppColors.textDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'Rating',
                          value: rating.toStringAsFixed(1),
                          icon: Icons.star_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          label: 'Total Deliveries',
                          value: totalDeliveries,
                          icon: Icons.local_shipping_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoTile(
                    label: 'Vehicle Type',
                    value: transportLabel,
                    icon: Icons.directions_bike_outlined,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    label: 'Address',
                    value: addressText,
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hydrateProfile(AppAuthProvider auth) {
    final mongoUser = auth.mongoUser;
    final mongoProfile = auth.mongoProfile;
    final userId = mongoUser?['_id']?.toString();

    if (userId == null || userId == _hydratedUserId) {
      return;
    }

    _nameController.text = (mongoUser?['name'] ?? '').toString();
    _emailController.text =
        (mongoUser?['email'] ?? auth.currentUser?.email ?? '').toString();
    _phoneController.text = (mongoUser?['phone'] ?? '').toString();
    _addressController.text = (mongoUser?['addressText'] ?? '').toString();

    final transport = (mongoProfile?['transportMode'] ?? 'walk')
        .toString()
        .toLowerCase();
    _transportMode = ['walk', 'cycle', 'bike', 'car'].contains(transport)
        ? transport
        : 'walk';

    _hydratedUserId = userId;
  }

  Future<void> _saveChanges() async {
    final auth = context.read<AppAuthProvider>();
    final firebaseUid = auth.currentUser?.uid;

    if (firebaseUid == null) {
      _showSnackBar('Please login again.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await BackendService.updateVolunteerProfile(
        firebaseUid: firebaseUid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressText: _addressController.text.trim(),
        transportMode: _transportMode,
      );

      await auth.refreshMongoUser();

      if (!mounted) return;
      _showSnackBar('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage account',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Menu list
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildSectionHeader('SETTINGS'),
                    _buildMenuItem(
                      ctx,
                      Icons.person_outline,
                      'Account details',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openManageAccountPage();
                      },
                    ),
                    _buildMenuItem(
                      ctx,
                      Icons.lock_outline,
                      'Change password',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showChangePasswordDialog();
                      },
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Log out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openManageAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Manage account',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Account details'),
                const SizedBox(height: 12),
                _textField(label: 'Name', controller: _nameController),
                const SizedBox(height: 12),
                _textField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _textField(
                  label: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _textField(
                  label: 'Location',
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _transportMode,
                  decoration: const InputDecoration(
                    labelText: 'Mode of transport',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'walk', child: Text('Walk')),
                    DropdownMenuItem(value: 'cycle', child: Text('Cycle')),
                    DropdownMenuItem(value: 'bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _transportMode = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            await _saveChanges();
                            if (mounted) Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    label: 'New password',
                    controller: _newPasswordController,
                    obscureText: true,
                    hint: 'Min 6 characters',
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    label: 'Confirm new password',
                    controller: _confirmPasswordController,
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                          setDialogState(() => _isChangingPassword = true);
                          final success = await _changePassword();
                          if (ctx.mounted && success) {
                            Navigator.pop(ctx);
                          }
                          if (ctx.mounted) {
                            setDialogState(() => _isChangingPassword = false);
                          }
                        },
                  child: _isChangingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return false;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please login again.');
        return false;
      }

      await user.updatePassword(newPassword);
      _showSnackBar('Password updated successfully.');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackBar('Please login again and retry password change.');
      } else {
        _showSnackBar(e.message ?? 'Failed to update password.');
      }
      return false;
    } catch (_) {
      _showSnackBar('Failed to update password.');
      return false;
    }
  }

  Future<void> _logout() async {
    await Provider.of<AppAuthProvider>(context, listen: false).logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ───────────────────────── Helpers ─────────────────────────

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _transportModeLabel(String mode) {
    switch (mode) {
      case 'cycle':
        return 'Cycle';
      case 'bike':
        return 'Bike';
      case 'car':
        return 'Car';
      default:
        return 'Walk';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
