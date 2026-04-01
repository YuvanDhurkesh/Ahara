import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'create_listing_page.dart';
import 'seller_listing_details_page.dart';
import '../../../core/localization/app_localizations.dart';

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
      final activeJson = await BackendService.getSellerListings(
        mongoSellerId,
        'active',
      );
      final completedJson = await BackendService.getSellerListings(
        mongoSellerId,
        'completed',
      );
      final expiredJson = await BackendService.getSellerListings(
        mongoSellerId,
        'expired',
      );

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
          (l.remainingQuantity > 0);
    }).toList();
  }

  List<Listing> get _expiredListings {
    return _allListings.where((l) {
      return (l.expiryTime.isBefore(_now) ||
              l.expiryTime.isAtSameMomentAs(_now)) &&
          l.status != ListingStatus.claimed;
    }).toList();
  }

  List<Listing> get _completedListings {
    return _allListings
        .where((l) => l.status == ListingStatus.claimed)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.translate("my_listings"),
            style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textDark,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.translate("active")),
              Tab(text: AppLocalizations.of(context)!.translate("completed")),
              Tab(text: AppLocalizations.of(context)!.translate("expired_tab")),
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
                label: Text(
                  AppLocalizations.of(context)!.translate("new_listing"),
                ),
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
            ? Center(
                child: Text(
                  "${AppLocalizations.of(context)!.translate("error")}: $_errorMessage",
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: TabBarView(
                    children: [
                      _buildListingList(
                        context,
                        _activeListings,
                        ListingStatus.active,
                      ),
                      _buildListingList(
                        context,
                        _completedListings,
                        ListingStatus.claimed,
                      ), // Backend uses 'completed' or remainingQuantity: 0
                      _buildListingList(
                        context,
                        _expiredListings,
                        ListingStatus.expired,
                      ),
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

  Future<void> _showRelistDialog(Listing listing) async {
    DateTime listingStart = DateTime.now();
    DateTime listingEnd = Listing.calculateExpiryTime(listing.foodType, listingStart);
    final quantityController = TextEditingController(text: listing.totalQuantity.toInt().toString());
    final priceController = TextEditingController(text: listing.price?.toInt().toString() ?? "");
    bool isFree = listing.redistributionMode == RedistributionMode.free;

    // Rescue Window state
    bool isRescueMode = false;
    TimeOfDay rescueFrom = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay rescueTo = const TimeOfDay(hour: 23, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate("relist_listing")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Relist: ${listing.foodName}"),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: "New Total Quantity (${listing.quantityUnit})",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Mark as Free?"),
                  value: isFree,
                  onChanged: (val) {
                    setDialogState(() {
                      isFree = val;
                      if (isFree) priceController.clear();
                    });
                  },
                ),
                if (!isFree)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: "New Price (₹)",
                        border: OutlineInputBorder(),
                        prefixText: "₹ ",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Listing Start picker (Prepared At)
                _buildTimePickerButton(
                  context: context,
                  label: "Listing Start",
                  dateTime: listingStart,
                  onTap: () async {
                    final picked = await _pickDateTime(context, initial: listingStart);
                    if (picked != null) {
                      setDialogState(() {
                        listingStart = picked;
                        listingEnd = Listing.calculateExpiryTime(listing.foodType, listingStart);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Rescue Window Section
                _buildRelistRescueWindowSection(
                  context: context,
                  enabled: isRescueMode,
                  from: rescueFrom,
                  to: rescueTo,
                  foodType: listing.foodType,
                  preparedAt: listingStart,
                  onToggle: (v) => setDialogState(() => isRescueMode = v),
                  onPickTime: (isFrom) async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: isFrom ? rescueFrom : rescueTo,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        if (isFrom) {
                          rescueFrom = picked;
                        } else {
                          rescueTo = picked;
                        }
                      });
                    }
                  },
                ),

                if (!isRescueMode) ...[
                  const SizedBox(height: 12),
                  // Manual Expiry (Only if not in rescue mode)
                  _buildTimePickerButton(
                    context: context,
                    label: "Expiry Time",
                    dateTime: listingEnd,
                    onTap: () async {
                      final picked = await _pickDateTime(context, initial: listingEnd);
                      if (picked != null) {
                        setDialogState(() {
                          listingEnd = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Auto-calc: +${Listing.calculateExpiryTime(listing.foodType, listingStart).difference(listingStart).inHours}h for ${listing.foodType.name.split('.').last.replaceAll('_', ' ')}",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.translate("cancel")),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isFree && priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a price or mark as free")),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(
                AppLocalizations.of(context)!.translate("relist_listing"),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        DateTime finalFrom;
        DateTime finalTo;

        if (isRescueMode) {
          final window = _getRelistRescueWindow(rescueFrom, rescueTo);
          finalFrom = window.$1;
          finalTo = window.$2;
        } else {
          finalFrom = listingStart;
          finalTo = listingEnd;
        }

        final newQuantity = int.tryParse(quantityController.text) ?? listing.totalQuantity.toInt();
        final newPrice = isFree ? 0 : (int.tryParse(priceController.text) ?? listing.price?.toInt() ?? 0);

        await BackendService.relistListing(listing.id, {
          "pickupWindow": {
            "from": finalFrom.toIso8601String(),
            "to": finalTo.toIso8601String(),
          },
          "totalQuantity": newQuantity,
          "pricing": {
            "discountedPrice": newPrice,
            "isFree": isFree,
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Listing relisted successfully!")),
          );
          _fetchListings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to relist: $e")));
        }
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, ListingStatus status) {
    String message = AppLocalizations.of(context)!.translate("no_listings_yet");
    if (status == ListingStatus.claimed)
      message = AppLocalizations.of(
        context,
      )!.translate("no_completed_listings");
    if (status == ListingStatus.expired)
      message = AppLocalizations.of(context)!.translate("no_expired_listings");

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
              AppLocalizations.of(
                context,
              )!.translate("start_creating_listing_desc"),
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
                child: Image.network(
                  listing.getDisplayImageUrl(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("❌ Image load error: $error");
                    return _buildImagePlaceholder();
                  },
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
                    gradient: LinearGradient(
                      colors:
                          listing.redistributionMode == RedistributionMode.free
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
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
                            ? AppLocalizations.of(context)!.translate("FREE")
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
                    Flexible(
                      child: Text(
                        "${listing.totalQuantity} ${listing.quantityUnit}",
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _now.isBefore(listing.expiryTime)
                            ? "${AppLocalizations.of(context)!.translate("expires_in")} ${_formatDuration(listing.expiryTime.difference(_now))}"
                            : "${AppLocalizations.of(context)!.translate("expired_ago")} ${_formatDuration(_now.difference(listing.expiryTime))}",
                        style: TextStyle(
                          color: _now.isBefore(listing.expiryTime)
                              ? Colors.orange.shade700
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate("hygiene_status"),
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
                      mainAxisSize: MainAxisSize.min,
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
                          child: Text(
                            AppLocalizations.of(context)!.translate("edit"),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isExpired)
                          ElevatedButton.icon(
                            onPressed: () => _showRelistDialog(listing),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate("relist_listing"),
                            ),
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
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SellerListingDetailsPage(
                                        listing: listing,
                                      ),
                                ),
                              );
                              if (result == true) {
                                _fetchListings(); // Refresh if something changed (like deletion)
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.primary),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate("view_details"),
                              style: const TextStyle(color: AppColors.primary),
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

  Widget _buildTimePickerButton({
    required BuildContext context,
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(dateTime),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Widget _buildRelistRescueWindowSection({
    required BuildContext context,
    required bool enabled,
    required TimeOfDay from,
    required TimeOfDay to,
    required FoodType foodType,
    required DateTime preparedAt,
    required ValueChanged<bool> onToggle,
    required Function(bool) onPickTime,
  }) {
    final amber = const Color(0xFFF59E0B);
    final amberLight = const Color(0xFFFEF3C7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: enabled ? amberLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? amber.withOpacity(0.6) : Colors.grey[300]!,
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              "Schedule Rescue Window",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: enabled ? const Color(0xFF92400E) : Colors.black,
              ),
            ),
            subtitle: const Text("Allow pickup only during closing time", style: TextStyle(fontSize: 11)),
            value: enabled,
            onChanged: onToggle,
            activeColor: amber,
          ),
          if (enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeChip(
                          label: "Opens At",
                          timeStr: _fmtTime(from),
                          icon: Icons.login_rounded,
                          color: amber,
                          onTap: () => onPickTime(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeChip(
                          label: "Closes At",
                          timeStr: _fmtTime(to),
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: () => onPickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Safety Hint
                  Builder(
                    builder: (_) {
                      final safetyDt = Listing.calculateExpiryTime(foodType, preparedAt);
                      final window = _getRelistRescueWindow(from, to);
                      final toDt = window.$2;
                      final isSafe = !toDt.isAfter(safetyDt);
                      final safeStr = DateFormat('hh:mm a').format(safetyDt);
                      return Row(
                        children: [
                          Icon(
                            isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            size: 13,
                            color: isSafe ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isSafe
                                  ? 'Safe ✓ Food stays fresh until $safeStr'
                                  : '⚠ Exceeds safety limit ($safeStr)',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSafe ? Colors.green[700] : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip({
    required String label,
    required String timeStr,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                  Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (DateTime, DateTime) _getRelistRescueWindow(TimeOfDay from, TimeOfDay to) {
    final now = DateTime.now();
    DateTime fromDt = DateTime(now.year, now.month, now.day, from.hour, from.minute);
    DateTime toDt = DateTime(now.year, now.month, now.day, to.hour, to.minute);

    if (!toDt.isAfter(fromDt)) {
      toDt = toDt.add(const Duration(days: 1));
    }

    if (now.isAfter(toDt.add(const Duration(minutes: 5)))) {
      fromDt = fromDt.add(const Duration(days: 1));
      toDt = toDt.add(const Duration(days: 1));
    }

    return (fromDt, toDt);
  }
}
