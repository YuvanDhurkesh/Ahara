import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';
import '../../common/pages/landing_page.dart';
import 'buyer_food_detail_page.dart';
import 'buyer_notifications_page.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../data/services/backend_service.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/animated_toast.dart';
import '../../../shared/utils/location_util.dart';
import 'package:geolocator/geolocator.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  String _mainCategory = "All";
  String _subCategory = "All";

  // Real listings state
  List<Map<String, dynamic>> _realListings = [];
  bool _isLoading = false;

  // Live countdown state
  DateTime _now = DateTime.now();
  Timer? _countdownTimer;

  // 🔥 User location state
  String _userLocation = "Detecting location...";
  Position? _livePosition;
  String _firebaseUid = "";

  final List<String> _mainCategories = ["All", "Free", "Discounted"];
  final List<String> _categories = [
    "All",
    "Meals",
    "Bread & pastries",
    "Groceries",
    "Pet food",
    "Vegan",
    "Vegetarian",
    "Non-vegetarian",
    "Jain",
  ];

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firebaseUid = user.uid;
      _initLocation();
    }

    _fetchRealListings();

    // Update countdown every 30 seconds
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  Future<void> _initLocation() async {
    // 1. Try to get live location first
    final Position? position = await LocationUtil.getCurrentLocation();
    if (position != null) {
      if (mounted) {
        setState(() => _livePosition = position);
      }
      final city = await LocationUtil.getAddressFromCoords(position.latitude, position.longitude);
      if (city != null && mounted) {
        setState(() => _userLocation = "Current Location: $city");
        return; 
      }
    }

    // 2. Fallback to Profile Location
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final response = await BackendService.getUserProfile(_firebaseUid);
      if (mounted) {
        setState(() {
          _userLocation = response['user']?['addressText'] ?? "Unknown location";
        });
      }
    } catch (e) {
      debugPrint("Location fetch error: $e");
      if (mounted) {
        setState(() {
          _userLocation = "Location unavailable";
        });
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRealListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await BackendService.getAllActiveListings();
      if (mounted) {
        setState(() {
          _realListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching listings: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filter out expired listings
  List<Map<String, dynamic>> get _validListings {
    final now = DateTime.now();
    return _realListings.where((listing) {
      final expiryStr = listing['pickupWindow']?['to'];
      if (expiryStr == null) return false;
      try {
        final expiry = DateTime.parse(expiryStr);
        return expiry.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String _formatTimeRemaining(DateTime expiryTime) {
    final diff = expiryTime.difference(_now);
    if (diff.isNegative) return "Expired";
    if (diff.inDays > 0) return "${diff.inDays}d ${diff.inHours % 24}h";
    if (diff.inHours > 0) return "${diff.inHours}h ${diff.inMinutes % 60}m";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Soon";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    
    final allItems = <dynamic>[
      ..._validListings,
      ...allMockStores,
    ];
    
    final List<String> dietaryPrefs = List<String>.from(auth.mongoProfile?['dietaryPreferences'] ?? []);

    final filteredItems = allItems.where((item) {
      final isMock = item is MockStore;

      // 1. Filter by Main Category (Free/Discounted)
      bool matchesMain = true;
      if (_mainCategory == "Free") {
        matchesMain = isMock ? item.isFree : (item['pricing']?['isFree'] ?? false);
      } else if (_mainCategory == "Discounted") {
        matchesMain = isMock
            ? (item.discount != null)
            : ((item['pricing']?['originalPrice'] ?? 0) > (item['pricing']?['discountedPrice'] ?? 0));
      }

      // 2. Filter by Sub Category (Meals, Groceries, etc.)
      bool matchesSub = true;
      if (_subCategory != "All") {
        if (isMock) {
          final String subLower = _subCategory.toLowerCase();
          final String catLower = item.category.toLowerCase();
          
          if (subLower == "meals") {
            matchesSub = catLower.contains("meals") || catLower.contains("cafe") || catLower.contains("restaurant");
          } else if (subLower == "bread & pastries") {
            matchesSub = catLower.contains("bakery") || catLower.contains("pastry");
          } else if (subLower == "groceries") {
            matchesSub = catLower.contains("grocery") || catLower.contains("supermarket") || catLower.contains("pet food");
          } else if (subLower == "vegan") {
            matchesSub = catLower.contains("vegan");
          } else if (subLower == "vegetarian") {
            matchesSub = catLower.contains("vegetarian") || catLower.contains("veg") || catLower.contains("vegan") || catLower.contains("jain");
          } else if (subLower == "non-vegetarian") {
            matchesSub = catLower.contains("non-veg") || catLower.contains("steak") || catLower.contains("grill");
          } else {
            matchesSub = (item.category == _subCategory);
          }
        } else {
          final String dietaryType = (item['dietaryType'] ?? "").toString().toLowerCase();
          final String foodType = (item['foodType'] ?? "").toString();
          
          final String subLower = _subCategory.toLowerCase();
          if (subLower == "non-vegetarian") {
            matchesSub = (dietaryType == "non_veg" || foodType == "non_veg");
          } else if (subLower == "vegetarian") {
            matchesSub = (dietaryType == "vegetarian" || foodType == "vegetarian");
          } else if (subLower == "vegan") {
            matchesSub = (dietaryType == "vegan" || foodType == "vegan");
          } else if (subLower == "jain") {
            matchesSub = (dietaryType == "jain" || foodType == "jain");
          } else if (subLower == "meals") {
            matchesSub = (foodType == "prepared_meal");
          } else if (subLower == "bread & pastries") {
            matchesSub = (foodType == "bakery_item");
          } else if (subLower == "groceries") {
            matchesSub = (foodType == "fresh_produce" || foodType == "packaged_food" || foodType == "dairy_product");
          } else {
            matchesSub = (foodType == _subCategory);
          }
        }
      }

      // 3. Filter by User Dietary Preferences
      bool matchesDietary = true;
      if (dietaryPrefs.isNotEmpty) {
        String itemDietary = "vegetarian"; 
        if (isMock) {
          final cat = item.category.toLowerCase();
          if (cat.contains("vegan")) itemDietary = "vegan";
          else if (cat.contains("non-veg")) itemDietary = "non_veg";
          else if (cat.contains("vegetarian")) itemDietary = "vegetarian";
          else if (cat.contains("jain")) itemDietary = "jain";
        } else {
          itemDietary = (item['dietaryType'] ?? "vegetarian").toString().toLowerCase();
        }
        
        if (dietaryPrefs.length == 1) {
          final pref = dietaryPrefs.first;
          if (pref == "vegan" && itemDietary != "vegan") matchesDietary = false;
          if (pref == "jain" && itemDietary != "jain") matchesDietary = false;
          if (pref == "vegetarian" && (itemDietary == "non_veg")) matchesDietary = false;
          if (pref == "non_veg" && itemDietary != "non_veg") matchesDietary = false;
        } else {
          if (dietaryPrefs.contains("vegan") && !dietaryPrefs.contains("non_veg")) {
             if (itemDietary == "non_veg") matchesDietary = false;
          }
           if (dietaryPrefs.contains("vegetarian") && !dietaryPrefs.contains("non_veg")) {
             if (itemDietary == "non_veg") matchesDietary = false;
          }
        }
      }

      return matchesMain && matchesSub && matchesDietary;
    }).toList();

    // 4. Sort by Proximity to Live Position
    if (_livePosition != null) {
      filteredItems.sort((a, b) {
        double distA = 9999.0;
        double distB = 9999.0;

        if (a is! MockStore) {
          final coords = a['pickupGeo']?['coordinates'];
          if (coords != null && coords is List && coords.length >= 2) {
            distA = LocationUtil.calculateDistance(_livePosition!.latitude, _livePosition!.longitude, (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          }
        } else {
           distA = LocationUtil.calculateDistance(_livePosition!.latitude, _livePosition!.longitude, 12.9716, 77.5946);
        }

        if (b is! MockStore) {
          final coords = b['pickupGeo']?['coordinates'];
          if (coords != null && coords is List && coords.length >= 2) {
            distB = LocationUtil.calculateDistance(_livePosition!.latitude, _livePosition!.longitude, (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          }
        } else {
           distB = LocationUtil.calculateDistance(_livePosition!.latitude, _livePosition!.longitude, 12.9716, 77.5946);
        }
        return distA.compareTo(distB);
      });
    }

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildMainCategoryTabs(),
          const SizedBox(height: 8),
          _buildCategoryTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchRealListings,
                    child: filteredItems.isEmpty
                        ? _buildEmptyState()
                        : ResponsiveLayout(
                            mobile: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildItemCard(filteredItems[index]),
                                );
                              },
                            ),
                            tablet: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.1,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return _buildItemCard(filteredItems[index]);
                              },
                            ),
                            desktop: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return _buildItemCard(filteredItems[index]);
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 64, color: AppColors.textLight.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate("no_places_found"),
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _userLocation,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
<<<<<<< HEAD
                  ),

                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 🔥 Dynamic Discover Title
              Text(
                _userLocation == "Detecting location..."
                    ? AppLocalizations.of(context)!.translate("discover") ?? "Discover"
                    : (_livePosition != null 
                        ? (AppLocalizations.of(context)!.translate("discover_near_you") ?? "Discover Near You")
                        : "${AppLocalizations.of(context)!.translate("discover") ?? "Discover"} ${_userLocation.split(',').last.trim()}"),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
=======
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 14),
                  ],
>>>>>>> origin/main
                ),
                const SizedBox(height: 4),
                Text(
                  _userLocation == "Detecting location..."
                      ? "Discover"
                      : (_livePosition != null ? "Discover Near You" : "Discover ${_userLocation.split(',').last.trim()}"),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerNotificationsPage()));
            },
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 22),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
            },
            icon: const Icon(Icons.logout, color: AppColors.textDark, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _mainCategories.map((category) {
          final isSelected = _mainCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mainCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate(category.toLowerCase()),
                    style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _subCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _subCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: isSelected ? AppColors.secondary : AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate(category.toLowerCase().replaceAll(" & ", "_")),
                    style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark.withOpacity(0.6), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    if (item is MockStore) {
      return _buildRestaurantCard(item);
    } else {
      return _buildRealListingCard(item as Map<String, dynamic>);
    }
  }

  Widget _buildRealListingCard(Map<String, dynamic> listing) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final String name = langProvider.getTranslatedText(context, listing, 'foodName');
    final pricing = listing['pricing'] ?? {};
    final bool isFree = pricing['isFree'] ?? false;
    final int price = pricing['discountedPrice'] ?? 0;
    final int? originalPrice = pricing['originalPrice'];

    final sellerProfile = listing['sellerProfileId'] ?? {};
    final String orgName = sellerProfile['orgName'] ?? "Local Seller";
    final double rating = (sellerProfile['stats']?['avgRating'] ?? 0.0).toDouble();

    final String? expiryStr = listing['pickupWindow']?['to'];
    final DateTime? expiryTime = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

    final String? pickupFromStr = listing['pickupWindow']?['from'];
    final DateTime? pickupFrom = pickupFromStr != null ? DateTime.tryParse(pickupFromStr) : null;

    bool _checkUpcoming(DateTime? start) {
      if (start == null) return false;
      if (!start.isAfter(_now)) return false;
      if (start.difference(_now).inHours < 24) {
        final todayStart = DateTime(_now.year, _now.month, _now.day, start.hour, start.minute);
        if (!todayStart.isAfter(_now)) return false;
      }
      return true;
    }

    final bool isRescueUpcoming = _checkUpcoming(pickupFrom);

    String _fmt12(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    }

    final List images = listing['images'] ?? [];
    final String uploadedImageUrl = images.isNotEmpty ? BackendService.formatImageUrl(images[0]) : "";
    final String imageUrl = BackendService.isValidImageUrl(uploadedImageUrl) ? uploadedImageUrl : BackendService.generateFoodImageUrl(name);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BuyerFoodDetailPage(listing: listing)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(height: 180, color: AppColors.textLight.withOpacity(0.05), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                    },
                    errorBuilder: (context, error, stackTrace) => Container(height: 180, width: double.infinity, color: AppColors.textLight.withOpacity(0.05), child: Icon(Icons.image_not_supported_outlined, color: AppColors.textLight.withOpacity(0.2), size: 32)),
                  ),
                ),
                if (isFree)
                  Positioned(
<<<<<<< HEAD
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate("free").toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
=======
                    top: 12, left: 12,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)), child: const Text("FREE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
>>>>>>> origin/main
                  ),
                if (rating > 0)
                  Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]))),
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
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (originalPrice != null && originalPrice > price)
                            Text(
                              "₹$originalPrice",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight.withOpacity(0.5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            isFree ? AppLocalizations.of(context)!.translate("free").toUpperCase() : "₹$price",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isFree ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (isRescueUpcoming)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFFB45309)), const SizedBox(width: 4), Text('${AppLocalizations.of(context)!.translate("opens_at")} ${_fmt12(pickupFrom!)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)))]),
                              )
                            else if (expiryTime != null)
                              _buildIconLabel(Icons.timer_outlined, "${AppLocalizations.of(context)!.translate("ends_in")}${_formatTimeRemaining(expiryTime)}"),
                            _buildIconLabel(Icons.store, orgName),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isRescueUpcoming)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_clock_outlined, size: 13, color: Colors.grey.shade500), const SizedBox(width: 4), Text(AppLocalizations.of(context)!.translate("locked") ?? 'Locked', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold))]))
                      else
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isFree ? Colors.green : AppColors.primary, borderRadius: BorderRadius.circular(12)), child: Text(isFree ? (AppLocalizations.of(context)!.translate("claim_now") ?? 'Claim Now') : (AppLocalizations.of(context)!.translate("reserve") ?? 'Reserve'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(MockStore store) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BuyerFoodDetailPage(store: store)));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    store.image, height: 180, width: double.infinity, fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(height: 180, color: AppColors.textLight.withOpacity(0.05), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorBuilder: (context, error, stackTrace) => Container(height: 180, color: AppColors.textLight.withOpacity(0.05), child: Icon(Icons.image_not_supported_outlined, color: AppColors.textLight.withOpacity(0.2), size: 32)),
                  ),
                ),
                Positioned(
<<<<<<< HEAD
                  top: 12,
                  left: 12,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (store.discount != null)
                        _buildSpecialBadge(store.discount!, Colors.orange),
                      if (store.isFree)
                        _buildSpecialBadge(AppLocalizations.of(context)!.translate("free").toUpperCase(), Colors.green),
                      ...store.badges
                          .map((badge) => _buildBadge(badge))
                          .toList(),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<AppAuthProvider>(
                    builder: (context, auth, _) {
                      final profile = auth.mongoProfile;
                    final List? favorites = profile?['favouriteSellers'];
                    // Mock stores don't have MongoDB listings, so we use their ID
                    // Note: This might fail on backend if store.id is not a valid ObjectId
                    // but we'll use it to trigger the UI and toast for consistency.
                    final bool isFavorited = favorites?.contains(store.id) ?? false;

                    return GestureDetector(
                      onTap: () async {
                        if (auth.currentUser == null) return;
                        try {
                          await BackendService.toggleFavoriteSeller(
                              firebaseUid: auth.currentUser!.uid,
                              sellerId: store.id);
                          await auth.refreshMongoUser();
                          if (mounted) {
                            AnimatedToast.show(
                              context,
                              isFavorited ? "Removed restaurant from favorites" : "Added restaurant to favorites",
                              type: isFavorited ? ToastType.info : ToastType.success,
                            );
                          }
                        } catch (e) {
                          debugPrint("Error toggling favorite for mock store: $e");
                        }
                      },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_outline,
                            color: isFavorited
                                ? Colors.red
                                : AppColors.textLight.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          store.rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
=======
                  top: 12, left: 12,
                  child: Wrap(spacing: 6, runSpacing: 6, children: [if (store.discount != null) _buildSpecialBadge(store.discount!, Colors.orange), if (store.isFree) _buildSpecialBadge("FREE", Colors.green), ...store.badges.map((badge) => _buildBadge(badge)).toList()]),
>>>>>>> origin/main
                ),
                Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(store.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]))),
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
                      Expanded(child: Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (store.oldPrice != null) Text(store.oldPrice!, style: TextStyle(fontSize: 12, color: AppColors.textLight.withOpacity(0.5), decoration: TextDecoration.lineThrough)),
                          Text(store.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: store.isFree ? Colors.green : AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildIconLabel(Icons.timer_outlined, "${AppLocalizations.of(context)!.translate("ends_in")}2h"),
                            _buildIconLabel(Icons.directions_walk, "1.2 km"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: store.isFree
                              ? Colors.green
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          store.isFree 
                              ? AppLocalizations.of(context)!.translate("claim_now")
                              : AppLocalizations.of(context)!.translate("reserve"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.dark.withOpacity(0.7)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2))));
  }

  Widget _buildSpecialBadge(String text, Color color) {
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))));
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textLight.withOpacity(0.5)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
