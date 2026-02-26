import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';
import 'buyer_food_detail_page.dart';
import '../../../data/services/backend_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/animated_toast.dart';
import '../../../shared/utils/location_util.dart';
import 'package:geolocator/geolocator.dart';

class BuyerBrowsePage extends StatefulWidget {
  const BuyerBrowsePage({super.key});

  @override
  State<BuyerBrowsePage> createState() => _BuyerBrowsePageState();
}

class _BuyerBrowsePageState extends State<BuyerBrowsePage> {
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final MapController _mapController = MapController();

  // Filter States
  String _searchQuery = "";
  double _minRating = 0.0;
  bool _onlyFree = false;

  // Map Interaction State
  String? _selectedStoreId;
  bool _showSearchInArea = false;
  bool _hasVisibleResults = true;
  LatLng? _lastCenter;
  Position? _livePosition;

  // Real Data State
  List<Map<String, dynamic>> _realListings = [];
  bool _isListingsLoading = false;
  
  // Live countdown state
  DateTime _now = DateTime.now();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchRealListings();
    
    // Update countdown every 30 seconds
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    // 🔥 NEW: Center map on user location after a short delay to allow provider initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUserLocation();
    });
  }

  Future<void> _centerOnUserLocation() async {
    if (!mounted) return;
    
    // 1. Try to get live location first
    final Position? position = await LocationUtil.getCurrentLocation();
    if (position != null) {
      if (mounted) {
        setState(() => _livePosition = position);
        debugPrint("📍 Centering map on LIVE user location: [${position.latitude}, ${position.longitude}]");
        _mapController.move(LatLng(position.latitude, position.longitude), 14);
        return;
      }
    }

    // 2. Fallback to profile location
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final coords = auth.mongoUser?['geo']?['coordinates'];
    
    if (coords != null && coords is List && coords.length >= 2) {
      final double lng = (coords[0] as num).toDouble();
      final double lat = (coords[1] as num).toDouble();
      
      debugPrint("📍 Centering map on profile location: [$lat, $lng]");
      _mapController.move(LatLng(lat, lng), 13);
    } else {
       debugPrint("📍 User location not found in profile, defaulting to Bangalore");
    }
  }

  Future<void> _goToLiveLocation() async {
    final Position? position = await LocationUtil.getCurrentLocation();
    if (position != null) {
      setState(() => _livePosition = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
      AnimatedToast.show(context, "Centered on current location", type: ToastType.info);
    } else {
      AnimatedToast.show(context, "Could not fetch location", type: ToastType.error);
    }
  }

  Future<void> _fetchRealListings() async {
    setState(() => _isListingsLoading = true);
    try {
      final listings = await BackendService.getAllActiveListings();
      setState(() {
        _realListings = listings;
        _isListingsLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching real listings: $e");
      setState(() => _isListingsLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Format time remaining until expiry
  String _formatTimeRemaining(DateTime expiryTime) {
    final diff = expiryTime.difference(_now);
    if (diff.isNegative) return "Expired";
    if (diff.inDays > 0) return "Expires in ${diff.inDays}d ${diff.inHours % 24}h";
    if (diff.inHours > 0) return "Expires in ${diff.inHours}h ${diff.inMinutes % 60}m";
    if (diff.inMinutes > 0) return "Expires in ${diff.inMinutes}m";
    return "Expiring soon";
  }

  // Filter out expired listings (client-side defense)
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

  // Filter stores based on search and filters
  List<dynamic> get _allResults {
    // 1. Start with mock stores
    List<dynamic> results = List.from(allMockStores);
    
    // 2. Add only valid (non-expired) real listings
    results.insertAll(0, _validListings);

    final auth = context.watch<AppAuthProvider>();
    final List<String> dietaryPrefs = List<String>.from(auth.mongoProfile?['dietaryPreferences'] ?? []);

    return results.where((item) {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final name = item is MockStore ? item.name : langProvider.getTranslatedText(context, item, 'foodName');
      final type = item is MockStore ? item.type : (item['foodType'] ?? "");
      final rating = item is MockStore ? double.tryParse(item.rating) ?? 0.0 : 0.0;
      final isFree = item is MockStore ? item.isFree : (item['pricing']?['isFree'] ?? false);

      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!name.toLowerCase().contains(query) &&
            !type.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 2. Min Rating
      if (rating < _minRating) return false;

      // 3. Price Filters
      if (_onlyFree && !isFree) return false;

      // 🔥 NEW: Filter by User Dietary Preferences (Strict Filtering)
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
        
        // 1. If user has only one preference, act as a specific filter
        if (dietaryPrefs.length == 1) {
          final pref = dietaryPrefs.first;
          if (pref == "vegan" && itemDietary != "vegan") return false;
          if (pref == "jain" && itemDietary != "jain") return false;
          if (pref == "vegetarian" && (itemDietary == "non_veg" || itemDietary == "not_specified")) return false;
          if (pref == "non_veg" && itemDietary != "non_veg") return false;
        } else {
          // 2. If multiple, ensure item matches ANY of the allowed types (e.g. user eats Veg + Non-Veg)
          // But strict exclusions apply:
          if (dietaryPrefs.contains("vegan") && !dietaryPrefs.contains("non_veg")) {
             if (itemDietary == "non_veg") return false;
          }
           if (dietaryPrefs.contains("vegetarian") && !dietaryPrefs.contains("non_veg")) {
             if (itemDietary == "non_veg") return false;
          }
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final List<String> dietaryPrefs = List<String>.from(auth.mongoUser?['profile']?['dietaryPreferences'] ?? []);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          _buildMapBackground(),

         

          // 3. Floating Search Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingSearchHeader(),
          ),

          // 🔥 NEW: Search in this area button
          if (_showSearchInArea)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: _buildFloatingButton(
                  icon: Icons.refresh,
                  label: "Search in this area",
                  onTap: () {
                    setState(() => _showSearchInArea = false);
                    _fetchRealListings();
                    AnimatedToast.show(context, "Searching in this area...", type: ToastType.info);
                  },
                ),
              ),
            ),

          // 🔥 NEW: Empty State Prompt
          if ((_allResults.isEmpty || !_hasVisibleResults) && !_isListingsLoading)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_outlined, color: AppColors.primary, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        "No listings here yet",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _allResults.isEmpty 
                            ? "Try changing your filters or searching another area."
                            : "Invite sellers in this area to encourage community growth!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Draggable Bottom Sheet
          _buildBottomSheetList(),

          // 5. Pop-out Card
          if (_selectedStoreId != null) _buildPopOutCard(),

          // 🔥 NEW: Locate Me Button
          Positioned(
            bottom: 220,
            right: 20,
            child: FloatingActionButton(
              heroTag: "locateMe",
              onPressed: _goToLiveLocation,
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
  return FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      initialCenter: const LatLng(12.9716, 77.5946), // Bangalore default
      initialZoom: 13,
      onPositionChanged: (position, hasGesture) {
        if (position.center != null) {
          // 1. Check for visible results
          final bool visible = _checkVisibleResults(position.bounds);
          if (visible != _hasVisibleResults) {
            setState(() => _hasVisibleResults = visible);
          }

          // 2. Show "Search in area" button if gestured
          if (hasGesture) {
            if (_lastCenter == null || 
                (position.center!.latitude - _lastCenter!.latitude).abs() > 0.01 ||
                (position.center!.longitude - _lastCenter!.longitude).abs() > 0.01) {
              setState(() {
                _showSearchInArea = true;
                _lastCenter = position.center;
              });
            }
          }
        }
      },
      onTap: (_, __) {
        if (_selectedStoreId != null) {
          setState(() => _selectedStoreId = null);
        }
      },
    ),
    children: [
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        userAgentPackageName: "com.yourapp.app",
      ),
      MarkerLayer(
        markers: _buildOSMMarkers(),
      ),
    ],
  );
}

List<Marker> _buildOSMMarkers() {
  final List<Marker> markers = _allResults.map((item) {
    final String id = item is MockStore ? item.id : (item['_id'] ?? "");
    final bool isSelected = _selectedStoreId == id;
    final bool isFree = item is MockStore ? item.isFree : (item['pricing']?['isFree'] ?? false);
    final String price = item is MockStore ? item.price : "₹${item['pricing']?['discountedPrice'] ?? 0}";

    // 🔥 Real coordinates from pickupGeo
    double lat = 12.9716;
    double lng = 77.5946;

    if (item is MockStore) {
      // Distribute mock stores slightly for demo
      lat = 12.9716 + (_allResults.indexOf(item) * 0.005);
      lng = 77.5946 + (_allResults.indexOf(item) * 0.005);
    } else {
      final coords = item['pickupGeo']?['coordinates'];
      if (coords != null && coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return Marker(
      width: isSelected ? 120 : 100,
      height: isSelected ? 60 : 50,
      point: LatLng(lat, lng),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedStoreId = id);
          _mapController.move(LatLng(lat, lng), 14); // Focus on marker
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.primary : Colors.black).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item is MockStore ? Icons.store_outlined : Icons.restaurant_menu,
                size: 14,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isFree ? AppLocalizations.of(context)!.translate("free") : price,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }).toList();

  // 🔥 NEW: Add User's "Blue Dot" position
  if (_livePosition != null) {
    markers.add(
      Marker(
        width: 24,
        height: 24,
        point: LatLng(_livePosition!.latitude, _livePosition!.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return markers;
}

bool _checkVisibleResults(LatLngBounds? bounds) {
  if (bounds == null) return true;
  if (_allResults.isEmpty) return false;

  for (final item in _allResults) {
    double lat = 12.9716;
    double lng = 77.5946;

    if (item is MockStore) {
      lat = 12.9716 + (_allResults.indexOf(item) * 0.005);
      lng = 77.5946 + (_allResults.indexOf(item) * 0.005);
    } else {
      final coords = item['pickupGeo']?['coordinates'];
      if (coords != null && coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    if (bounds.contains(LatLng(lat, lng))) {
      return true;
    }
  }
  return false;
}

Widget _buildFloatingButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildFloatingSearchHeader() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.search, size: 24, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      label: Text(AppLocalizations.of(context)!.translate("bangalore") ?? "Bangalore"),
                      hintText: AppLocalizations.of(context)!.translate("search_city_food_category") ?? "Search city, food or category...",
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textLight.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty || _minRating > 0 || _onlyFree)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                      _minRating = 0;
                      _onlyFree = false;
                    }),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildHeaderFilter(AppLocalizations.of(context)!.translate("Filter"), onTap: _showFilterDialog),
                const SizedBox(width: 8),
                if (_minRating > 0) ...[
                  _buildActiveFilterChip("${_minRating}+ ★"),
                  const SizedBox(width: 8),
                ],
                if (_onlyFree) ...[
                  _buildActiveFilterChip("Free"),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  "${_allResults.length} ${AppLocalizations.of(context)!.translate('results')}",
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFilter(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate("Filter"),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.translate("Rating"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [3.5, 4.0, 4.5].map((rating) {
                      final isSelected = _minRating == rating;
                      return ChoiceChip(
                        label: Text("$rating+ ★"),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {});
                          setState(() => _minRating = selected ? rating : 0);
                        },
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        // Add backgroundColor if needed to ensure visibility when not selected
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.translate("Offers"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.translate("Free Food Only")),
                    selected: _onlyFree,
                    onSelected: (val) {
                      setModalState(() {});
                      setState(() => _onlyFree = val);
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: _onlyFree ? Colors.white : Colors.black,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate("Apply Filters")),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      controller: _sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  controller: scrollController,
                  itemCount: _allResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    return _buildStoreCard(_allResults[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopOutCard() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final item = _allResults.firstWhere((s) {
      final id = s is MockStore ? s.id : (s['_id'] ?? "");
      return id == _selectedStoreId;
    });
    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      item is MockStore 
                          ? item.image 
                          : ((item['images'] as List?)?.isNotEmpty == true 
                              ? BackendService.formatImageUrl(item['images'][0]) 
                              : BackendService.generateFoodImageUrl(langProvider.getTranslatedText(context, item, 'foodName'))),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          height: 150,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _selectedStoreId = null),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item is MockStore 
                                ? item.name 
                                : Provider.of<LanguageProvider>(context, listen: false).getTranslatedText(context, item, 'foodName'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            item is MockStore 
                                ? "${item.rating} ★ • ${item.isFree ? AppLocalizations.of(context)!.translate("free") : item.price}"
                                : "4.5 ★ • ${item['pricing']?['isFree'] == true ? AppLocalizations.of(context)!.translate("free") : "₹${item['pricing']?['discountedPrice'] ?? 0}"}",
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyerFoodDetailPage(listing: item is! MockStore ? item : null, store: item is MockStore ? item : null),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.translate("view_details")),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(dynamic item) {
    if (item is MockStore) {
      return _buildMockStoreCard(item);
    } else {
      return _buildRealListingCard(item);
    }
  }

  Widget _buildRealListingCard(Map<String, dynamic> listing) {
    // Implement real listing card
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final String name = langProvider.getTranslatedText(context, listing, 'foodName');
    final String type = listing['foodType'] ?? "Meal";
    final pricing = listing['pricing'] ?? {};
    final bool isFree = pricing['isFree'] ?? false;
    final int price = pricing['discountedPrice'] ?? 0;
    
    final sellerProfile = listing['sellerProfileId'] ?? {};
    final String orgName = sellerProfile['orgName'] ?? "Local Seller";
    final double rating = (sellerProfile['stats']?['avgRating'] ?? 0.0).toDouble();
    final int ratingCount = sellerProfile['stats']?['ratingCount'] ?? 0;
    
    // Get expiry time for countdown
    final String? expiryStr = listing['pickupWindow']?['to'];
    final DateTime? expiryTime = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
    
    final List images = listing['images'] ?? [];
    final String uploadedImageUrl = images.isNotEmpty 
        ? BackendService.formatImageUrl(images[0])
        : "";
    final String imageUrl = BackendService.isValidImageUrl(uploadedImageUrl) 
        ? uploadedImageUrl 
        : BackendService.generateFoodImageUrl(name);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BuyerFoodDetailPage(listing: listing)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Consumer<AppAuthProvider>(
                  builder: (context, auth, _) {
                    final profile = auth.mongoProfile;
                    final sellerId = listing['sellerProfileId']?['userId'] ?? "";
                    final List? favorites = profile?['favouriteSellers'];
                    final bool isFavorited = favorites?.contains(sellerId) ?? false;

                    return GestureDetector(
                      onTap: () async {
                        if (auth.currentUser == null || sellerId.isEmpty) return;
                        try {
                          await BackendService.toggleFavoriteSeller(
                              firebaseUid: auth.currentUser!.uid,
                              sellerId: sellerId);
                          await auth.refreshMongoUser();
                          if (mounted) {
                            AnimatedToast.show(
                              context,
                              isFavorited ? "Removed restaurant from favorites" : "Added restaurant to favorites",
                              type: isFavorited ? ToastType.info : ToastType.success,
                            );
                          }
                        } catch (e) {
                          debugPrint("Error toggling favorite restaurant: $e");
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFavorited ? Colors.red : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orgName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "${rating.toStringAsFixed(1)} ($ratingCount)",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (expiryTime != null) ...[
                          const Icon(Icons.access_time, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeRemaining(expiryTime),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          listing['pickupAddressText'] ?? "Bangalore",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isFree ? AppLocalizations.of(context)!.translate("free") : "₹$price",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: " / item",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerFoodDetailPage(listing: listing),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      "Select",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockStoreCard(MockStore store) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BuyerFoodDetailPage(store: store)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  store.image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Consumer<AppAuthProvider>(
                  builder: (context, auth, _) {
                    final profile = auth.mongoProfile;
                    final List? favorites = profile?['favouriteSellers'];
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFavorited ? Colors.red : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${store.rating} (${store.reviews.values.length * 50} reviews)",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "1.2 miles",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: store.isFree ? "Free" : store.price,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: " / item",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerFoodDetailPage(store: store),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      "Select",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    double step = 80;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step * 0.8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final blockPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(20, 20, 50, 50), blockPaint);
    canvas.drawRect(const Rect.fromLTWH(100, 100, 120, 60), blockPaint);
    canvas.drawRect(const Rect.fromLTWH(250, 50, 80, 80), blockPaint);
    canvas.drawRect(const Rect.fromLTWH(20, 300, 100, 100), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
