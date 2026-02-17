import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../shared/styles/app_colors.dart';
import 'login_page.dart';
import '../../../shared/widgets/phone_input_field.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';

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
  final _locationController = TextEditingController();

  String? _selectedTransport;
  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _transportModes = ['Car', 'Bike', 'Cycle', 'Walk'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _locationController.dispose();
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
    // Show DOB field for everything except 'Cycle' and 'Walk'
    final bool showDOB =
        _selectedTransport == 'Car' || _selectedTransport == 'Bike';

    return Scaffold(
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
                    "Join as a Volunteer",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Offer your time and help distribute food surplus to the neighborhood.",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Name Field
                  _buildLabel("FULL NAME"),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Enter your full name",
                      prefixIcon: Icon(Icons.person_outline),
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
                    hint: Text(
                      "Select transport mode",
                      style: GoogleFonts.inter(
                        color: AppColors.textLight.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please select transport mode";
                      return null;
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Conditional DOB Field
                  if (showDOB) ...[
                    _buildLabel("DATE OF BIRTH"),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: "DD/MM/YYYY",
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Please select your date of birth";
                        if (_selectedDate != null &&
                            !_isEligible(_selectedDate!)) {
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
                    decoration: const InputDecoration(
                      hintText: "name@example.com",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your email";
                      if (!value.contains('@'))
                        return "Please enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

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

                  // Location Field
                  _buildLabel("LOCATION (OPTIONAL)"),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: "E.g. Bangalore, Karnataka",
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Password Field
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
                      if (value.length < 6)
                        return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          
                          final auth = context.read<AppAuthProvider>();
                          
                          try {
                            await auth.registerUser(
                              role: 'volunteer',
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              location: _locationController.text.trim().isEmpty 
                                  ? 'Not specified' 
                                  : _locationController.text.trim(),
                              transportMode: _selectedTransport,
                              dateOfBirth: _selectedDate?.toIso8601String(),
                              language: context.read<LanguageProvider>().locale.languageCode,
                            );
                            
                            if (!mounted) return;
                            
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
                          } on fb.FirebaseAuthException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? "Registration failed")),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Create Volunteer Account"),
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
