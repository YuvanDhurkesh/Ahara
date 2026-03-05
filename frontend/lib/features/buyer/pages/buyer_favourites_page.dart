import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/services/backend_service.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'buyer_food_detail_page.dart';
import '../../../shared/widgets/animated_toast.dart';
import '../data/mock_stores.dart';
import '../../../core/localization/app_localizations.dart';

class BuyerFavouritesPage extends StatefulWidget {
  final VoidCallback? onDiscoverMore;
  const BuyerFavouritesPage({super.key, this.onDiscoverMore});

  @override
  State<BuyerFavouritesPage> createState() => _BuyerFavouritesPageState();
}

class _BuyerFavouritesPageState extends State<BuyerFavouritesPage> {
  List<Map<String, dynamic>> _favoriteSellers = [];
  List<Map<String, dynamic>> _allActiveListings = [];
  bool _isLoading = true;
  String? _expandedSellerId;

  // Tracks the previous favouriteSellers snapshot to detect changes
  List<String> _lastFavIds = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AppAuthProvider>(context, listen: true);
    final List<dynamic> currentIds = auth.mongoProfile?['favouriteSellers'] ?? [];
    final List<String> currentIdStrs = currentIds.map((e) => e.toString()).toList();

    // Re-fetch only when the list actually changed
    if (!_listsEqual(_lastFavIds, currentIdStrs)) {
      _lastFavIds = currentIdStrs;
      // Don't call on very first load (initState handles that)
      if (!_isLoading) {
        _fetchFavorites();
      }
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _fetchInitialData() async {
    debugPrint("🟡 [Favourites] _fetchInitialData() called");
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchFavorites(),
      _fetchAllListings(),
    ]);
    if (mounted) setState(() => _isLoading = false);
    debugPrint("🟢 [Favourites] _fetchInitialData() done. Total sellers: ${_favoriteSellers.length}");
  }

  Future<void> _fetchAllListings() async {
    debugPrint("🔵 [Favourites] Fetching all active listings...");
    try {
      final listings = await BackendService.getAllActiveListings();
      debugPrint("🔵 [Favourites] Got ${listings.length} active listings from backend.");
      if (mounted) {
        setState(() => _allActiveListings = listings);
      }
    } catch (e) {
      debugPrint("🔴 [Favourites] Error fetching all listings: $e");
    }
  }

  Future<void> _fetchFavorites() async {
    debugPrint("⭐ [Favourites] _fetchFavorites() called");
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("🔴 [Favourites] No Firebase user found. Aborting.");
        return;
      }
      debugPrint("⭐ [Favourites] Firebase UID: ${user.uid}");

      // 1. Fetch real sellers from backend
      debugPrint("⭐ [Favourites] Calling BackendService.getFavoriteSellers...");
      final sellers = await BackendService.getFavoriteSellers(user.uid);
      debugPrint("⭐ [Favourites] Backend returned ${sellers.length} favorite sellers.");
      for (var s in sellers) {
        debugPrint("   ↳ Seller: orgName=${s['orgName']}, _id=${s['_id']}, userId=${s['userId']}");
      }

      // 2. Check mongo profile for favorite IDs (including mock stores)
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      final List<dynamic> favoriteIds = auth.mongoProfile?['favouriteSellers'] ?? [];
      debugPrint("⭐ [Favourites] mongoProfile favouriteSellers IDs: $favoriteIds");

      List<Map<String, dynamic>> combinedSellers = List.from(sellers);

      for (var id in favoriteIds) {
        final idStr = id.toString();
        debugPrint("   ↳ Checking ID: $idStr (type: ${id.runtimeType})");

        // Match store_ prefixed IDs (new format) OR plain numeric IDs (legacy format)
        final isStorePrefix = idStr.startsWith("store_");
        final isLegacyNumeric = int.tryParse(idStr) != null;

        if (isStorePrefix || isLegacyNumeric) {
          debugPrint("   ↳ Looks like a mock store ID. Searching allMockStores...");
          // Try exact match first (store_1), then try numeric match (1 -> store_1)
          final matches = allMockStores.where((s) =>
            s.id == idStr || s.id == "store_$idStr"
          ).toList();
          if (matches.isNotEmpty) {
            final mockStore = matches.first;
            debugPrint("   ✅ Found mock store: ${mockStore.name}");
            combinedSellers.add({
              '_id': mockStore.id,
              'orgName': mockStore.name,
              'isMock': true,
              'mockData': mockStore,
            });
          } else {
            debugPrint("   ❌ No mock store found with ID: $idStr");
          }
        } else {
          debugPrint("   → Skipping '$idStr' (real seller ID, handled by backend)");
        }
      }

      debugPrint("⭐ [Favourites] Combined total sellers to display: ${combinedSellers.length}");

      if (mounted) {
        setState(() {
          _favoriteSellers = combinedSellers;
        });
      }
    } catch (e) {
      debugPrint("🔴 [Favourites] Error fetching favorite sellers: $e");
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
      title: Text(
        AppLocalizations.of(context)!.translate("favorite_restaurants"),
        style: const TextStyle(
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
            AppLocalizations.of(context)!.translate("no_favorite_restaurants"),
            style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.translate("follow_favorites_desc"),
            style: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onDiscoverMore ?? () => _fetchFavorites(),
            icon: const Icon(Icons.search_rounded, size: 20, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.translate("discover_more"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    final bool isMock = seller['isMock'] ?? false;
    final sellerId = isMock ? seller['_id'] : ((seller['userId'] is Map ? seller['userId']['_id'] : seller['userId']) ?? seller['_id']);
    final orgName = seller['orgName'] ?? "Unknown Seller";
    
    final double rating = isMock 
        ? (double.tryParse((seller['mockData'] as MockStore).rating) ?? 0.0)
        : (seller['stats']?['avgRating'] ?? 0.0).toDouble();
        
    final address = isMock 
        ? "Mock Location, Ahara" 
        : (seller['businessAddressText'] ?? "No address provided");
        
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
              child: Icon(isMock ? Icons.store_outlined : Icons.store, color: AppColors.primary, size: 24),
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
                    (() {
                      final hasListings = isMock || _allActiveListings.any((l) {
                        final lSeller = l['sellerProfileId'];
                        if (lSeller is String) return lSeller == sellerId;
                        if (lSeller is Map) {
                          return lSeller['_id'] == sellerId || 
                                 (lSeller['userId'] is Map ? lSeller['userId']['_id'] : lSeller['userId']) == sellerId;
                        }
                        return false;
                      });
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasListings ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasListings ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasListings ? AppLocalizations.of(context)!.translate("LIVE") : AppLocalizations.of(context)!.translate("QUIET"),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: hasListings ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    })(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
                  onPressed: () async {
                    final auth = Provider.of<AppAuthProvider>(context, listen: false);
                    if (auth.currentUser == null) return;
                    
                    try {
                      await BackendService.toggleFavoriteSeller(
                        firebaseUid: auth.currentUser!.uid,
                        sellerId: sellerId!,
                      );
                      await auth.refreshMongoUser();
                      
                      if (mounted) {
                        AnimatedToast.show(
                          context,
                          "Removed $orgName from favorites",
                          type: ToastType.info,
                        );
                        _fetchInitialData(); // Refresh list and listings
                      }
                    } catch (e) {
                      debugPrint("Error removing favorite: $e");
                    }
                  },
                ),
                if (!isMock) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                      ),
                      Text(
                        isExpanded ? AppLocalizations.of(context)!.translate("close") : AppLocalizations.of(context)!.translate("items"),
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            onTap: isMock ? null : () {
              setState(() {
                _expandedSellerId = isExpanded ? null : sellerId;
              });
            },
          ),
          if (isExpanded && !isMock) _buildSellerListings(sellerId!),
        ],
      ),
    );
  }

  Widget _buildSellerListings(String sellerId) {
    final sellerListings = _allActiveListings
            .where((l) {
              final lSeller = l['sellerProfileId'];
              if (lSeller is String) return lSeller == sellerId;
              if (lSeller is Map) {
                return lSeller['_id'] == sellerId || 
                       (lSeller['userId'] is Map ? lSeller['userId']['_id'] : lSeller['userId']) == sellerId;
              }
              return false;
            })
            .toList();

    if (sellerListings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.textLight.withOpacity(0.5), size: 18),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.translate("no_active_listings"),
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
                  isFree ? AppLocalizations.of(context)!.translate("FREE") : "₹$price",
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
  }
}
