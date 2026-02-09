import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

class BuyerPaymentPage extends StatefulWidget {
  const BuyerPaymentPage({super.key});

  @override
  State<BuyerPaymentPage> createState() => _BuyerPaymentPageState();
}

class _BuyerPaymentPageState extends State<BuyerPaymentPage> {
  final List<Map<String, dynamic>> _methods = [
    {"type": "Card", "label": "Visa *1234", "icon": Icons.credit_card_rounded},
    {
      "type": "UPI",
      "label": "Google Pay / PhonePe",
      "icon": Icons.qr_code_rounded,
    },
    {"type": "Cash", "label": "Cash on Delivery", "icon": Icons.money_rounded},
  ];

  String _selectedMethod = "Visa *1234";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment Method",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final method = _methods[index];
                final isSelected = _selectedMethod == method['label'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMethod = method['label']),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            method['icon'],
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['type'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight.withOpacity(0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                method['label'],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Confirm Payment",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
