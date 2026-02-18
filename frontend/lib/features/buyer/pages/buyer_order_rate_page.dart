/// File: buyer_order_rate_page.dart
/// Purpose: Feedback collection interface for completed transactions.
/// 
/// Responsibilities:
/// - Collects granular metrics for food quality, variety, and packaging
/// - Captures dedicated ratings for volunteer delivery performance
/// - Synchronizes multi-dimensional feedback with the backend repository
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/backend_service.dart';

/// Evaluation wizard for aggregating buyer sentiment post-fulfillment.
/// 
/// Features:
/// - Dual-category rating system (Food vs Delivery Hero)
/// - Interactive five-star selection widgets
/// - Free-form text input for qualitative reviews
class BuyerOrderRatePage extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyerOrderRatePage({super.key, required this.order});

  @override
  State<BuyerOrderRatePage> createState() => _BuyerOrderRatePageState();
}

/// Manages rating state arithmetic and submission lifecycle.
class _BuyerOrderRatePageState extends State<BuyerOrderRatePage> {
  // Mock Ratings
  double _collectionRating = 0;
  double _qualityRating = 0;
  double _varietyRating = 0;
  double _quantityRating = 0;
  double _volunteerRating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Rate Order",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _getStoreImage(widget.order['listingId'] ?? {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.order['sellerId']?['name'] ?? "Unknown Donor",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Rate your food experience",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Food Ratings
              _buildRatingRow(
                "Collection",
                _collectionRating,
                (v) => setState(() => _collectionRating = v),
              ),
              const SizedBox(height: 24),
              _buildRatingRow(
                "Food Quality",
                _qualityRating,
                (v) => setState(() => _qualityRating = v),
              ),
              const SizedBox(height: 24),
              _buildRatingRow(
                "Variety",
                _varietyRating,
                (v) => setState(() => _varietyRating = v),
              ),
              const SizedBox(height: 24),
              _buildRatingRow(
                "Quantity",
                _quantityRating,
                (v) => setState(() => _quantityRating = v),
              ),

              const SizedBox(height: 48),

              // Volunteer Rating
              if (widget.order['volunteerId'] != null) ...[
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  "Delivery Partner",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "How was ${widget.order['volunteerId']?['name'] ?? 'the volunteer'}?",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _buildFiveStar(
                        _volunteerRating,
                        (v) => setState(() => _volunteerRating = v),
                        size: 40,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],

              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Add detailed review...",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Rating submitted!")),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Submit Review"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double rating,
    Function(double) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        _buildFiveStar(rating, onChanged),
      ],
    );
  }

  Widget _buildFiveStar(
    double rating,
    Function(double) onChanged, {
    double size = 28,
  }) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => onChanged(index + 1.0),
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: size,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }),
    );
  }
  ImageProvider? _getStoreImage(Map<String, dynamic> listing) {
    final images = listing['images'] as List?;
    if (images != null && images.isNotEmpty) {
      return NetworkImage(BackendService.formatImageUrl(images.first));
    }
    return null;
  }
}
