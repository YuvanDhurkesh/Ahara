import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

class BuyerNotificationsPage extends StatefulWidget {
  const BuyerNotificationsPage({super.key});

  @override
  State<BuyerNotificationsPage> createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
  // State variables
  bool _calendarReminders = false;
  bool _email = true;
  bool _pushNotifications = true;
  bool _importantUpdates = true;
  bool _announcements = true;
  bool _surpriseBagAlerts = true;

  // Days selection
  final List<String> _days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Warm background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchItem(
              "Calendar reminders",
              "Automatically add collection times to your calendar to receive reminders.",
              _calendarReminders,
              (val) => setState(() => _calendarReminders = val),
            ),
            _buildDivider(),
            _buildSwitchItem(
              "Email",
              "Be the first to learn about new stores, great tips, updates, and even a food pun or two.",
              _email,
              (val) => setState(() => _email = val),
            ),
            _buildDivider(),
            _buildSwitchItem(
              "Push notifications",
              "Get notified about availability, feature updates, promotions, and more.",
              _pushNotifications,
              (val) => setState(() => _pushNotifications = val),
            ),

            const SizedBox(height: 16),
            _buildCheckboxItem(
              "Important updates",
              "Receive updates related to your reserved Surprise Bags and other essential app notifications.",
              _importantUpdates,
              (val) => setState(() => _importantUpdates = val ?? false),
            ),
            _buildCheckboxItem(
              "Announcements and promotions",
              "Be the first to hear about new stores joining the app, competitions, promotions in your area, and more.",
              _announcements,
              (val) => setState(() => _announcements = val ?? false),
            ),
            _buildCheckboxItem(
              "Surprise Bag alerts",
              "Receive personalised Surprise Bag recommendations and alerts.",
              _surpriseBagAlerts,
              (val) => setState(() => _surpriseBagAlerts = val ?? false),
            ),

            const SizedBox(height: 32),
            Text(
              "Daily reminder",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select which days you'd like an extra reminder to save food.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildDaySelector(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Changes saved")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Save changes",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF006D5B),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF006D5B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 32, thickness: 1, color: Colors.grey.shade200);
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        final isSelected = _selectedDays.contains(day);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.transparent
                  : Colors.transparent, // Logic check
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF006D5B)
                    : Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF006D5B)
                    : AppColors.textLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
