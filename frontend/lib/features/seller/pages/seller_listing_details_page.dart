import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';

class SellerListingDetailsPage extends StatefulWidget {
  final Listing listing;

  const SellerListingDetailsPage({super.key, required this.listing});

  @override
  State<SellerListingDetailsPage> createState() => _SellerListingDetailsPageState();
}

class _SellerListingDetailsPageState extends State<SellerListingDetailsPage> {
  late Listing _listing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing"),
        content: const Text("Are you sure you want to delete this listing? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await BackendService.deleteListing(_listing.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Listing deleted successfully")),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = DateTime.now().isAfter(_listing.expiryTime);
    final String formattedFrom = DateFormat('MMM d, h:mm a').format(_listing.preparedAt);
    final String formattedTo = DateFormat('MMM d, h:mm a').format(_listing.expiryTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'listing-${_listing.id}',
                child: Image.network(
                  _listing.getDisplayImageUrl(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _handleDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Delete Listing",
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusChip(_listing.status),
                      _buildFulfillmentBadges(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Provider.of<LanguageProvider>(context, listen: false).getTranslatedText(context, _listing.toJson(), 'foodName'),
                    style: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoIcon(Icons.category_outlined, _listing.foodType.name.replaceAll('_', ' ').toUpperCase()),
                      const SizedBox(width: 16),
                      _buildInfoIcon(Icons.clean_hands_outlined, _listing.hygieneStatus.name.toUpperCase(), color: Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInventoryCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Description"),
                  const SizedBox(height: 8),
                  Text(
                    _listing.description.isEmpty ? "No description provided." : Provider.of<LanguageProvider>(context, listen: false).getTranslatedText(context, _listing.toJson(), 'description'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textDark.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Pickup Window"),
                  const SizedBox(height: 12),
                  _buildTimeCard(formattedFrom, formattedTo, isExpired),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Pricing"),
                  const SizedBox(height: 12),
                  _buildPriceCard(),
                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildStatusChip(ListingStatus status) {
    Color color = AppColors.primary;
    String label = status.name.toUpperCase();
    if (status == ListingStatus.claimed) {
      color = Colors.green;
      label = "COMPLETED";
    } else if (DateTime.now().isAfter(_listing.expiryTime)) {
      color = Colors.red;
      label = "EXPIRED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildFulfillmentBadges() {
    return Row(
      children: [
        Icon(Icons.directions_walk, size: 16, color: AppColors.textLight.withOpacity(0.6)),
        const SizedBox(width: 4),
        Icon(Icons.moped, size: 16, color: AppColors.textLight.withOpacity(0.6)),
      ],
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textLight),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textLight,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard() {
    final progress = _listing.totalQuantity > 0 
        ? _listing.remainingQuantity / _listing.totalQuantity 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Inventory Status",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textLight),
              ),
              Text(
                "${_listing.remainingQuantity.toInt()} / ${_listing.totalQuantity.toInt()} ${_listing.quantityUnit}",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.2 ? Colors.red : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(_listing.totalQuantity - _listing.remainingQuantity).toInt()} items already ordered",
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String from, String to, bool isExpired) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: isExpired ? Colors.red : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Available from $from", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                Text("Expires on $to", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    final isFree = _listing.redistributionMode == RedistributionMode.free;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFree ? Colors.green.withOpacity(0.05) : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.volunteer_activism : Icons.payments_outlined,
            color: isFree ? Colors.green : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            isFree ? "Completely Free" : "Discounted Price: ₹${_listing.price?.toStringAsFixed(0)}",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isFree ? Colors.green : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
