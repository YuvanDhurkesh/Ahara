import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';
import 'buyer_food_detail_page.dart';

class BuyerBrowsePage extends StatefulWidget {
  final Set<String> favouriteIds;
  final Function(String) onToggleFavourite;

  const BuyerBrowsePage({
    super.key,
    required this.favouriteIds,
    required this.onToggleFavourite,
  });

  @override
  State<BuyerBrowsePage> createState() => _BuyerBrowsePageState();
}

class _BuyerBrowsePageState extends State<BuyerBrowsePage> {
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Filter States
  String _searchQuery = "";
  double _minRating = 0.0;
  bool _onlyFree = false;

  // Map Interaction State
  String? _selectedStoreId;

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // Filter stores based on search and filters
  List<MockStore> get _filteredStores {
    return allMockStores.where((store) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!store.name.toLowerCase().contains(query) &&
            !store.type.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 2. Min Rating
      final rating = double.tryParse(store.rating) ?? 0.0;
      if (rating < _minRating) return false;

      // 3. Price Filters
      if (_onlyFree && !store.isFree) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          _buildMapBackground(),

          // 2. Map Markers
          _buildMapMarkers(),

          // 3. Floating Search Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingSearchHeader(),
          ),

          // 4. Draggable Bottom Sheet
          _buildBottomSheetList(),

          // 5. Pop-out Card
          if (_selectedStoreId != null) _buildPopOutCard(),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return GestureDetector(
      onTap: () {
        if (_selectedStoreId != null) {
          setState(() => _selectedStoreId = null);
        }
      },
      child: Container(
        color: const Color(0xFFE5E5E5),
        child: CustomPaint(painter: GridMapPainter(), child: Container()),
      ),
    );
  }

  Widget _buildMapMarkers() {
    final List<Offset> positions = [
      const Offset(100, 250),
      const Offset(250, 300),
      const Offset(150, 400),
      const Offset(300, 200),
      const Offset(80, 500),
      const Offset(320, 550),
    ];

    return Stack(
      children: List.generate(
        _filteredStores.length.clamp(0, positions.length),
        (index) {
          final store = _filteredStores[index];
          final pos = positions[index];
          final isSelected = _selectedStoreId == store.id;

          return Positioned(
            top: pos.dy,
            left: pos.dx,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStoreId = store.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  store.isFree ? "Free" : store.price,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
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
                      hintText: "Bangalore",
                      hintStyle: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
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
                _buildHeaderFilter("Filter", onTap: _showFilterDialog),
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
                  "${_filteredStores.length} results",
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
                    "Filter",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Rating",
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
                    "Offers",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilterChip(
                    label: const Text("Free Food Only"),
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
                      child: const Text("Apply Filters"),
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
                  itemCount: _filteredStores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    return _buildStoreCard(_filteredStores[index]);
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
    final store = allMockStores.firstWhere((s) => s.id == _selectedStoreId);
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
                      store.image,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                            store.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${store.rating} ★ • ${store.isFree ? "Free" : store.price}",
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
                            builder: (_) => BuyerFoodDetailPage(store: store),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("View"),
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

  Widget _buildStoreCard(MockStore store) {
    bool isFavourite = widget.favouriteIds.contains(store.id);

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
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFavourite ? Colors.red : Colors.black,
                  ),
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
