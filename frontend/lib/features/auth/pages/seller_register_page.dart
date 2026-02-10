import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';
import '../../../shared/widgets/phone_input_field.dart';

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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedType;
  bool _obscurePassword = true;

  final List<String> _sellerTypes = [
    'Restaurant',
    'Cafe',
    'Cloud Kitchen',
    'Pet Shop',
    'Event Management',
    'Cafeteria',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _fssaiController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Join as a Seller",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Partner with us to reduce food waste and serve your local community.",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Business Name Field
                  _buildLabel("BUSINESS NAME"),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "E.g. Sunshine Delights",
                      prefixIcon: Icon(Icons.business_outlined),
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
                    hint: Text(
                      "Select business type",
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textLight.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    items: _sellerTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      );
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
                  ),
                  const SizedBox(height: 28),

                  // FSSAI Number Field
                  _buildLabel("FSSAI NUMBER"),
                  TextFormField(
                    controller: _fssaiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "14-digit FSSAI number",
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter FSSAI number";
                      if (value.length != 14)
                        return "FSSAI number must be 14 digits";
                      return null;
                    },
                  ),
                  // Contact Number Field
                  PhoneInputField(
                    controller: _phoneController,
                    label: "CONTACT NUMBER",
                    hintText: "12345 67890",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Email Field
                  _buildLabel("BUSINESS EMAIL"),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "contact@business.com",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter email";
                      if (!value.contains('@'))
                        return "Please enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Password Field
                  _buildLabel("PASSWORD"),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "At least 8 characters",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Registration successful! Please login.",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
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
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
