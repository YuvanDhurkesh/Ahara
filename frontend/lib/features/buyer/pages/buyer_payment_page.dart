import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/repositories/payment_repository.dart';

class BuyerPaymentPage extends StatefulWidget {
  final double? amount;
  final String? orderId;

  const BuyerPaymentPage({super.key, this.amount, this.orderId});

  @override
  State<BuyerPaymentPage> createState() => _BuyerPaymentPageState();
}

class _BuyerPaymentPageState extends State<BuyerPaymentPage> {
  late Razorpay _razorpay;
  final PaymentRepository _paymentRepo = PaymentRepository();
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {
      "type": "Card",
      "label": "Credit/Debit Card",
      "subtitle": "Visa, Mastercard, Rupay",
      "icon": Icons.credit_card_rounded,
      "isRazorpay": true
    },
    {
      "type": "UPI",
      "label": "UPI",
      "subtitle": "Google Pay / PhonePe / Paytm",
      "icon": Icons.qr_code_rounded,
      "isRazorpay": true
    },
    {
      "type": "Wallet",
      "label": "Digital Wallet",
      "subtitle": "PayTM Wallet",
      "icon": Icons.account_balance_wallet_rounded,
      "isRazorpay": true
    },
    {
      "type": "Cash",
      "label": "Cash on Delivery",
      "subtitle": "Pay when order arrives",
      "icon": Icons.money_rounded,
      "isRazorpay": false
    },
  ];

  String _selectedMethod = "Card";

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final isVerified = await _paymentRepo.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (isVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, _selectedMethod);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification failed!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    // Handle Cash on Delivery
    if (_selectedMethod == "Cash") {
      Navigator.pop(context, _selectedMethod);
      return;
    }

    // Handle Razorpay payment
    setState(() => _isProcessing = true);

    try {
      final amount = widget.amount ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final orderResponse = await _paymentRepo.createOrder(
        amount: amount,
        receipt: 'order_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (orderResponse['success'] == true) {
        final order = orderResponse['order'];
        final keyId = orderResponse['key_id'];

        var options = {
          'key': keyId,
          'amount': (amount * 100).toInt(),
          'name': 'Ahara',
          'description': 'Food Order',
          'order_id': order['id'],
          'prefill': {
            'email': 'user@ahara.com',
            'contact': '9999999999',
          },
          'theme': {'color': '#000000'}
        };

        _razorpay.open(options);
      } else {
        if (mounted) {
          final errorMsg = orderResponse['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order creation failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
                final isSelected = _selectedMethod == method['type'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMethod = method['type']),
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
                                method['label'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                method['subtitle'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      AppColors.textLight.withOpacity(0.6),
                                ),
                              ),
                              if (method['isRazorpay'])
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '(via Razorpay)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primary,
                                    ),
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
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isProcessing ? "Processing..." : "Confirm Payment",
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
  }}