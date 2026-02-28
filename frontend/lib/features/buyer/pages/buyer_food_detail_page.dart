import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../../data/providers/app_auth_provider.dart';
import '../../../shared/widgets/animated_toast.dart';

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
    final double sellerRating = (sellerProfile['stats']?['avgRating'] ?? 0.0)
        .toDouble();
    final int ratingCount = sellerProfile['stats']?['ratingCount'] ?? 0;
    final String rating =
        store?.rating ??
        (sellerRating > 0 ? sellerRating.toStringAsFixed(1) : "4.5");

    final bool isFree =
        store?.isFree ?? (listing?['pricing']?['isFree'] ?? false);
    final String price =
        store?.price ?? "₹${listing?['pricing']?['discountedPrice'] ?? 0}";

    final List images = listing?['images'] ?? [];
    final String foodName =
        store?.name ?? (listing?['foodName'] ?? "Food Item");
    final String uploadedImageUrl = images.isNotEmpty
        ? BackendService.formatImageUrl(images[0])
        : "";
    final String imageUrl =
        store?.image ??
        (BackendService.isValidImageUrl(uploadedImageUrl)
            ? uploadedImageUrl
            : BackendService.generateFoodImageUrl(foodName));

    final String address =
        store?.address ?? (listing?['pickupAddressText'] ?? "Bangalore");
    final String orgName =
        store?.name ??
        (listing?['sellerProfileId']?['orgName'] ?? "Local Seller");

    final Map<String, double> reviews =
        store?.reviews ??
        {"Collection": 4.5, "Quality": 4.8, "Variety": 4.2, "Quantity": 4.7};

    // Use ingredients if available, else use a placeholder based on description
    final List<String> ingredients =
        store?.ingredients ??
        (listing?['description']?.toString().split(',') ??
            ["Organic", "Healthy", "Fresh"]);

    final bool offersDelivery =
        store?.offersDelivery ??
        (listing?['options']?['deliveryAvailable'] ?? true);

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
                  _buildHeaderInfo(
                    context,
                    type,
                    rating,
                    name,
                    address,
                    orgName,
                  ),
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
      floatingActionButton: _buildReserveButton(
        context,
        isFree,
        price,
        offersDelivery,
      ),
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
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer<AppAuthProvider>(
            builder: (context, auth, _) {
              final sellerId = listing?['sellerProfileId']?['userId'] ?? "";
              final profile = auth.mongoProfile;
              final List? favorites = profile?['favouriteSellers'];
              final bool isFavorited = favorites?.contains(sellerId) ?? false;

              return CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.white,
                    size: 20,
                  ),
                  onPressed: () async {
                    if (auth.currentUser == null || sellerId.isEmpty) return;
                    try {
                      await BackendService.toggleFavoriteSeller(
                        firebaseUid: auth.currentUser!.uid,
                        sellerId: sellerId,
                      );
                      await auth.refreshMongoUser();
                      if (context.mounted) {
                        AnimatedToast.show(
                          context,
                          isFavorited
                              ? "Removed restaurant from favorites"
                              : "Added restaurant to favorites",
                          type: isFavorited
                              ? ToastType.info
                              : ToastType.success,
                        );
                      }
                    } catch (e) {
                      debugPrint("Error toggling favorite restaurant: $e");
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 64),
                ),
              ),
            ),
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

  Widget _buildHeaderInfo(
    BuildContext context,
    String type,
    String rating,
    String name,
    String address,
    String orgName,
  ) {
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
        const SizedBox(height: 16),
        // Restaurant Name with Favorite Toggle
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              radius: 20,
              child: const Icon(
                Icons.store,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sold by",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    orgName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
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

  Widget _buildReviewSection(
    BuildContext context,
    String rating,
    Map<String, double> reviews,
  ) {
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

  // Removed old _buildReserveButton - using new integrated version below

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
                          builder: (context) => BuyerPaymentPage(
                            amount: (listing?['pricing']?['discountedPrice'] ?? 0).toDouble(),
                          ),
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
                          // This is the SnackBar that needs to be replaced, but the instruction
                          // specifies "favorite toggle" which is not present here.
                          // Assuming the user wants to replace this specific SnackBar with the provided AnimatedToast snippet,
                          // even though the message content is different.
                          // If the intent was to add a favorite toggle elsewhere, that code is missing.
                          if (context.mounted) {
                            AnimatedToast.show(
                              context,
                              "Checkout for real listings coming soon!", // Keeping original message
                              type: ToastType
                                  .info, // Using info as it's not success/error
                            );
                          }
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

  Widget _buildReserveButton(
    BuildContext context,
    bool isFree,
    String price,
    bool offersDelivery,
  ) {
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
          Builder(
            builder: (context) {
              final fromStr = listing?['pickupWindow']?['from'];
              final fromDt = fromStr != null
                  ? DateTime.tryParse(fromStr)
                  : null;
              bool _checkUpcoming(DateTime? start) {
                if (start == null) return false;
                final now = DateTime.now();
                if (!start.isAfter(now)) return false;

                // Healing legacy "tomorrow-shifted" bug listings
                if (start.difference(now).inHours < 24) {
                  final todayStart = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    start.hour,
                    start.minute,
                  );
                  if (!todayStart.isAfter(now)) return false;
                }
                return true;
              }

              final isUpcoming = _checkUpcoming(fromDt);

              return ElevatedButton(
                onPressed: () {
                  if (isUpcoming) {
                    _showRescueWindowCountdown(context, fromDt!);
                  } else {
                    _showOrderDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUpcoming
                      ? Colors.orange.shade700
                      : (isFree ? Colors.green : AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: isUpcoming ? 0 : 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUpcoming) ...[
                      const Icon(
                        Icons.lock_clock_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isUpcoming
                          ? 'Opens at ${DateFormat('hh:mm a').format(fromDt!)}'
                          : (isFree ? 'Claim Now' : 'Order Now'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context) {
    int quantity = 1;
    final maxQuantity = listing!['remainingQuantity'] ?? 1;
    final pricePerItem = (listing!['pricing']?['discountedPrice'] ?? 0)
        .toDouble();
    final isFree = listing!['pricing']?['isFree'] ?? false;

    int currentStep =
        1; // 1: Quantity, 2: Logistics, 3: Address (optional), 4: Summary/Matching
    String fulfillment = "self_pickup";
    Map<String, dynamic>? dropAddressData;
    final instructionsController = TextEditingController();
    bool isConsentGiven = false;
    String matchingStatus = "idle"; // idle, matching, matched, timeout
    Map<String, dynamic>? matchingOrder;
    int secondsLeft = 30;

    int totalSteps = fulfillment == "volunteer_delivery" ? 4 : 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isPlacing = false;
          double total = pricePerItem * quantity;
          totalSteps = fulfillment == "volunteer_delivery" ? 4 : 3;

          // Progress Bar Helper
          Widget buildProgressBar() {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Row(
                    children: List.generate(totalSteps, (index) {
                      final stepNum = index + 1;
                      final isActive = stepNum <= currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index == totalSteps - 1 ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $currentStep of $totalSteps',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currentStep == 1
                            ? 'Quantity'
                            : currentStep == 2
                            ? 'Logistics'
                            : currentStep == 3 &&
                                  fulfillment == "volunteer_delivery"
                            ? 'Address'
                            : 'Review',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Helper for Selection Item (Restored from main branch logic)
          Widget buildSelectionItem({
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
                  border: Border.all(
                    color: AppColors.textDark.withOpacity(0.05),
                  ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          }

          // Polling Timer logic
          void startMatching(Map<String, dynamic> order) {
            matchingOrder = order;
            setState(() {
              matchingStatus = "matching";
              secondsLeft = 30;
            });

            Future.doWhile(() async {
              if (matchingStatus != "matching") return false;
              if (secondsLeft <= 0) {
                setState(() => matchingStatus = "timeout");
                return false;
              }

              try {
                final updatedOrder = await BackendService.getOrderById(
                  order['_id'],
                );
                if (updatedOrder['status'] == 'volunteer_assigned' ||
                    updatedOrder['status'] == 'volunteer_accepted') {
                  setState(() {
                    matchingStatus = "matched";
                    matchingOrder = updatedOrder;
                  });
                  return false;
                }
                // Check if backend auto-switched to self_pickup
                if (updatedOrder['fulfillment'] == 'self_pickup' &&
                    updatedOrder['status'] == 'placed') {
                  setState(() {
                    matchingStatus = "timeout";
                    matchingOrder = updatedOrder;
                  });
                  return false;
                }
              } catch (e) {
                print("Polling error: $e");
              }

              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                setState(() => secondsLeft -= 2);
              }
              return true;
            });
          }

          Widget buildQuantityStep() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Quantity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                  'Max available: $maxQuantity',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }

          Widget buildLogisticsStep() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Delivery Method',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Self-Pickup'),
                  subtitle: const Text('You collect the food from donor'),
                  value: 'self_pickup',
                  groupValue: fulfillment,
                  onChanged: (val) => setState(() => fulfillment = val!),
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: const Text('Volunteer Delivery'),
                  subtitle: const Text('Request a volunteer for delivery'),
                  value: 'volunteer_delivery',
                  groupValue: fulfillment,
                  onChanged: (val) => setState(() => fulfillment = val!),
                  activeColor: AppColors.primary,
                ),
              ],
            );
          }

          Widget buildAddressStep() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                buildSelectionItem(
                  icon: Icons.location_on_outlined,
                  title: "Drop Location",
                  value:
                      dropAddressData?["addressText"] ??
                      "Tap to select address",
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuyerAddressPage(),
                      ),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      setState(() => dropAddressData = result);
                    }
                  },
                ),
                if (dropAddressData == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      'Please select a delivery address',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Special Instructions',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: instructionsController,
                  decoration: InputDecoration(
                    hintText: 'Gate code, floor, landmark...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                ),
              ],
            );
          }

          Widget buildMatchingUI() {
            if (matchingStatus == "matching") {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Finding a volunteer nearby...',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Time remaining: ${secondsLeft}s',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              );
            } else if (matchingStatus == "timeout") {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_off_outlined,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No volunteers found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We couldn\'t find a volunteer to deliver this order right now.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else if (matchingStatus == "matched") {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Volunteer Found!',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A volunteer has accepted your delivery request.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }

          Widget buildSummaryStep() {
            if (matchingStatus != "idle") return buildMatchingUI();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal ($quantity items):'),
                    Text(isFree ? 'FREE' : '₹$total'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Logistics:'),
                    Text(
                      fulfillment == 'self_pickup'
                          ? 'Self-Pickup'
                          : 'Volunteer Delivery',
                    ),
                  ],
                ),
                if (fulfillment == 'volunteer_delivery' &&
                    dropAddressData != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Drop At:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          dropAddressData!["addressText"],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (fulfillment == 'volunteer_delivery') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Est. Delivery Time:'),
                      Text(
                        '15-25 mins',
                        style: GoogleFonts.inter(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You will receive a 4-digit OTP to share with the volunteer for safe delivery.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isConsentGiven,
                        onChanged: (val) =>
                            setState(() => isConsentGiven = val!),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I understand this is surplus food and I will inspect it before consumption.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (matchingStatus == "idle") buildProgressBar(),
                currentStep == 1
                    ? buildQuantityStep()
                    : currentStep == 2
                    ? buildLogisticsStep()
                    : (currentStep == 3 && fulfillment == "volunteer_delivery")
                    ? buildAddressStep()
                    : buildSummaryStep(),
              ],
            ),
            actions: [
              if (currentStep > 1 && matchingStatus == "idle")
                TextButton(
                  onPressed: () => setState(() => currentStep--),
                  child: const Text('Back'),
                ),
              if (matchingStatus == "timeout")
                TextButton(
                  onPressed: () async {
                    if (matchingOrder == null) {
                      Navigator.pop(context);
                      return;
                    }
                    try {
                      await BackendService.cancelOrder(
                        matchingOrder!['_id'],
                        'buyer',
                        'No volunteer found — cancelled by buyer',
                      );
                      try {
                        Provider.of<AppAuthProvider>(context, listen: false).refreshMongoUser();
                      } catch (_) {}
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to cancel: ${e.toString().replaceAll("Exception: ", "")}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (currentStep < totalSteps)
                ElevatedButton(
                  onPressed: () {
                    if (currentStep == 3 &&
                        fulfillment == "volunteer_delivery" &&
                        dropAddressData == null) {
                      return;
                    }
                    setState(() => currentStep++);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (currentStep == totalSteps)
                ElevatedButton(
                  onPressed: isPlacing || !isConsentGiven
                      ? null
                      : () async {
                          if (matchingStatus == "idle") {
                            if (fulfillment == "volunteer_delivery") {
                              setState(() => isPlacing = true);
                              final response = await _createInitialOrder(
                                context,
                                quantity,
                                fulfillment,
                                dropAddressData: dropAddressData,
                                specialInstructions:
                                    instructionsController.text,
                              );
                              if (response != null) {
                                final order = response['order'];
                                setState(() {
                                  matchingOrder = order;
                                });
                                startMatching(order);
                                setState(() => isPlacing = false);
                              }
                            } else {
                              // Self Pickup logic
                              if (!isFree) {
                                final method = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BuyerPaymentPage(
                                      amount: total,
                                    ),
                                  ),
                                );
                                if (method == null) return;
                              }
                              setState(() => isPlacing = true);
                              await _placeOrder(
                                context,
                                quantity,
                                fulfillment,
                                dropAddressData: dropAddressData,
                                specialInstructions:
                                    instructionsController.text,
                              );
                            }
                          } else if (matchingStatus == "matched") {
                            if (!isFree) {
                              final method = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerPaymentPage(
                                    amount: total,
                                  ),
                                ),
                              );
                              if (method == null) return;
                              // Update order payment status
                              await BackendService.updateOrder(
                                matchingOrder!['_id'],
                                {
                                  "payment": {
                                    "status": "paid",
                                    "method": method,
                                  },
                                },
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerOrderConfirmationPage(
                                    order: {"order": matchingOrder!},
                                  ),
                                ),
                              );
                            }
                          } else if (matchingStatus == "timeout") {
                            // Switch to self-pickup
                            setState(() {
                              isPlacing = true;
                              fulfillment = "self_pickup";
                            });
                            await BackendService.updateOrder(
                              matchingOrder!['_id'],
                              {
                                "fulfillment": "self_pickup",
                                "status": "placed",
                              },
                            );
                            if (!isFree) {
                              final method = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerPaymentPage(
                                    amount: total,
                                  ),
                                ),
                              );
                              if (method != null) {
                                await BackendService.updateOrder(
                                  matchingOrder!['_id'],
                                  {
                                    "payment": {
                                      "status": "paid",
                                      "method": method,
                                    },
                                  },
                                );
                              }
                            }
                            if (context.mounted) {
                              final finalOrder =
                                  await BackendService.getOrderById(
                                    matchingOrder!['_id'],
                                  );
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerOrderConfirmationPage(
                                    order: {"order": finalOrder},
                                  ),
                                ),
                              );
                            }
                          }
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
                          matchingStatus == "idle"
                              ? (isFree ? 'Claim' : 'Confirm Order')
                              : matchingStatus == "timeout"
                              ? 'Switch to Pickup'
                              : 'Finalize Order',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _createInitialOrder(
    BuildContext context,
    int quantity,
    String fulfillment, {
    Map<String, dynamic>? dropAddressData,
    String? specialInstructions,
  }) async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final buyerId = authProvider.mongoUser?['_id'];
      if (buyerId == null) throw Exception('User not logged in');

      final discountedPrice =
          (listing!['pricing']?['discountedPrice'] ??
                  listing!['pricing']?['originalPrice'] ??
                  0)
              .toDouble();
      final itemTotal = discountedPrice * quantity;

      final orderData = {
        "listingId": listing!['_id'].toString(),
        "buyerId": buyerId.toString(),
        "quantityOrdered": quantity,
        "fulfillment": fulfillment,
        "specialInstructions": specialInstructions,
        "pickup": {
          "addressText":
              listing!['pickupAddressText'] ??
              listing!['pickupAddress']?['addressText'] ??
              'Pickup location',
          "scheduledAt": listing!['pickupWindow']?['to'],
          if (listing!['pickupGeo'] != null) "geo": listing!['pickupGeo'],
        },
        if (dropAddressData != null)
          "drop": {
            "addressText": dropAddressData["addressText"],
            if (dropAddressData["geo"] != null) "geo": dropAddressData["geo"],
          },
        "pricing": {
          "itemTotal": itemTotal,
          "deliveryFee": 0.0,
          "platformFee": 0.0,
          "total": itemTotal,
        },
      };

      return await BackendService.createOrder(orderData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
    int quantity,
    String fulfillment, {
    Map<String, dynamic>? dropAddressData,
    String? specialInstructions,
  }) async {
    try {
      // Get buyer ID from auth provider
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final buyerId = authProvider.mongoUser?['_id'];

      if (buyerId == null) {
        throw Exception('User not logged in');
      }

      // Ensure IDs are strings
      final listingIdStr = listing!['_id'].toString();
      final buyerIdStr = buyerId.toString();

      // Calculate pricing with fallbacks
      final discountedPrice =
          (listing!['pricing']?['discountedPrice'] ??
                  listing!['pricing']?['originalPrice'] ??
                  0)
              .toDouble();
      final itemTotal = discountedPrice * quantity;

      final orderData = {
        "listingId": listingIdStr,
        "buyerId": buyerIdStr,
        "quantityOrdered": quantity,
        "fulfillment": fulfillment,
        "specialInstructions": specialInstructions,
        "pickup": {
          "addressText":
              listing!['pickupAddressText'] ??
              listing!['pickupAddress']?['addressText'] ??
              'Pickup location',
          "scheduledAt": listing!['pickupWindow']?['to'],
          if (listing!['pickupGeo'] != null) "geo": listing!['pickupGeo'],
        },
        if (dropAddressData != null)
          "drop": {
            "addressText": dropAddressData["addressText"],
            if (dropAddressData["geo"] != null) "geo": dropAddressData["geo"],
          },
        "pricing": {
          "itemTotal": itemTotal,
          "deliveryFee": 0.0,
          "platformFee": 0.0,
          "total": itemTotal,
        },
      };

      // Debug: Print order data
      print("=== ORDER DATA ===");
      print("Order data: $orderData");
      print("Listing pricing: ${listing!['pricing']}");
      if (listing!['pickupGeo'] != null)
        print("Pickup Geo: ${listing!['pickupGeo']}");
      print("==================");

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

  void _showRescueWindowCountdown(BuildContext context, DateTime openTime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RescueCountdownContent(
        openTime: openTime,
        onOpened: () {
          if (context.mounted) {
            Navigator.pop(context);
            _showOrderDialog(context);
          }
        },
      ),
    );
  }
}

class _RescueCountdownContent extends StatefulWidget {
  final DateTime openTime;
  final VoidCallback onOpened;

  const _RescueCountdownContent({
    required this.openTime,
    required this.onOpened,
  });

  @override
  State<_RescueCountdownContent> createState() =>
      _RescueCountdownContentState();
}

class _RescueCountdownContentState extends State<_RescueCountdownContent> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _now = DateTime.now();
      });

      if (_now.isAfter(widget.openTime)) {
        timer.cancel();
        widget.onOpened();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.openTime.difference(_now);

    String timerStr = "";
    if (diff.isNegative) {
      timerStr = "0s";
    } else if (diff.inHours > 0) {
      timerStr =
          "${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s";
    } else if (diff.inMinutes > 0) {
      timerStr = "${diff.inMinutes}m ${diff.inSeconds % 60}s";
    } else {
      timerStr = "${diff.inSeconds}s";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 48,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Rescue Window Not Open Yet",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "This listing is part of a scheduled rescue window. You can place your order in:",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              timerStr,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Opens exactly at ${DateFormat('hh:mm a').format(widget.openTime)}",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Got it, I'll wait",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
