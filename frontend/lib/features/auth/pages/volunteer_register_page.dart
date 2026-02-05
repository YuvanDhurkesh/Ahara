import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';

class VolunteerRegisterPage extends StatefulWidget {
  const VolunteerRegisterPage({super.key});

  @override
  State<VolunteerRegisterPage> createState() => _VolunteerRegisterPageState();
}

class _VolunteerRegisterPageState extends State<VolunteerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedTransport;
  DateTime? _selectedDate;
  bool _obscurePassword = true;

  final List<String> _transportModes = ['Bike', 'Cycle', 'Car', 'Van', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  bool _isEligible(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  @override
  Widget build(BuildContext context) {
    // Show DOB field for everything except 'Cycle'
    final bool showDOB =
        _selectedTransport != null && _selectedTransport != 'Cycle';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Join as a Volunteer",
                style: GoogleFonts.lora(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Offer your time and help distribute food surplus to the neighborhood.",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Name Field
              _buildLabel("FULL NAME"),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "Enter your full name",
                  Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter your name";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Mode of Transport Dropdown
              _buildLabel("MODE OF TRANSPORT"),
              DropdownButtonFormField<String>(
                value: _selectedTransport,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                decoration: _buildInputDecoration(
                  "Select transport mode",
                  Icons.directions_bike_outlined,
                ),
                items: _transportModes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
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
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please select transport mode";
                  return null;
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textLight.withOpacity(0.6),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(height: 28),

              // Conditional DOB Field
              if (showDOB) ...[
                _buildLabel("DATE OF BIRTH"),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    "DD/MM/YYYY",
                    Icons.calendar_today_outlined,
                  ),
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please select your date of birth";
                    if (_selectedDate != null && !_isEligible(_selectedDate!)) {
                      return "You must be 18 years or older to register";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
              ],

              // Email Field
              _buildLabel("EMAIL ADDRESS"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "name@example.com",
                  Icons.email_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter your email";
                  if (!value.contains('@')) return "Please enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Contact Number Field
              _buildLabel("CONTACT NUMBER"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "Enter your phone number",
                  Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter your number";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Password Field
              _buildLabel("PASSWORD"),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "At least 6 characters",
                  Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textLight.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter a password";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process registration
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Create Volunteer Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already registered? ",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark.withOpacity(0.85),
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textLight.withOpacity(0.4),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
