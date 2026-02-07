import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../../buyer/pages/buyer_dashboard_page.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class BuyerRegisterPage extends StatefulWidget {

  final String role;

  const BuyerRegisterPage({
    super.key,
    required this.role,
  });

  @override
  State<BuyerRegisterPage> createState() => _BuyerRegisterPageState();
}


class _BuyerRegisterPageState extends State<BuyerRegisterPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  //---------------------------------------------------------

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  //---------------------------------------------------------

  Future<void> _registerUser() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();

    try {

      final user = await auth.registerUser(
        role: widget.role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        location: _locationController.text.trim(),
      );


      if (!mounted) return;

      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const BuyerDashboardPage(),
          ),
          (route) => false,
        );
      }

    } on fb.FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Registration failed"),
        ),
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Join as a ${widget.role[0].toUpperCase()}${widget.role.substring(1)}",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 12),

              Text(
                "Create your account to start finding local surplus meals and help reduce waste.",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              _buildLabel("FULL NAME"),
              _buildTextField(_nameController, "E.g. Jane Doe", Icons.person_outline),

              const SizedBox(height: 28),

              _buildLabel("PHONE NUMBER"),
              _buildTextField(_phoneController, "+1 (555) 000-0000", Icons.phone_outlined),

              const SizedBox(height: 28),

              _buildLabel("EMAIL ADDRESS"),
              _buildTextField(_emailController, "name@example.com", Icons.email_outlined),

              const SizedBox(height: 28),

              //-------------------------------------------------
              // PASSWORD
              //-------------------------------------------------

              _buildLabel("PASSWORD"),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "At least 6 characters",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              //-------------------------------------------------
              // LOCATION
              //-------------------------------------------------

              _buildLabel("LOCATION"),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: "Search your area",
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please specify your location";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              //-------------------------------------------------
              // REGISTER BUTTON
              //-------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Account"),
                ),
              ),

              const SizedBox(height: 32),

              //-------------------------------------------------
              // LOGIN NAV
              //-------------------------------------------------

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    "Already registered? ",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.8),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },

                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //---------------------------------------------------------

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  //---------------------------------------------------------

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "This field is required" : null,
    );
  }
}
