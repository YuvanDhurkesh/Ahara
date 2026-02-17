import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';
import '../../../shared/widgets/phone_input_field.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';

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
  final _locationController = TextEditingController();

  String? _selectedType;
  bool _obscurePassword = true;
  bool _isLoading = false;

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
    _locationController.dispose();
    super.dispose();
  }

  //---------------------------------------------------------
  /// SELLER REGISTRATION
  //---------------------------------------------------------

  Future<void> _registerSeller() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();

    try {
      final user = await auth.registerUser(
        role: 'seller',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? 'Not specified'
            : _locationController.text.trim(),
        businessName: _nameController.text.trim(),
        businessType: _selectedType,
        fssaiNumber: _fssaiController.text.trim(),
        language:
            context.read<LanguageProvider>().locale.languageCode,
      );

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Please login."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  //---------------------------------------------------------

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildLabel("BUSINESS NAME"),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: "E.g. Sunshine Delights",
                      prefixIcon: Icon(Icons.business_outlined),
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? "Please enter business name"
                            : null,
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("BUSINESS TYPE"),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    hint: const Text("Select business type"),
                    items: _sellerTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedType = value),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? "Please select business type"
                            : null,
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("FSSAI NUMBER"),
                  TextFormField(
                    controller: _fssaiController,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                    ],
                    decoration: const InputDecoration(
                      hintText: "14-digit FSSAI number",
                      prefixIcon: Icon(Icons.verified_outlined),
                      counterText: '',
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

                  PhoneInputField(
                    controller: _phoneController,
                    label: "CONTACT NUMBER",
                    hintText: "12345 67890",
                    maxLength: 10,
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("BUSINESS EMAIL"),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: "contact@business.com",
                      prefixIcon: Icon(Icons.email_outlined),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("LOCATION (OPTIONAL)"),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: "E.g. Bangalore, Karnataka",
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("PASSWORD"),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: "At least 8 characters",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null || value.length < 8
                            ? "Password must be at least 8 characters"
                            : null,
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _registerSeller,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Create Seller Account",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already registered? ",
                        style: TextStyle(
                          color: AppColors.textLight
                              .withOpacity(0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginPage(),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight:
                                FontWeight.bold,
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
      padding:
          const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium),
    );
  }
}
