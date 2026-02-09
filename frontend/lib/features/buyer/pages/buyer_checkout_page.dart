import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_dashboard_page.dart';
import '../data/mock_stores.dart';

class BuyerCheckoutPage extends StatefulWidget {
  final MockStore store;

  const BuyerCheckoutPage({super.key, required this.store});

  @override
  State<BuyerCheckoutPage> createState() => _BuyerCheckoutPageState();
}

class _BuyerCheckoutPageState extends State<BuyerCheckoutPage> {
  // State Variables
  String _selectedAddress = "Add shipping address";
  String _selectedPayment = "Visa *1234";
  String _promoCode = "";
  final TextEditingController _promoController = TextEditingController();

  // Mock Addresses
  final List<String> _savedAddresses = [
    "123, Green Street, Koramangala, Bangalore",
    "Tech Park, Indiranagar, Bangalore",
    "45, 8th Main, HSR Layout, Bangalore",
  ];

  // Logic to parse price
  double get _price {
    return double.tryParse(
          widget.store.price.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
  }

  double get _taxes => _price * 0.05;
  double get _total => _price + _taxes;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          "Checkout",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Conditional Delivery Sections
                  if (widget.store.offersDelivery) ...[
                    _buildInteractiveOptionRow(
                      "SHIPPING",
                      _selectedAddress,
                      onTap: _showAddressSelector,
                    ),
                    const Divider(height: 32, color: Color(0xFFEEEEEE)),
                    _buildOptionRow("DELIVERY", "Free"),
                    const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  ],

                  _buildInteractiveOptionRow(
                    "PAYMENT",
                    _selectedPayment,
                    onTap: _showPaymentSelector,
                  ),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  _buildInteractiveOptionRow(
                    "PROMOS",
                    _promoCode.isEmpty ? "Apply promo code" : _promoCode,
                    isPlaceholder: _promoCode.isEmpty,
                    onTap: _showPromoCodeDialog,
                  ),

                  const SizedBox(height: 48),

                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ITEMS",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "DESCRIPTION",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "PRICE",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Item Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.store.type,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.store.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget
                                  .store
                                  .area, // Using area as simplistic description
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Quantity: 01",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.store.isFree ? "Free" : widget.store.price,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),

                  // Totals
                  _buildSummaryRow("Subtotal (1)", _formatPrice(_price)),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    "Shipping total",
                    widget.store.offersDelivery ? "Free" : "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow("Taxes", _formatPrice(_taxes)),
                  const SizedBox(height: 20),
                  _buildSummaryRow(
                    "Total",
                    _formatPrice(_total),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showOrderSuccess(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Place order",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Helpers
  Widget _buildOptionRow(
    String label,
    String value, {
    bool isPlaceholder = false,
  }) {
    return _buildInteractiveOptionRow(
      label,
      value,
      isPlaceholder: isPlaceholder,
      onTap: null,
    );
  }

  Widget _buildInteractiveOptionRow(
    String label,
    String value, {
    bool isPlaceholder = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isPlaceholder ? const Color(0xFF888888) : Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    if (widget.store.isFree && value == 0) return "Free";
    return "₹${value.toStringAsFixed(2)}";
  }

  // Interactive Bottom Sheets

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Address",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ..._savedAddresses.map(
                (addr) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(addr, style: GoogleFonts.inter(fontSize: 14)),
                  onTap: () {
                    setState(() => _selectedAddress = addr);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add, color: Colors.blue),
                title: Text(
                  "Add New Address",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddAddressDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAddressDialog() {
    // Simplified Mock Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Address"),
        content: const TextField(
          decoration: InputDecoration(
            hintText: "Enter address or pick from map",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Mock adding
              setState(() {
                _selectedAddress = "New Address, Bangalore";
                _savedAddresses.add(_selectedAddress);
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPaymentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Method",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // UPI Option
                _buildPaymentOptionTile(
                  icon: Icons.qr_code,
                  title: "UPI",
                  subtitle: "Google Pay, PhonePe, Paytm",
                  onTap: () {
                    Navigator.pop(context);
                    _showDetailedPaymentSheet("UPI");
                  },
                ),

                // Card Option
                _buildPaymentOptionTile(
                  icon: Icons.credit_card,
                  title: "Credit / Debit Card",
                  subtitle: "Visa, Mastercard, Rupay",
                  onTap: () {
                    Navigator.pop(context);
                    _showDetailedPaymentSheet("Card");
                  },
                ),

                // Cash Option
                _buildPaymentOptionTile(
                  icon: Icons.money,
                  title: "Cash",
                  subtitle: "Pay on delivery / pickup",
                  onTap: () {
                    setState(() => _selectedPayment = "Cash");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDetailedPaymentSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                        _showPaymentSelector();
                      },
                    ),
                    Text(
                      type == "UPI" ? "Enter UPI ID" : "Card Details",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (type == "UPI")
                  _buildUPIForm(context)
                else
                  _buildCardForm(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUPIForm(BuildContext context) {
    // State wrapper
    return StatefulBuilder(
      builder: (context, setState) {
        bool isValid =
            false; // Mock validation state logic inside builder would require Controller listener
        // Simplified Logic: Text Field always shows.
        return Column(
          children: [
            Wrap(
              spacing: 12,
              children: [
                _buildChip("GPay"),
                _buildChip("PhonePe"),
                _buildChip("Paytm"),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: "UPI ID",
                hintText: "example@upi",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.check_circle, color: Colors.green),
              ),
              onChanged: (val) {
                // Mock validation logic
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  this.setState(() => _selectedPayment = "UPI (Verified)");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Verify & Pay"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildCardForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: "Card Number",
            hintText: "0000 0000 0000 0000",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Expiry Date",
                  hintText: "MM/YY",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: "CVV",
                  hintText: "123",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: "Cardholder Name",
            hintText: "John Doe",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              this.setState(() => _selectedPayment = "Visa *8888");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Save Card"),
          ),
        ),
      ],
    );
  }

  void _showPromoCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Promo Code"),
        content: TextField(
          controller: _promoController,
          decoration: const InputDecoration(
            hintText: "e.g., WELCOME50",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_promoController.text.isNotEmpty) {
                setState(() {
                  _promoCode = _promoController.text.toUpperCase();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Promo '$_promoCode' applied!")),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Order successfully placed",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your meal is being prepared with care.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerDashboardPage(
                            initialIndex: 2, // Orders tab
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "View My Orders",
                      style: GoogleFonts.inter(
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
      },
    );
  }
}
