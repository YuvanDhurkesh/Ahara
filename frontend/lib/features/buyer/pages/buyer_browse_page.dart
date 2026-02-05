import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../data/mock_stores.dart';

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
  String _searchQuery = "";
  String? _selectedArea;

  final List<Map<String, String>> _popularAreas = [
    {
      "name": "Koramangala",
      "image":
          "https://images.unsplash.com/photo-1596422846543-75c6fc183fdf?q=80&w=400&fit=crop",
    },
    {
      "name": "Indiranagar",
      "image":
          "https://images.unsplash.com/photo-1605649487212-47bdab064df7?q=80&w=400&fit=crop",
    },
    {
      "name": "HSR Layout",
      "image":
          "https://images.unsplash.com/photo-1590059132213-f91575ee700d?q=80&w=400&fit=crop",
    },
    {
      "name": "Jayanagar",
      "image":
          "https://images.unsplash.com/photo-1449156001931-828320f218a4?q=80&w=400&fit=crop",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<MockStore> featuredResults = allMockStores.where((store) {
      bool matchesSearch =
          store.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          store.type.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesArea = _selectedArea == null || store.area == _selectedArea;
      return matchesSearch && matchesArea;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (_searchQuery.isEmpty && _selectedArea == null) ...[
                    _buildSectionHeader("Popular Areas"),
                    _buildAreaGrid(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("All Near You"),
                  ] else ...[
                    _buildActiveFilters(),
                  ],
                  _buildResultsList(featuredResults),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Browse Bangalore",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Search restaurants or dishes",
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAreaGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _popularAreas.length,
        itemBuilder: (context, index) {
          final area = _popularAreas[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedArea = area["name"]),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(area["image"]!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  area["name"]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedArea != null)
              _buildFilterChip(
                _selectedArea!,
                () => setState(() => _selectedArea = null),
              ),
            if (_searchQuery.isNotEmpty)
              _buildFilterChip("Search: $_searchQuery", () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
        onDeleted: onDelete,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildResultsList(List<MockStore> stores) {
    if (stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text("No restaurants found in this area.")),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        return _buildStoreCard(stores[index]);
      },
    );
  }

  Widget _buildStoreCard(MockStore store) {
    bool isFavourite = widget.favouriteIds.contains(store.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  store.image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (store.isFree) _buildTextBadge("FREE", Colors.green),
                    _buildTextBadge(store.area, Colors.black54),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => widget.onToggleFavourite(store.id),
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
                      isFavourite ? Icons.favorite : Icons.favorite_outline,
                      color: isFavourite
                          ? Colors.red
                          : AppColors.textLight.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        store.type,
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  store.price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: store.isFree ? Colors.green : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
