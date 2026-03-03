import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../shared/styles/app_colors.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/review_widgets.dart';

class BuyerOrderReviewPage extends StatefulWidget {
  final String orderId;
  final String buyerId;
  final Map<String, dynamic> orderData; // Contains seller, volunteer, item details

  const BuyerOrderReviewPage({
    super.key,
    required this.orderId,
    required this.buyerId,
    required this.orderData,
  });

  @override
  State<BuyerOrderReviewPage> createState() => _BuyerOrderReviewPageState();
}

class _BuyerOrderReviewPageState extends State<BuyerOrderReviewPage> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  
  // State for seller review
  int _sellerRating = 0;
  final TextEditingController _sellerCommentController = TextEditingController();
  final List<String> _sellerSelectedTags = [];

  // State for volunteer review
  int _volunteerRating = 0;
  final TextEditingController _volunteerCommentController = TextEditingController();
  final List<String> _volunteerSelectedTags = [];

  // UI state
  bool _isSellerAnonymous = false;
  bool _isVolunteerAnonymous = false;
  bool _isSubmitting = false;

  // Predefined tags
  static const List<String> SELLER_TAGS = [
    "Quality of food",
    "Packaging quality",
    "Freshness",
    "Meets description",
    "Quick preparation",
    "Value for money"
  ];

  static const List<String> VOLUNTEER_TAGS = [
    "Delivery speed",
    "Professional behavior",
    "Food condition on arrival",
    "Politeness",
    "Handled with care",
    "On-time delivery"
  ];

  @override
  void dispose() {
    _sellerCommentController.dispose();
    _volunteerCommentController.dispose();
    super.dispose();
  }

  Future<void> _submitReviews() async {
    // Validate at least one review
    if (_sellerRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the seller'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.orderData['needsVolunteerReview'] && _volunteerRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the volunteer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit seller review
      await _reviewRepo.createReview(
        orderId: widget.orderId,
        reviewerId: widget.buyerId,
        targetType: 'seller',
        targetUserId: widget.orderData['sellerId'],
        rating: _sellerRating,
        comment: _sellerCommentController.text.isEmpty
            ? null
            : _sellerCommentController.text,
        tags: _sellerSelectedTags.isEmpty ? null : _sellerSelectedTags,
        isAnonymous: _isSellerAnonymous,
      );

      // Submit volunteer review if applicable
      if (widget.orderData['needsVolunteerReview']) {
        await _reviewRepo.createReview(
          orderId: widget.orderId,
          reviewerId: widget.buyerId,
          targetType: 'volunteer',
          targetUserId: widget.orderData['volunteerId'],
          rating: _volunteerRating,
          comment: _volunteerCommentController.text.isEmpty
              ? null
              : _volunteerCommentController.text,
          tags: _volunteerSelectedTags.isEmpty ? null : _volunteerSelectedTags,
          isAnonymous: _isVolunteerAnonymous,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviews submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildReviewSection({
    required String title,
    required String targetName,
    required int currentRating,
    required Function(int) onRatingChanged,
    required TextEditingController commentController,
    required List<String> selectedTags,
    required Function(String, bool) onTagToggle,
    required List<String> availableTags,
    required bool isAnonymous,
    required Function(bool) onAnonymousChanged,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Rating $targetName',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Star Rating
            Text(
              'How would you rate this ${title.toLowerCase()}?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            StarRatingWidget(
              initialRating: currentRating,
              onRatingChanged: onRatingChanged,
              size: 48,
            ),
            const SizedBox(height: 24),

            // Comment
            Text(
              'Add a comment (optional)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Tags
            Text(
              'Select tags (max 3)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags
                  .map(
                    (tag) => ReviewTagChip(
                      tag: tag,
                      isSelected: selectedTags.contains(tag),
                      onSelected: (bool selected) {
                        if (selected && selectedTags.length >= 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Maximum 3 tags allowed'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }
                        onTagToggle(tag, selected);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Anonymous option
            Row(
              children: [
                Checkbox(
                  value: isAnonymous,
                  onChanged: (bool? value) {
                    onAnonymousChanged(value ?? false);
                  },
                  activeColor: AppColors.primary,
                ),
                Text(
                  'Review anonymously',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVolunteer = widget.orderData['needsVolunteerReview'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rate Your Order',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller Review Section
            _buildReviewSection(
              title: 'Review Seller',
              targetName: widget.orderData['sellerName'] ?? 'Seller',
              currentRating: _sellerRating,
              onRatingChanged: (rating) {
                setState(() => _sellerRating = rating);
              },
              commentController: _sellerCommentController,
              selectedTags: _sellerSelectedTags,
              onTagToggle: (tag, selected) {
                setState(() {
                  if (selected) {
                    _sellerSelectedTags.add(tag);
                  } else {
                    _sellerSelectedTags.remove(tag);
                  }
                });
              },
              availableTags: SELLER_TAGS,
              isAnonymous: _isSellerAnonymous,
              onAnonymousChanged: (value) {
                setState(() => _isSellerAnonymous = value);
              },
            ),

            // Volunteer Review Section (if applicable)
            if (hasVolunteer)
              _buildReviewSection(
                title: 'Review Volunteer',
                targetName: widget.orderData['volunteerName'] ?? 'Volunteer',
                currentRating: _volunteerRating,
                onRatingChanged: (rating) {
                  setState(() => _volunteerRating = rating);
                },
                commentController: _volunteerCommentController,
                selectedTags: _volunteerSelectedTags,
                onTagToggle: (tag, selected) {
                  setState(() {
                    if (selected) {
                      _volunteerSelectedTags.add(tag);
                    } else {
                      _volunteerSelectedTags.remove(tag);
                    }
                  });
                },
                availableTags: VOLUNTEER_TAGS,
                isAnonymous: _isVolunteerAnonymous,
                onAnonymousChanged: (value) {
                  setState(() => _isVolunteerAnonymous = value);
                },
              ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Reviews',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
