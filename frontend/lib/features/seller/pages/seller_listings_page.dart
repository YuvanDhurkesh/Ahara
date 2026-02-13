import 'package:flutter/material.dart';
import '../../../data/models/listing_model.dart';
import '../../../shared/styles/app_colors.dart';
import 'create_listing_page.dart';

class SellerListingsPage extends StatelessWidget {
  const SellerListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for demonstration
    final List<Listing> mockListings = [
      Listing(
        id: "1",
        foodName: "Mixed Veg Curry",
        foodType: FoodType.prepared_meal,
        quantityValue: 5,
        quantityUnit: "portions",
        redistributionMode: RedistributionMode.free,
        preparedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiryTime: DateTime.now().add(const Duration(hours: 4)),
        hygieneStatus: HygieneStatus.excellent,
        locationAddress: "123 Green Lane, Eco City",
        latitude: 0,
        longitude: 0,
        imageUrl:
            "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80",
        description:
            "Freshly prepared mixed vegetable curry with aromatic spices.",
        status: ListingStatus.active,
      ),
      Listing(
        id: "2",
        foodName: "Organic Carrots",
        foodType: FoodType.fresh_produce,
        quantityValue: 2,
        quantityUnit: "kg",
        redistributionMode: RedistributionMode.discounted,
        price: 45.0,
        preparedAt: DateTime.now().subtract(const Duration(days: 1)),
        expiryTime: DateTime.now().add(const Duration(days: 1)),
        hygieneStatus: HygieneStatus.good,
        locationAddress: "Farm Stand 5, Rural Road",
        latitude: 0,
        longitude: 0,
        imageUrl:
            "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&q=80",
        description: "Crunchy organic carrots from local farm.",
        status: ListingStatus.active,
      ),
      Listing(
        id: "3",
        foodName: "Whole Wheat Bread",
        foodType: FoodType.bakery_item,
        quantityValue: 3,
        quantityUnit: "pieces",
        redistributionMode: RedistributionMode.free,
        preparedAt: DateTime.now().subtract(const Duration(hours: 5)),
        expiryTime: DateTime.now().add(const Duration(hours: 19)),
        hygieneStatus: HygieneStatus.excellent,
        locationAddress: "Village Bakery, Main St",
        latitude: 0,
        longitude: 0,
        imageUrl:
            "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80",
        description: "Freshly baked whole wheat bread loaf.",
        status: ListingStatus.active,
      ),
    ];

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Active"),
                Tab(text: "Completed"),
                Tab(text: "Expired"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListingList(context, mockListings, ListingStatus.active),
                _buildListingList(context, mockListings, ListingStatus.claimed),
                _buildListingList(context, mockListings, ListingStatus.expired),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingList(
    BuildContext context,
    List<Listing> listings,
    ListingStatus status,
  ) {
    final filteredListings = listings.where((l) => l.status == status).toList();

    if (filteredListings.isEmpty) {
      return _buildEmptyState(context, status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredListings.length,
      itemBuilder: (context, index) {
        return _buildListingCard(context, filteredListings[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ListingStatus status) {
    String message = "No listings yet";
    if (status == ListingStatus.claimed) message = "No completed listings";
    if (status == ListingStatus.expired) message = "No expired listings";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textLight.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          if (status == ListingStatus.active)
            Text(
              "Start by creating your first food listing",
              style: TextStyle(color: AppColors.textLight.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, Listing listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                listing.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: AppColors.textLight.withOpacity(0.1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: listing.redistributionMode == RedistributionMode.free
                        ? Colors.green.withOpacity(0.9)
                        : AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    listing.redistributionMode == RedistributionMode.free
                        ? "FREE"
                        : "₹${listing.price?.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        listing.foodName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.foodType.name
                                .replaceAll('_', ' ')
                                .substring(0, 1)
                                .toUpperCase() +
                            listing.foodType.name
                                .replaceAll('_', ' ')
                                .substring(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.scale_outlined,
                      size: 16,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${listing.quantityValue} ${listing.quantityUnit}",
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Expires in ${_formatDuration(listing.expiryTime.difference(DateTime.now()))}",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hygiene Status",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.hygieneStatus.name
                                  .substring(0, 1)
                                  .toUpperCase() +
                              listing.hygieneStatus.name.substring(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateListingPage(listing: listing),
                              ),
                            );
                          },
                          child: const Text("Edit"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.primary),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return "${duration.inDays}d";
    if (duration.inHours > 0) return "${duration.inHours}h";
    return "${duration.inMinutes}m";
  }
}
