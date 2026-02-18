import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context)!;
    final auth = context.watch<AppAuthProvider>();
    _hydrateProfile(auth);

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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textDark,
            ),
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [_personalInfoCard(localizations)]),
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
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          _textField(
            label: localizations.translate('email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
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
            value: _transportMode,
            decoration: InputDecoration(
              labelText: localizations.translate('vehicle_type'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'walk', child: const Text('Walk')),
              DropdownMenuItem(
                value: 'cycle',
                child: Text(localizations.translate('bicycle')),
              ),
              DropdownMenuItem(
                value: 'bike',
                child: Text(localizations.translate('bike')),
              ),
              DropdownMenuItem(
                value: 'car',
                child: Text(localizations.translate('car')),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _transportMode = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
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
                  : Text(localizations.translate('save_changes')),
            ),
          ),
        ],
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
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(localizations.translate('change_password')),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showChangePasswordDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    localizations.translate('logout_btn'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
              title: Text(
                AppLocalizations.of(context)!.translate('change_password'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    label: AppLocalizations.of(
                      context,
                    )!.translate('new_password'),
                    controller: _newPasswordController,
                    obscureText: true,
                    hint: 'Min 6 characters',
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    label: AppLocalizations.of(
                      context,
                    )!.translate('confirm_new_password'),
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
