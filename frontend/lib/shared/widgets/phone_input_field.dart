import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/app_colors.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String hintText;
  final String? initialCountryCode;
  final ValueChanged<String>? onCountryCodeChanged;
  final int maxLength;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    required this.label,
    this.hintText = "Enter phone number",
    this.initialCountryCode = "+91",
    this.onCountryCodeChanged,
    this.maxLength = 10,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late String _selectedCountryCode;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India'},
    {'code': '+1', 'name': 'USA'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+61', 'name': 'Australia'},
    {'code': '+971', 'name': 'UAE'},
    {'code': '+65', 'name': 'Singapore'},
    {'code': '+81', 'name': 'Japan'},
    {'code': '+49', 'name': 'Germany'},
    {'code': '+33', 'name': 'France'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode ?? '+91';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.phone,
          maxLength: widget.maxLength,
          obscureText: false, // Ensure digits are visible
          cursorColor: AppColors.primary,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black, // Absolute black for contrast
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: false, // Disable theme fill
            counterText: '',
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: AppColors.textLight.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isDense: true,
                  items: _countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text(
                        country['code']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCountryCode = value);
                      if (widget.onCountryCodeChanged != null) {
                        widget.onCountryCodeChanged!(value);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}
