import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../shared/styles/app_colors.dart';
import '../widgets/review_widgets.dart';

class SellerReviewsPage extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerReviewsPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerReviewsPage> createState() => _SellerReviewsPageState();
}

class _SellerReviewsPageState extends State<SellerReviewsPage> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  
  late Future<Map<String, dynamic>> _reviewsFuture;
  int _currentPage = 1;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = _reviewRepo.getReviewsForUser(
      userId: widget.sellerId,
      page: _currentPage,
      limit: 10,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached end, load more
      setState(() {
        _currentPage++;
        _loadReviews();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.sellerName} Reviews',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reviews',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loadReviews());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final analytics = data['analytics'] as Map<String, dynamic>?;
          final reviews = data['reviews'] as List<dynamic>? ?? [];
          final pagination = data['pagination'] as Map<String, dynamic>?;

          if (reviews.isEmpty && _currentPage == 1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics Section
                  if (analytics != null) ...[
                    RatingBreakdownChart(
                      avgRating: (analytics['avgRating'] as num?)?.toDouble() ?? 0,
                      totalReviews: analytics['totalReviews'] as int? ?? 0,
                      ratingDistribution: {
                        5: analytics['ratingDistribution']['5'] as int? ?? 0,
                        4: analytics['ratingDistribution']['4'] as int? ?? 0,
                        3: analytics['ratingDistribution']['3'] as int? ?? 0,
                        2: analytics['ratingDistribution']['2'] as int? ?? 0,
                        1: analytics['ratingDistribution']['1'] as int? ?? 0,
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 24),

                    // Most common tags
                    if ((analytics['mostCommonTags'] as List?)?.isNotEmpty ?? false) ...[
                      Text(
                        'Customer Highlights',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (analytics['mostCommonTags'] as List?)
                                ?.map((tagData) {
                              final tag = tagData['tag'] as String?;
                              final count = tagData['count'] as int?;
                              return Chip(
                                label: Text(
                                  '$tag ($count)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.primary.withOpacity(0.7),
                              );
                            }).toList() ??
                            [],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Verified percentage
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${analytics['verifiedPercentage']} verified purchases',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 24),
                  ],

                  // Reviews List
                  Text(
                    'All Reviews',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...reviews.map((reviewData) {
                    final review = reviewData as Map<String, dynamic>;
                    return ReviewCard(
                      reviewerName: review['reviewer']['name'] as String? ?? 'Verified Buyer',
                      rating: (review['rating'] as num?)?.toDouble() ?? 0,
                      comment: review['comment'] as String? ?? '',
                      tags: List<String>.from(review['tags'] as List? ?? []),
                      createdAt: DateTime.parse(review['createdAt'] as String? ?? DateTime.now().toIso8601String()),
                      sellerResponse: review['response'] != null
                          ? (review['response'] as Map<String, dynamic>)['message'] as String?
                          : null,
                      isVerified: review['isVerified'] as bool? ?? true,
                    );
                  }).toList(),

                  // Load more indicator
                  if (pagination?['hasMore'] == true) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Volunteer reviews page (same structure, different data)
class VolunteerReviewsPage extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const VolunteerReviewsPage({
    super.key,
    required this.volunteerId,
    required this.volunteerName,
  });

  @override
  State<VolunteerReviewsPage> createState() => _VolunteerReviewsPageState();
}

class _VolunteerReviewsPageState extends State<VolunteerReviewsPage> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  
  late Future<Map<String, dynamic>> _reviewsFuture;
  int _currentPage = 1;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = _reviewRepo.getReviewsForUser(
      userId: widget.volunteerId,
      page: _currentPage,
      limit: 10,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _currentPage++;
        _loadReviews();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.volunteerName} Reviews',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reviews',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loadReviews());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final analytics = data['analytics'] as Map<String, dynamic>?;
          final reviews = data['reviews'] as List<dynamic>? ?? [];

          if (reviews.isEmpty && _currentPage == 1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (analytics != null) ...[
                    RatingBreakdownChart(
                      avgRating: (analytics['avgRating'] as num?)?.toDouble() ?? 0,
                      totalReviews: analytics['totalReviews'] as int? ?? 0,
                      ratingDistribution: {
                        5: analytics['ratingDistribution']['5'] as int? ?? 0,
                        4: analytics['ratingDistribution']['4'] as int? ?? 0,
                        3: analytics['ratingDistribution']['3'] as int? ?? 0,
                        2: analytics['ratingDistribution']['2'] as int? ?? 0,
                        1: analytics['ratingDistribution']['1'] as int? ?? 0,
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 24),
                    if ((analytics['mostCommonTags'] as List?)?.isNotEmpty ?? false) ...[
                      Text(
                        'Highlights',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (analytics['mostCommonTags'] as List?)
                                ?.map((tagData) {
                              final tag = tagData['tag'] as String?;
                              final count = tagData['count'] as int?;
                              return Chip(
                                label: Text(
                                  '$tag ($count)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.primary.withOpacity(0.7),
                              );
                            }).toList() ??
                            [],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                  Text(
                    'All Reviews',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...reviews.map((reviewData) {
                    final review = reviewData as Map<String, dynamic>;
                    return ReviewCard(
                      reviewerName: review['reviewer']['name'] as String? ?? 'Verified Buyer',
                      rating: (review['rating'] as num?)?.toDouble() ?? 0,
                      comment: review['comment'] as String? ?? '',
                      tags: List<String>.from(review['tags'] as List? ?? []),
                      createdAt: DateTime.parse(review['createdAt'] as String? ?? DateTime.now().toIso8601String()),
                      isVerified: review['isVerified'] as bool? ?? true,
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
