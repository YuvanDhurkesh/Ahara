import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable badge widget that displays "🛡️ FSSAI Verified"
/// when the seller's FSSAI certificate has been validated.
///
/// Usage:
/// ```dart
/// if (listing.isFssaiVerified)
///   const FssaiVerifiedBadge()
/// ```
class FssaiVerifiedBadge extends StatelessWidget {
  final bool compact;

  const FssaiVerifiedBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 12, color: Colors.green.shade700),
            const SizedBox(width: 3),
            Text(
              'FSSAI',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '🛡️ FSSAI Verified',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
