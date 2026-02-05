import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'buyer_home_page.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';

class BuyerCheckoutPage extends StatefulWidget {
  final MockStore store;

  const BuyerCheckoutPage({super.key, required this.store});

  @override
  State<BuyerCheckoutPage> createState() => _BuyerCheckoutPageState();
}

class _BuyerCheckoutPageState extends State<BuyerCheckoutPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String? _selectedAddress = "Home"; // Default selection
  String? _selectedPayment = "Credit Card"; // Default selection

  // Hardcoded addresses for demo
  final List<Map<String, String>> _addresses = [
    {"label": "Home", "address": "123, Green Street, Koramangala, Bangalore"},
    {"label": "Work", "address": "Tech Park, Indiranagar, Bangalore"},
  ];

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading:
            _currentStep <
                3 // Hide back button on success screen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        title: _currentStep < 3
            ? Text(
                _getStepTitle(),
                style: GoogleFonts.bellefair(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              )
            : null,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildBillSummary(),
          _buildAddressSelection(),
          _buildPaymentSelection(),
          _buildSuccessScreen(),
        ],
      ),
      bottomNavigationBar: _currentStep < 3 ? _buildBottomBar() : null,
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Order Summary";
      case 1:
        return "Delivery Address";
      case 2:
        return "Payment Method";
      default:
        return "";
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _currentStep == 2 ? "Confirm & Pay" : "Proceed",
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillSummary() {
    final price =
        double.tryParse(
          widget.store.price.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final taxes = price * 0.05; // 5% tax
    final total = price + taxes;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.store.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.store.name,
                        style: GoogleFonts.alice(
                          fontSize: 22,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.store.type,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textLight.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Bill Details",
            style: GoogleFonts.alice(fontSize: 26, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: Column(
              children: [
                _buildBillRow("Item Total", "₹${price.toStringAsFixed(2)}"),
                const SizedBox(height: 12),
                _buildBillRow(
                  "Taxes & Charges",
                  "₹${taxes.toStringAsFixed(2)}",
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                _buildBillRow(
                  "To Pay",
                  "₹${total.toStringAsFixed(2)}",
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.textDark : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Address",
            style: GoogleFonts.bellefair(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          ..._addresses.map((addr) {
            final isSelected = _selectedAddress == addr['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedAddress = addr['label']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
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
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addr['label']!,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr['address']!,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement Add Address / Map functionality
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Address"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection() {
    final methods = ["Credit Card", "Debit Card", "UPI", "Cash on Collection"];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method",
            style: GoogleFonts.bellefair(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          ...methods.map((method) {
            final isSelected = _selectedPayment == method;
            return GestureDetector(
              onTap: () => setState(() => _selectedPayment = method),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      method,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 32),
            Text(
              "Order Confirmed!",
              style: GoogleFonts.bellefair(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We've sent the details to your email.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Home and clear stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyerHomePage(
                        favouriteIds: const {},
                        onToggleFavourite: (_) {},
                      ),
                    ), // Temporary -> should be BuyerHome
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Back to Home",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
