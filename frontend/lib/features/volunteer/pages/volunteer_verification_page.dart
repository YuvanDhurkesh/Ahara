import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/services/backend_service.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../main.dart'; // Import AuthWrapper

class VolunteerVerificationPage extends StatefulWidget {
  const VolunteerVerificationPage({super.key});

  @override
  State<VolunteerVerificationPage> createState() =>
      _VolunteerVerificationPageState();
}

class _VolunteerVerificationPageState extends State<VolunteerVerificationPage> {
  final _aadhaarController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  bool _isAadhaarSubmitted = false;
  bool _isVerifying = false;
  bool _isSuccess = false;
  int _timerValue = 60;
  Timer? _timer;

  @override
  void dispose() {
    _aadhaarController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerValue = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        timer.cancel();
      }
    });
  }

  void _submitAadhaar() {
    final validationError = Validators.validateAadhaar(_aadhaarController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }
    setState(() => _isAadhaarSubmitted = true);
    _startTimer();
  }

  void _verifyFinal() async {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit mock OTP")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final auth = context.read<AppAuthProvider>();
      final phone = auth.mongoUser?['phone'] ?? "";
      
      await BackendService.verifyAadhaarMock(
        phoneNumber: phone,
        aadhaarNumber: _aadhaarController.text.trim(),
        name: auth.mongoUser?['name'] ?? "Volunteer",
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
        });
        
        // Refresh profile state
        await auth.refreshMongoUser();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Account Verification",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isSuccess ? _buildSuccessState() : _buildVerificationForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Get Verified",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          "Verified volunteers get priority access to delivery requests.",
          style: TextStyle(fontSize: 14, color: AppColors.textLight.withOpacity(0.6)),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAadhaarSubmitted ? "Enter Code" : "Aadhaar Card Number",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isAadhaarSubmitted 
                  ? "We sent a 6-digit OTP to your linked mobile number." 
                  : "Enter your 12-digit Aadhaar number for identity verification.",
                style: TextStyle(fontSize: 13, color: AppColors.textLight.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),

              if (!_isAadhaarSubmitted) ...[
                _buildAadhaarInput(),
                const SizedBox(height: 32),
                _buildButton("Generate OTP", _submitAadhaar),
              ] else ...[
                _buildOtpInput(),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Resend in ${_timerValue}s",
                    style: TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 32),
                _buildButton(_isVerifying ? "Verifying..." : "Verify & Complete", _isVerifying ? null : _verifyFinal),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isAadhaarSubmitted = false),
                    child: const Text("Change Aadhaar Number", style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          "Verification Successful!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Your identity has been verified. You now have full access to delivery requests.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 48),
        _buildButton("Go to Home", () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }),
      ],
    );
  }

  Widget _buildAadhaarInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0EB), // Slightly darker cream for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _aadhaarController,
        keyboardType: TextInputType.number,
        maxLength: 12,
        obscureText: false, // Ensure digits are visible
        autocorrect: false,
        enableSuggestions: false,
        cursorColor: AppColors.primary,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24, // Even larger
          fontWeight: FontWeight.w800, // Extra bold
          letterSpacing: 4,
          color: Colors.black, // Use absolute black for maximum contrast
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: "XXXX XXXX XXXX",
          hintStyle: TextStyle(
            letterSpacing: 0,
            color: Colors.grey.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          filled: false, // Don't use theme-level white fill
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          counterText: "",
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 50,
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0EB), // Match Aadhaar field
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _otpFocusNodes[index].hasFocus ? AppColors.primary : AppColors.textLight.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            obscureText: false, // Ensure digits are visible
            cursorColor: AppColors.primary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black, // Absolute black
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: "",
              filled: false, // No default theme background
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
