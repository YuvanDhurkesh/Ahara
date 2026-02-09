import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

class VolunteerVerificationPage extends StatelessWidget {
  const VolunteerVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verification Status',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _EmailVerificationCard(),
            SizedBox(height: 16),
            _IdentityVerificationCard(),
            SizedBox(height: 16),
            _TransportVerificationCard(),
            SizedBox(height: 24),
            _VerificationProgressCard(),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────────────── Cards ─────────────────────────
//

class _EmailVerificationCard extends StatelessWidget {
  const _EmailVerificationCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      borderColor: Colors.green,
      child: Row(
        children: [
          const Icon(Icons.email_outlined, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Email Verification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Verify your email address to receive delivery notifications',
                  style: TextStyle(color: AppColors.textLight),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Email Verified',
                      style: TextStyle(color: Colors.green),
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
}

class _IdentityVerificationCard extends StatelessWidget {
  const _IdentityVerificationCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Identity Verification',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your Aadhaar card or Driver’s License',
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upload ID Document'),
          ),
        ],
      ),
    );
  }
}

class _TransportVerificationCard extends StatelessWidget {
  const _TransportVerificationCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.directions_bike, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Transport Confirmation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Confirm your mode of transportation for deliveries',
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: 'Select Transport Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bicycle',
                      child: Text('Bicycle'),
                    ),
                    DropdownMenuItem(
                      value: 'bike',
                      child: Text('Bike'),
                    ),
                    DropdownMenuItem(
                      value: 'car',
                      child: Text('Car'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationProgressCard extends StatelessWidget {
  const _VerificationProgressCard();

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Verification Progress',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.33,
            minHeight: 8,
            backgroundColor: Color(0xFFE0E0E0),
            color: AppColors.primary,
          ),
          SizedBox(height: 8),
          Text(
            '1 of 3 steps completed',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

//
// ───────────────────────── Base Card ─────────────────────────
//

class _BaseCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _BaseCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: borderColor != null
            ? Border(left: BorderSide(color: borderColor!, width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}
