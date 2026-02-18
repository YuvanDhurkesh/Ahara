/// File: seller_listings_page.dart
/// Purpose: Comprehensive management interface for a seller's food inventory.
/// 
/// Responsibilities:
/// - Fetches and categorizes listings by operational state (Active, Expired, Claimed)
/// - Implements real-time countdown logic for food safety monitoring
/// - Orchestrates relisting and editing flows for inventory items
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'create_listing_page.dart';

/// Tab-based overview of all food items donated or sold by the user.
/// 
/// Features:
/// - Dynamic filtering based on live time-of-flight (expiry)
/// - Multi-status tabs (Active/Completed/Expired)
/// - Integration with [CreateListingPage] for inventory expansion
class SellerListingsPage extends StatefulWidget {
  const SellerListingsPage({super.key});

  @override
  State<SellerListingsPage> createState() => _SellerListingsPageState();
}

class _SellerListingsPageState extends State<SellerListingsPage> {
  List<Listing> _allListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Real-time state for dynamic expiry
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchListings();
    // Update timer every 10 seconds for live countdown
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final firebaseUser = authProvider.currentUser;

      if (firebaseUser == null) {
        throw Exception("No user logged in");
      }

      // 1. Get Mongo Seller ID
      final profileData = await BackendService.getUserProfile(firebaseUser.uid);
      final mongoSellerId = profileData['user']['_id'];

      // 2. Fetch all listings (we'll filter client-side for real-time updates)
      final activeJson = await BackendService.getSellerListings(mongoSellerId, 'active');
      final completedJson = await BackendService.getSellerListings(mongoSellerId, 'completed');
      final expiredJson = await BackendService.getSellerListings(mongoSellerId, 'expired');

      if (mounted) {
        setState(() {
          // Combine all into _allListings for dynamic filtering
          _allListings = [
            ...activeJson.map((j) => Listing.fromJson(j)),
            ...completedJson.map((j) => Listing.fromJson(j)),
            ...expiredJson.map((j) => Listing.fromJson(j)),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Dynamic getters for real-time filtering
  List<Listing> get _activeListings {
    return _allListings.where((l) {
      return l.expiryTime.isAfter(_now) && 
             l.status != ListingStatus.claimed &&
             (l.quantityValue > 0);
    }).toList();
  }

  List<Listing> get _expiredListings {
    return _allListings.where((l) {
      return (l.expiryTime.isBefore(_now) || l.expiryTime.isAtSameMomentAs(_now)) &&
             l.status != ListingStatus.claimed;
    }).toList();
  }

  /// Returns listings that have been successfully fulfilled or claimed.
  List<Listing> get _completedListings {
    return _allListings.where((l) => l.status == ListingStatus.claimed).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            "My Listings",
            style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textDark,
          bottom: const TabBar(
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateListingPage(),
                    ),
                  );
                  _fetchListings(); // Refresh after return
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Listing"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            IconButton(
              onPressed: _fetchListings,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text("Error: $_errorMessage"))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: TabBarView(
                        children: [
                          _buildListingList(context, _activeListings, ListingStatus.active),
                          _buildListingList(context, _completedListings, ListingStatus.claimed), // Backend uses 'completed' or remainingQuantity: 0
                          _buildListingList(context, _expiredListings, ListingStatus.expired),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildListingList(
    BuildContext context,
    List<Listing> listings,
    ListingStatus status,
  ) {
    if (listings.isEmpty) {
      return _buildEmptyState(context, status);
    }

    return RefreshIndicator(
      onRefresh: _fetchListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return _buildListingCard(context, listings[index]);
        },
      ),
    );
  }

  /// Triggers a modal to update the availability window for an expired listing.
  Future<void> _showRelistDialog(Listing listing) async {
    DateTime? newFrom;
    DateTime? newTo;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Relist Listing"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Relist: ${listing.foodName}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 7)),
                );
                if (picked != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    newFrom = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                  }
                }
              },
              child: Text(newFrom == null ? "Select Start Time" : "From: ${newFrom!.toString().substring(0, 16)}"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(hours: 2)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 7)),
                );
                if (picked != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    newTo = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                  }
                }
              },
              child: Text(newTo == null ? "Select End Time" : "To: ${newTo!.toString().substring(0, 16)}"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (newFrom != null && newTo != null) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select both start and end times")),
                );
              }
            },
            child: const Text("Relist"),
          ),
        ],
      ),
    );

    if (result == true && newFrom != null && newTo != null) {
      try {
        await BackendService.relistListing(listing.id, {
          "from": newFrom!.toIso8601String(),
          "to": newTo!.toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Listing relisted successfully!")),
          );
          _fetchListings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to relist: $e")),
          );
        }
      }
    }
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.textLight.withOpacity(0.1),
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: AppColors.textLight,
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, Listing listing) {
    final bool isExpired = _now.isAfter(listing.expiryTime);
    
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: listing.imageUrl.isNotEmpty 
                  ? Image.network(
                      BackendService.formatImageUrl(listing.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
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
                    gradient: LinearGradient(
                      colors: listing.redistributionMode == RedistributionMode.free
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        listing.redistributionMode == RedistributionMode.free 
                          ? Icons.volunteer_activism_outlined 
                          : Icons.currency_rupee_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.redistributionMode == RedistributionMode.free
                            ? "FREE"
                            : listing.price?.toStringAsFixed(0) ?? "0",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
                      _now.isBefore(listing.expiryTime)
                          ? "Expires in ${_formatDuration(listing.expiryTime.difference(_now))}"
                          : "Expired ${_formatDuration(_now.difference(listing.expiryTime))} ago",
                      style: TextStyle(
                        color: _now.isBefore(listing.expiryTime) 
                            ? Colors.orange.shade700 
                            : Colors.red,
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
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateListingPage(listing: listing),
                              ),
                            );
                            _fetchListings();
                          },
                          child: const Text("Edit"),
                        ),
                        const SizedBox(width: 4),
                        if (isExpired)
                          ElevatedButton.icon(
                            onPressed: () => _showRelistDialog(listing),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Relist"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
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
