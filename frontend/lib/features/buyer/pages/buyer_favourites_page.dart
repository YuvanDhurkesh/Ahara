import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/services/backend_service.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'buyer_food_detail_page.dart';

class BuyerFavouritesPage extends StatefulWidget {
  const BuyerFavouritesPage({super.key});

  @override
  State<BuyerFavouritesPage> createState() => _BuyerFavouritesPageState();
}

class _BuyerFavouritesPageState extends State<BuyerFavouritesPage> {
  List<Map<String, dynamic>> _favoriteSellers = [];
  bool _isLoading = true;
  String? _expandedSellerId;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final sellers = await BackendService.getFavoriteSellers(user.uid);
        if (mounted) {
          setState(() {
            _favoriteSellers = sellers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching favorite sellers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: _favoriteSellers.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSellerCard(_favoriteSellers[index]),
                      childCount: _favoriteSellers.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Favorite Restaurants",
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: AppColors.textLight.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "No favorite restaurants yet",
            style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Follow your favorite places to see their items here!",
            style: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchFavorites,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Refresh", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    final sellerId = seller['userId']?['_id'] ?? seller['userId'];
    final orgName = seller['orgName'] ?? "Unknown Seller";
    final rating = (seller['stats']?['avgRating'] ?? 0.0).toDouble();
    final address = seller['businessAddressText'] ?? "No address provided";
    final isExpanded = _expandedSellerId == sellerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.store, color: AppColors.primary, size: 24),
            ),
            title: Text(
              orgName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, color: AppColors.textLight.withOpacity(0.4), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(fontSize: 12, color: AppColors.textLight.withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
                Text(
                  isExpanded ? "Close" : "View Items",
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedSellerId = isExpanded ? null : sellerId;
              });
            },
          ),
          if (isExpanded) _buildSellerListings(sellerId),
        ],
      ),
    );
  }

  Widget _buildSellerListings(String sellerId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: BackendService.getAllActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final sellerListings = snapshot.data
                ?.where((l) => (l['sellerProfileId']?['userId'] ?? l['sellerProfileId']) == sellerId)
                .toList() ??
            [];

        if (sellerListings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppColors.textLight.withOpacity(0.5), size: 18),
                const SizedBox(width: 8),
                Text(
                  "No active listings currently",
                  style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textLight.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sellerListings.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.textDark.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final listing = sellerListings[index];
              final pricing = listing['pricing'] ?? {};
              final bool isFree = pricing['isFree'] ?? false;
              final int price = pricing['discountedPrice'] ?? 0;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyerFoodDetailPage(listing: listing),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    BackendService.formatImageUrl(listing['images']?.isNotEmpty == true ? listing['images'][0] : null),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.textLight.withOpacity(0.1),
                      child: Icon(Icons.fastfood, size: 24, color: AppColors.textLight.withOpacity(0.3)),
                    ),
                  ),
                ),
                title: Text(
                  listing['foodName'] ?? "Unnamed Item",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  isFree ? "FREE" : "₹$price",
                  style: TextStyle(
                    color: isFree ? Colors.green : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
