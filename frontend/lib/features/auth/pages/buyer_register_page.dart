import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';
import '../../../shared/widgets/phone_input_field.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/language_provider.dart';

class BuyerRegisterPage extends StatefulWidget {
  final String role;

  const BuyerRegisterPage({super.key, required this.role});

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
  bool _isDetectingLocation = false;

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
  /// 🔥 AUTO LOCATION DETECTION (PRODUCTION SAFE)
  //---------------------------------------------------------

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permanently denied. Enable from device settings.",
            ),
          ),
        );
        return;
      }

      /// Fetch coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      /// Convert to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String address =
          "${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";

      _locationController.text = address;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to detect location")),
      );
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
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
        language: context.read<LanguageProvider>().locale.languageCode,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  _buildTextField(
                    _nameController,
                    "E.g. Jane Doe",
                    Icons.person_outline,
                    maxLength: 50,
                  ),

                  const SizedBox(height: 28),

                  PhoneInputField(
                    controller: _phoneController,
                    label: "PHONE NUMBER",
                    hintText: "12345 67890",
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your number";
                      }
                      if (value.length != 10) {
                        return "Phone number must be 10 digits";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  _buildLabel("EMAIL ADDRESS"),
                  _buildTextField(
                    _emailController,
                    "name@example.com",
                    Icons.email_outlined,
                    maxLength: 100,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 28),

                  //-------------------------------------------------
                  /// PASSWORD
                  //-------------------------------------------------
                  _buildLabel("PASSWORD"),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: "At least 6 characters",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      counterText: '',
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
                  /// 🔥 LOCATION WITH AUTO DETECT BUTTON
                  //-------------------------------------------------
                  _buildLabel("LOCATION"),

                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: "Search your area",
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: IconButton(
                        icon: _isDetectingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        onPressed: _isDetectingLocation
                            ? null
                            : _detectLocation,
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Please specify your location"
                        : null,
                  ),

                  const SizedBox(height: 48),

                  //-------------------------------------------------
                  /// REGISTER BUTTON
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
    IconData icon, {
    int maxLength = 100,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        counterText: '',
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "This field is required" : null,
    );
  }
}
