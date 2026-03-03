import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

/// Reusable tag chip for review tags
class ReviewTagChip extends StatefulWidget {
  final String tag;
  final bool isSelected;
  final Function(bool) onSelected;
  final bool selectable;

  const ReviewTagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    required this.onSelected,
    this.selectable = true,
  });

  @override
  State<ReviewTagChip> createState() => _ReviewTagChipState();
}

class _ReviewTagChipState extends State<ReviewTagChip> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.selectable) {
      return Chip(
        label: Text(
          widget.tag,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary.withOpacity(0.7),
        side: BorderSide.none,
      );
    }

    return FilterChip(
      label: Text(
        widget.tag,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: _isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: _isSelected,
      onSelected: (bool selected) {
        setState(() {
          _isSelected = selected;
        });
        widget.onSelected(selected);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: _isSelected ? AppColors.primary : Colors.grey.shade300,
        width: 1,
      ),
      showCheckmark: false,
    );
  }
}

/// Review card for displaying submitted reviews
class ReviewCard extends StatelessWidget {
  final String reviewerName;
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
  final String? sellerResponse;
  final bool isVerified;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwnerReview;

  const ReviewCard({
    super.key,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.createdAt,
    this.sellerResponse,
    this.isVerified = true,
    this.onEdit,
    this.onDelete,
    this.isOwnerReview = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} mins ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${(diff.inDays / 30).floor()} months ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Rating, Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.toInt()
                                    ? Icons.star
                                    : Icons.star_outline,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isOwnerReview) ...[
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        onSelected: (choice) {
                          if (choice == 'edit') {
                            onEdit?.call();
                          } else if (choice == 'delete') {
                            onDelete?.call();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Comment
            if (comment.isNotEmpty)
              Text(
                comment,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (tag) => ReviewTagChip(
                        tag: tag,
                        selectable: false,
                        onSelected: (_) {},
                      ),
                    )
                    .toList(),
              ),
            ],
            // Seller Response
            if (sellerResponse != null && sellerResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response from seller',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sellerResponse!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rating breakdown widget showing distribution
class RatingBreakdownChart extends StatelessWidget {
  final Map<int, int> ratingDistribution;
  final double avgRating;
  final int totalReviews;

  const RatingBreakdownChart({
    super.key,
    required this.ratingDistribution,
    required this.avgRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating header
        Row(
          children: [
            Text(
              avgRating.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < avgRating.toInt()
                          ? Icons.star
                          : Icons.star_outline,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews reviews',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Rating distribution bars
        ...List.generate(5, (index) {
          final stars = 5 - index;
          final count = ratingDistribution[stars] ?? 0;
          final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '$stars★',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
