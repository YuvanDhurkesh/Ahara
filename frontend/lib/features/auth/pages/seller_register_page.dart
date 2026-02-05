import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fssaiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedType;
  bool _obscurePassword = true;

  final List<String> _sellerTypes = [
    'Restaurant',
    'Cloud Kitchen',
    'Cafe',
    'Event Management',
    'Catering Service',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _fssaiController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                "Join as a Seller",
                style: GoogleFonts.lora(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Partner with us to reduce food waste and serve your local community.",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Business Name Field
              _buildLabel("BUSINESS NAME"),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "E.g. Sunshine Delights",
                  Icons.business_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter business name";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Business Type Dropdown
              _buildLabel("BUSINESS TYPE"),
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                decoration: _buildInputDecoration(
                  "Select business type",
                  Icons.category_outlined,
                ),
                items: _sellerTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please select business type";
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

              // FSSAI Number Field
              _buildLabel("FSSAI NUMBER"),
              TextFormField(
                controller: _fssaiController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "14-digit FSSAI number",
                  Icons.verified_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter FSSAI number";
                  if (value.length != 14)
                    return "FSSAI number must be 14 digits";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Email Field
              _buildLabel("BUSINESS EMAIL"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _buildInputDecoration(
                  "contact@business.com",
                  Icons.email_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter email";
                  if (!value.contains('@')) return "Please enter a valid email";
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
                  "At least 8 characters",
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
                  if (value.length < 8)
                    return "Password must be at least 8 characters";
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
                    "Create Seller Account",
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
