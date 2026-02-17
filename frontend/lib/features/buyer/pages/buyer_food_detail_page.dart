import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';
import 'buyer_checkout_page.dart';
import 'buyer_address_page.dart';
import 'buyer_payment_page.dart';
import 'buyer_order_confirmation_page.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../data/services/backend_service.dart';
import '../../../core/auth/auth_provider.dart';

class BuyerFoodDetailPage extends StatelessWidget {
  final MockStore? store;
  final Map<String, dynamic>? listing;

  const BuyerFoodDetailPage({super.key, this.store, this.listing});

  @override
  Widget build(BuildContext context) {
    // Check if listing is expired
    final expiryTime = listing?['pickupWindow']?['to'] != null
        ? DateTime.tryParse(listing!['pickupWindow']['to'])
        : null;
    final isExpired = expiryTime != null && DateTime.now().isAfter(expiryTime);

    // Show expired state if listing has expired
    if (isExpired && listing != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_filled,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  "This listing has expired",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "This food item is no longer available for reservation.",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Browse Active Listings",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Original build logic for active listings
    // Unify data from store or listing
    final String name = store?.name ?? listing?['foodName'] ?? "Unknown Food";
    final String type = store?.type ?? listing?['foodType'] ?? "Meal";
    
    // Get rating from seller profile or use default
    final sellerProfile = listing?['sellerProfileId'] ?? {};
    final double sellerRating = (sellerProfile['stats']?['avgRating'] ?? 0.0).toDouble();
    final int ratingCount = sellerProfile['stats']?['ratingCount'] ?? 0;
    final String rating = store?.rating ?? (sellerRating > 0 ? sellerRating.toStringAsFixed(1) : "4.5");
    
    final bool isFree = store?.isFree ?? (listing?['pricing']?['isFree'] ?? false);
    final String price = store?.price ?? "₹${listing?['pricing']?['discountedPrice'] ?? 0}";
    
    final List images = listing?['images'] ?? [];
    final String imageUrl = store?.image ?? (images.isNotEmpty 
        ? BackendService.formatImageUrl(images[0])
        : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop");

    final String address = store?.address ?? (listing?['pickupAddressText'] ?? "Bangalore");
    final String orgName = store?.name ?? (listing?['sellerProfileId']?['orgName'] ?? "Local Seller");
    
    final Map<String, double> reviews = store?.reviews ?? {
      "Collection": 4.5,
      "Quality": 4.8,
      "Variety": 4.2,
      "Quantity": 4.7,
    };
    
    // Use ingredients if available, else use a placeholder based on description
    final List<String> ingredients = store?.ingredients ?? 
        (listing?['description']?.toString().split(',') ?? ["Organic", "Healthy", "Fresh"]);
    
    final bool offersDelivery = store?.offersDelivery ?? (listing?['options']?['deliveryAvailable'] ?? true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, imageUrl),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(context, type, rating, name, address),
                  const SizedBox(height: 32),
                  _buildDirectionsButton(),
                  const SizedBox(height: 48),
                  _buildReviewSection(context, rating, reviews),
                  const SizedBox(height: 48),
                  _buildIngredientsSection(ingredients),
                  const SizedBox(height: 120), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildReserveButton(context, isFree, price, offersDelivery),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, String type, String rating, String name, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: GoogleFonts.cormorantInfant(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textLight.withOpacity(0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.directions_outlined, size: 20),
        label: Text(
          "Get Directions",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context, String rating, Map<String, double> reviews) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingsTitle(),
                  const SizedBox(height: 16),
                  _buildLargeRating(rating),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildRatingsTitle()),
                  _buildLargeRating(rating),
                ],
              ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 4.0 : 2.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            String category = reviews.keys.elementAt(index);
            double score = reviews.values.elementAt(index);
            return _buildReviewCard(category, score);
          },
        ),
      ],
    );
  }

  Widget _buildRatingsTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overall Ratings",
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Verified Reviews",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              "from the community",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textLight.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeRating(String rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rating,
          style: GoogleFonts.inter(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            height: 1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
      ],
    );
  }

  Widget _buildReviewCard(String label, double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textDark.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight.withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                score.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 5.0,
              backgroundColor: AppColors.surface.withOpacity(0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<String> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ingredients",
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "What's inside your pick",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textLight.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ingredients.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReserveButton(BuildContext context, bool isFree, String price, bool offersDelivery) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showSelectionSlide(context, offersDelivery),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          shadowColor: AppColors.primary.withOpacity(0.4),
          backgroundColor: isFree ? Colors.green : AppColors.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFree ? "Claim Now" : "Reserve for $price",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSelectionSlide(BuildContext context, bool offersDelivery) {
    String currentAddress = "123, Green Street, Koramangala";
    String currentPayment = "Visa *1234";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Quick Checkout",
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (offersDelivery) ...[
                    _buildSelectionItem(
                      context,
                      icon: Icons.location_on_outlined,
                      title: "Delivery Address",
                      value: currentAddress,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuyerAddressPage(),
                          ),
                        );
                        if (result != null) {
                          setModalState(() => currentAddress = result);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildSelectionItem(
                    context,
                    icon: Icons.credit_card_outlined,
                    title: "Payment Method",
                    value: currentPayment,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerPaymentPage(),
                        ),
                      );
                      if (result != null) {
                        setModalState(() => currentPayment = result);
                      }
                    },
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (store != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BuyerCheckoutPage(store: store!),
                            ),
                          );
                        } else {
                          // Handle real listing checkout
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Checkout for real listings coming soon!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Confirm Selection",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textDark.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildReserveButton(BuildContext context, bool isFree, String price, bool offersDelivery) {
    // Only show button for real listings (not mock stores)
    if (listing == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Price',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  isFree ? 'FREE' : price,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.green : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showOrderDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFree ? Colors.green : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isFree ? 'Claim Now' : 'Order Now',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context) {
    int quantity = 1;
    final maxQuantity = listing?['remainingQuantity'] ?? 1;
    final pricing = listing?['pricing'] ?? {};
    final isFree = pricing['isFree'] ?? false;
    final pricePerItem = pricing['discountedPrice'] ?? 0;
    bool isPlacing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final total = isFree ? 0 : (pricePerItem * quantity);

          return AlertDialog(
            title: Text(
              'Place Order',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select quantity to order',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                      iconSize: 32,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < maxQuantity
                          ? () => setState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Max: $maxQuantity',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isFree ? 'FREE' : '₹$total',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFree ? Colors.green : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isPlacing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isPlacing
                    ? null
                    : () async {
                        setState(() => isPlacing = true);
                        await _placeOrder(context, quantity);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFree ? Colors.green : AppColors.primary,
                ),
                child: isPlacing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isFree ? 'Claim' : 'Place Order',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, int quantity) async {
    try {
      // Get buyer ID from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final buyerId = authProvider.mongoUserId;

      if (buyerId == null) {
        throw Exception('User not logged in');
      }

      final orderData = {
        "listingId": listing!['_id'],
        "buyerId": buyerId,
        "quantityOrdered": quantity,
        "fulfillment": "self_pickup",
        "pickup": {
          "addressText": listing!['pickupAddressText'] ?? 'Pickup location',
          "scheduledAt": listing!['pickupWindow']?['to'],
        },
        "pricing": {
          "itemTotal": (listing!['pricing']?['discountedPrice'] ?? 0) * quantity,
          "deliveryFee": 0,
          "platformFee": 0,
          "total": (listing!['pricing']?['discountedPrice'] ?? 0) * quantity,
        },
      };

      final response = await BackendService.createOrder(orderData);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        
        // Navigate to confirmation page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerOrderConfirmationPage(order: response),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
