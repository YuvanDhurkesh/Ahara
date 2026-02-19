import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<dynamic> _favouriteListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavourites();
  }

  Future<void> _fetchFavourites() async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    if (auth.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final listings = await BackendService.getFavoriteListings(auth.currentUser!.uid);
      if (mounted) {
        setState(() {
          _favouriteListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching favourites: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _favouriteListings.isEmpty
        ? _buildEmptyState()
        : RefreshIndicator(
            onRefresh: _fetchFavourites,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _favouriteListings.length,
              itemBuilder: (context, index) {
                return _buildFavouriteCard(_favouriteListings[index]);
              },
            ),
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppColors.textLight.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Your favourites list is empty",
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Heart a food item to save it here!",
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchFavourites,
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

  Widget _buildFavouriteCard(Map<String, dynamic> listing) {
    final List images = listing['images'] ?? [];
    final String foodName = listing['foodName'] ?? "Food Item";
    final String uploadedImageUrl = images.isNotEmpty 
        ? BackendService.formatImageUrl(images[0])
        : "";
    
    final String imageUrl = BackendService.isValidImageUrl(uploadedImageUrl)
        ? uploadedImageUrl
        : BackendService.generateFoodImageUrl(foodName);

    final pricing = listing['pricing'] ?? {};
    final bool isFree = pricing['isFree'] ?? false;
    final int price = pricing['discountedPrice'] ?? 0;
    final sellerProfile = listing['sellerProfileId'] ?? {};
    final String orgName = sellerProfile['orgName'] ?? "Local Seller";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerFoodDetailPage(listing: listing),
          ),
        ).then((_) => _fetchFavourites()); // Refresh when coming back
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orgName,
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFree ? "FREE" : "₹$price",
                          style: TextStyle(
                            color: isFree ? Colors.green : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                          onPressed: () async {
                            final auth = Provider.of<AppAuthProvider>(context, listen: false);
                            if (auth.currentUser == null) return;
                            try {
                              await BackendService.toggleFavoriteListing(
                                firebaseUid: auth.currentUser!.uid,
                                listingId: listing['_id'] ?? listing['id'],
                              );
                              await auth.refreshMongoUser();
                              _fetchFavourites();
                            } catch (e) {
                              debugPrint("Error unfavoriting: $e");
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
