import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'buyer_dashboard_page.dart';
import '../data/mock_stores.dart';
import '../../../core/localization/app_localizations.dart';

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
          AppLocalizations.of(context)!.translate("checkout") ?? "Checkout",
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
                      AppLocalizations.of(context)!.translate("shipping") ?? "SHIPPING",
                      _selectedAddress == "Add shipping address" ? (AppLocalizations.of(context)!.translate("add_shipping_address") ?? "Add shipping address") : _selectedAddress,
                      onTap: _showAddressSelector,
                    ),
                    const Divider(height: 32, color: Color(0xFFEEEEEE)),
                    _buildOptionRow(AppLocalizations.of(context)!.translate("delivery") ?? "DELIVERY", AppLocalizations.of(context)!.translate("free") ?? "Free"),
                    const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  ],

                  _buildInteractiveOptionRow(
                    AppLocalizations.of(context)!.translate("payment") ?? "PAYMENT",
                    _selectedPayment,
                    onTap: _showPaymentSelector,
                  ),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  _buildInteractiveOptionRow(
                    AppLocalizations.of(context)!.translate("promos") ?? "PROMOS",
                    _promoCode.isEmpty ? (AppLocalizations.of(context)!.translate("apply_promo_code") ?? "Apply promo code") : _promoCode,
                    isPlaceholder: _promoCode.isEmpty,
                    onTap: _showPromoCodeDialog,
                  ),

                  const SizedBox(height: 48),

                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate("items") ?? "ITEMS",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.translate("description") ?? "DESCRIPTION",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.translate("price") ?? "PRICE",
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
                              "${AppLocalizations.of(context)!.translate("quantity") ?? "Quantity"}: 01",
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
                        widget.store.isFree ? (AppLocalizations.of(context)!.translate("free") ?? "Free") : widget.store.price,
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
                  _buildSummaryRow(AppLocalizations.of(context)!.translate("subtotal") ?? "Subtotal (1)", _formatPrice(context, _price)),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    AppLocalizations.of(context)!.translate("shipping_total") ?? "Shipping total",
                    widget.store.offersDelivery ? (AppLocalizations.of(context)!.translate("free") ?? "Free") : (AppLocalizations.of(context)!.translate("not_applicable") ?? "N/A"),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(AppLocalizations.of(context)!.translate("taxes") ?? "Taxes", _formatPrice(context, _taxes)),
                  const SizedBox(height: 20),
                  _buildSummaryRow(
                    AppLocalizations.of(context)!.translate("total") ?? "Total",
                    _formatPrice(context, _total),
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
                  onPressed: () {
                    // Navigate to Dashboard and clear stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuyerDashboardPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate("place_order") ?? "Place order",
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

  String _formatPrice(BuildContext context, double value) {
    if (widget.store.isFree && value == 0) return AppLocalizations.of(context)!.translate("free") ?? "Free";
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
                AppLocalizations.of(context)!.translate("select_address") ?? "Select Address",
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
                  AppLocalizations.of(context)!.translate("add_new_address") ?? "Add New Address",
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
        title: Text(AppLocalizations.of(context)!.translate("add_address") ?? "Add Address"),
        content: TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate("enter_address_hint") ?? "Enter address or pick from map",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate("cancel") ?? "Cancel"),
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
            child: Text(AppLocalizations.of(context)!.translate("save") ?? "Save"),
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
                  AppLocalizations.of(context)!.translate("payment_method") ?? "Payment Method",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // UPI Option
                _buildPaymentOptionTile(
                  icon: Icons.qr_code,
                  title: AppLocalizations.of(context)!.translate("upi") ?? "UPI",
                  subtitle: AppLocalizations.of(context)!.translate("upi_subtitle") ?? "Google Pay, PhonePe, Paytm",
                  onTap: () {
                    Navigator.pop(context);
                    _showDetailedPaymentSheet("UPI");
                  },
                ),

                // Card Option
                _buildPaymentOptionTile(
                  icon: Icons.credit_card,
                  title: AppLocalizations.of(context)!.translate("credit_debit_card") ?? "Credit / Debit Card",
                  subtitle: AppLocalizations.of(context)!.translate("card_subtitle") ?? "Visa, Mastercard, Rupay",
                  onTap: () {
                    Navigator.pop(context);
                    _showDetailedPaymentSheet("Card");
                  },
                ),

                // Cash Option
                _buildPaymentOptionTile(
                  icon: Icons.money,
                  title: AppLocalizations.of(context)!.translate("cash") ?? "Cash",
                  subtitle: AppLocalizations.of(context)!.translate("cash_subtitle") ?? "Pay on delivery / pickup",
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
                      type == "UPI" ? (AppLocalizations.of(context)!.translate("enter_upi_id") ?? "Enter UPI ID") : (AppLocalizations.of(context)!.translate("card_details") ?? "Card Details"),
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
                labelText: AppLocalizations.of(context)!.translate("upi_id") ?? "UPI ID",
                hintText: AppLocalizations.of(context)!.translate("example_upi") ?? "example@upi",
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
                child: Text(AppLocalizations.of(context)!.translate("verify_and_pay") ?? "Verify & Pay"),
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
            labelText: AppLocalizations.of(context)!.translate("card_number") ?? "Card Number",
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
                  labelText: AppLocalizations.of(context)!.translate("expiry_date") ?? "Expiry Date",
                  hintText: AppLocalizations.of(context)!.translate("mm_yy") ?? "MM/YY",
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
                  labelText: AppLocalizations.of(context)!.translate("cvv") ?? "CVV",
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
            labelText: AppLocalizations.of(context)!.translate("cardholder_name") ?? "Cardholder Name",
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
            child: Text(AppLocalizations.of(context)!.translate("save_card") ?? "Save Card"),
          ),
        ),
      ],
    );
  }

  void _showPromoCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate("enter_promo_code") ?? "Enter Promo Code"),
        content: TextField(
          controller: _promoController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate("eg_welcome50") ?? "e.g., WELCOME50",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate("cancel") ?? "Cancel"),
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
            child: Text(AppLocalizations.of(context)!.translate("apply") ?? "Apply"),
          ),
        ],
      ),
    );
  }
}
