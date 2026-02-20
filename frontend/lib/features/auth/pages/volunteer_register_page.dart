import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';
import '../../../shared/widgets/phone_input_field.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../data/services/backend_service.dart';
import 'otp_verification_page.dart';
import 'volunteer_verification_page.dart';
import '../../location/pages/location_picker_page.dart';

class VolunteerRegisterPage extends StatefulWidget {
  const VolunteerRegisterPage({super.key});

  @override
  State<VolunteerRegisterPage> createState() =>
      _VolunteerRegisterPageState();
}

class _VolunteerRegisterPageState
    extends State<VolunteerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();
  final _aadhaarController = TextEditingController();

  String? _selectedTransport;
  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  bool _isAadhaarVerified = false;
  LocationResult? _selectedLocation;

  final List<String> _transportModes = [
    'Car',
    'Bike',
    'Cycle',
    'Walk'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number first")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AppAuthProvider>();
      await auth.sendOtp(_phoneController.text.trim());

      if (mounted) {
        setState(() => _isLoading = false);
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationPage(
              phoneNumber: _phoneController.text.trim(),
              isRegistration: true,
            ),
          ),
        );

        if (verified == true) {
          if (mounted) {
            setState(() => _isPhoneVerified = true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: $e")),
        );
      }
    }
  }

  Future<void> _verifyIdentity() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your phone number first")),
      );
      return;
    }

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VolunteerVerificationPage(
          phoneNumber: _phoneController.text.trim(),
          name: _nameController.text.trim(),
        ),
      ),
    );

    if (success == true) {
      setState(() => _isAadhaarVerified = true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  bool _isEligible(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month &&
            today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  Future<void> _registerVolunteer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your contact number with OTP first")),
      );
      return;
    }

    if (!_isAadhaarVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhaar verification is required for volunteers")),
      );
      return;
    }

    if ((_selectedTransport == 'Car' ||
            _selectedTransport == 'Bike') &&
        _selectedDate != null) {
      if (!_isEligible(_selectedDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "You must be 18+ to volunteer with Car/Bike"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();

    try {
      final user = await auth.registerUser(
        role: 'volunteer',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        location: _selectedLocation != null
            ? {
                "address": _selectedLocation!.address,
                "coordinates": [
                  _selectedLocation!.longitude,
                  _selectedLocation!.latitude
                ]
              }
            : _locationController.text.trim().isEmpty
                ? 'Not specified'
                : _locationController.text.trim(),
        transportMode: _selectedTransport,
        dateOfBirth: _selectedDate?.toIso8601String(),
        language:
            context.read<LanguageProvider>().locale.languageCode,
      );

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Registration successful! Please login."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e.message ?? "Registration failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showDOB =
        _selectedTransport == 'Car' ||
            _selectedTransport == 'Bike';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Join as a Volunteer",
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Offer your time and help distribute food surplus.",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildLabel("FULL NAME"),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 50,
                    decoration:
                        const InputDecoration(
                      hintText:
                          "Enter your full name",
                      prefixIcon:
                          Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null ||
                                value.isEmpty
                            ? "Please enter your name"
                            : null,
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("MODE OF TRANSPORT"),
                  DropdownButtonFormField<String>(
                    value: _selectedTransport,
                    hint: Text(
                      "Select transport mode",
                      style: GoogleFonts.inter(
                        color: AppColors.textLight.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    items: _transportModes.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(
                          mode,
                          style: GoogleFonts.inter(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTransport = value;
                        if (value == 'Cycle') {
                          _selectedDate = null;
                          _dobController.clear();
                        }
                      });
                    },
                    validator: (value) =>
                        value == null
                            ? "Please select transport mode"
                            : null,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (showDOB) ...[
                    _buildLabel("DATE OF BIRTH"),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        hintText:
                            "DD/MM/YYYY",
                        prefixIcon: Icon(Icons
                            .calendar_today_outlined),
                      ),
                      onTap: () =>
                          _selectDate(context),
                      validator: (value) =>
                          value == null ||
                                  value.isEmpty
                              ? "Please select your date of birth"
                              : null,
                    ),
                    const SizedBox(height: 28),
                  ],

                  _buildLabel("EMAIL ADDRESS"),
                  TextFormField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(
                      hintText:
                          "name@example.com",
                      prefixIcon: Icon(Icons
                          .email_outlined),
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null ||
                                !value.contains('@')
                            ? "Enter valid email"
                            : null,
                  ),

                  const SizedBox(height: 28),

                  PhoneInputField(
                    controller:
                        _phoneController,
                    label: "CONTACT NUMBER",
                    hintText: "12345 67890",
                    maxLength: 10,
                  ),

                  if (!_isPhoneVerified) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _verifyPhone,
                        icon: const Icon(Icons.verified_user_outlined, size: 18),
                        label: const Text("Verify Phone with OTP"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text(
                          "Phone Verified",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  _buildLabel("LOCATION"),
                  TextFormField(
                    controller: _locationController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push<LocationResult>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerPage(
                            initialAddress: _locationController.text,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedLocation = result;
                          _locationController.text = result.address;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "Select location on map",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      suffixIcon: Icon(Icons.map_outlined),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("IDENTITY VERIFICATION (AADHAAR)"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isAadhaarVerified ? Colors.green : AppColors.textLight.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isAadhaarVerified ? Icons.check_circle : Icons.security_outlined,
                              color: _isAadhaarVerified ? Colors.green : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isAadhaarVerified ? "Aadhaar e-KYC Verified" : "Verify Aadhaar Details",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isAadhaarVerified ? Colors.green : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        if (!_isAadhaarVerified)
                          TextButton(
                            onPressed: _verifyIdentity,
                            child: const Text("Start"),
                          )
                        else
                          const Icon(Icons.verified, color: Colors.green, size: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("PASSWORD"),
                  TextFormField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    decoration:
                        InputDecoration(
                      hintText:
                          "At least 6 characters",
                      prefixIcon:
                          const Icon(Icons
                              .lock_outline),
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() =>
                                _obscurePassword =
                                    !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        value == null ||
                                value.length < 6
                            ? "Minimum 6 characters"
                            : null,
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _registerVolunteer,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Create Volunteer Account"),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium),
    );
  }
}
