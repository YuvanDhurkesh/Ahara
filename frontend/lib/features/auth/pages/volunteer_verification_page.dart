import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../shared/styles/app_colors.dart';
import '../../../data/services/backend_service.dart';

class VolunteerVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String name;

  const VolunteerVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.name,
  });

  @override
  State<VolunteerVerificationPage> createState() => _VolunteerVerificationPageState();
}

class _VolunteerVerificationPageState extends State<VolunteerVerificationPage> {
  final _aadhaarController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  bool _isAadhaarSubmitted = false;
  bool _isVerifying = false;
  int _timerValue = 60;
  Timer? _timer;

  @override
  void dispose() {
    _aadhaarController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
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
    if (_aadhaarController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 12-digit Aadhaar number")),
      );
      return;
    }
    setState(() {
      _isAadhaarSubmitted = true;
    });
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mock Aadhaar OTP sent to your linked mobile number")),
    );
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
      // Use the mock service
      final result = await BackendService.verifyAadhaarMock(
        phoneNumber: widget.phoneNumber,
        aadhaarNumber: _aadhaarController.text.trim(),
        name: widget.name,
      );

      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Identity Verification Successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
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
          "Identity Verification",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.security_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              "Aadhaar e-KYC",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isAadhaarSubmitted 
                ? "Enter the 6-digit OTP sent to the mobile number registered with your Aadhaar."
                : "Enter your 12-digit Aadhaar number to verify your identity.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            if (!_isAadhaarSubmitted) ...[
              _buildAadhaarInput(),
              const SizedBox(height: 40),
              _buildLargeButton("Generate OTP", _submitAadhaar),
            ] else ...[
              _buildOtpInput(),
              const SizedBox(height: 24),
              Text(
                "Resend code in ${_timerValue}s",
                style: TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 48),
              _buildLargeButton(_isVerifying ? "Verifying..." : "Verify & Complete", _isVerifying ? null : _verifyFinal),
              TextButton(
                onPressed: () => setState(() => _isAadhaarSubmitted = false),
                child: const Text("Change Aadhaar Number", style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAadhaarInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withOpacity(0.1), width: 1.5),
      ),
      child: TextField(
        controller: _aadhaarController,
        keyboardType: TextInputType.number,
        maxLength: 12,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
          color: AppColors.textDark,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "XXXX XXXX XXXX",
          hintStyle: TextStyle(letterSpacing: 0, color: Colors.grey),
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
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _otpFocusNodes[index].hasFocus ? AppColors.primary : AppColors.textLight.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: "", border: InputBorder.none),
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

  Widget _buildLargeButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text),
      ),
    );
  }
}
