/// File: buyer_address_page.dart
/// Purpose: Management and selection hub for buyer's delivery locations.
/// 
/// Responsibilities:
/// - Lists saved addresses with primary selection logic
/// - Routes to the "Add Address" flow
/// - Provides feedback on the currently active delivery point
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

import 'buyer_add_address_page.dart';

/// List-based interface for managing and selecting delivery addresses.
class BuyerAddressPage extends StatefulWidget {
  const BuyerAddressPage({super.key});

  @override
  State<BuyerAddressPage> createState() => _BuyerAddressPageState();
}

/// Orchestrates address selection, list management, and navigation callbacks.
class _BuyerAddressPageState extends State<BuyerAddressPage> {
  final List<Map<String, dynamic>> _addresses = [
    {
      "addressText": "123, Green Street, Koramangala, Bangalore",
      "geo": {"type": "Point", "coordinates": [77.6309, 12.9352]}
    },
    {
      "addressText": "Tech Park, Indiranagar, Bangalore",
      "geo": {"type": "Point", "coordinates": [77.6387, 12.9784]}
    },
    {
      "addressText": "45, 8th Main, HSR Layout, Bangalore",
      "geo": {"type": "Point", "coordinates": [77.6375, 12.9121]}
    },
  ];

  Map<String, dynamic>? _selectedAddressData;

  @override
  void initState() {
    super.initState();
    _selectedAddressData = _addresses[0];
  }

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
          "Delivery Address",
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
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final addrData = _addresses[index];
                final isSelected = _selectedAddressData == addrData;

                return GestureDetector(
                  onTap: () => setState(() => _selectedAddressData = addrData),
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
                        Icon(
                          Icons.location_on_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            addrData["addressText"],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
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
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final newAddressData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuyerAddAddressPage(),
                      ),
                    );

                    if (newAddressData != null && newAddressData is Map<String, dynamic>) {
                      setState(() {
                        _addresses.add(newAddressData);
                        _selectedAddressData = newAddressData;
                      });
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Add New Address"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedAddressData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Confirm Address",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
