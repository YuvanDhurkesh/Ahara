import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import 'seller_overview_page.dart';
import 'seller_listings_page.dart';
import 'seller_orders_page.dart';
import 'seller_profile_page.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../common/pages/landing_page.dart';
import 'package:provider/provider.dart';

class SellerDashboardPage extends StatefulWidget {
  final int initialIndex;
  const SellerDashboardPage({super.key, this.initialIndex = 0});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  late int _selectedIndex;
  bool _isVoiceModeActive = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _toggleVoiceMode() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (voiceService.isListening) {
      await voiceService.stopListening();
      setState(() => _isVoiceModeActive = false);
    } else {
      setState(() => _isVoiceModeActive = true);
      await voiceService.speak(
        AppLocalizations.of(context)!.translate("voice_mode_on") ?? "Voice mode activated. How can I help?",
        languageCode: langProvider.locale.languageCode,
      );
      
      voiceService.startListening((words) {
        _handleVoiceCommand(words);
      });
    }
  }

  void _handleVoiceCommand(String words) {
    debugPrint("Recognized words: $words");
    final lowerWords = words.toLowerCase();
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    if (lowerWords.contains("help")) {
      voiceService.speak("You can say: Logout, Profile, Overview, Listings, Orders, or Refresh.");
    } else if (lowerWords.contains("logout")) {
      voiceService.speak("Logging out...");
      _performLogout();
    } else if (lowerWords.contains("profile")) {
      voiceService.speak("Opening profile");
      setState(() => _selectedIndex = 3);
    } else if (lowerWords.contains("overview")) {
      voiceService.speak("Opening overview");
      setState(() => _selectedIndex = 0);
    } else if (lowerWords.contains("listing")) {
      voiceService.speak("Opening listings");
      setState(() => _selectedIndex = 1);
    } else if (lowerWords.contains("order")) {
      voiceService.speak("Opening orders");
      setState(() => _selectedIndex = 2);
    } else if (lowerWords.contains("refresh")) {
      voiceService.speak("Refreshing dashboard.");
      setState(() {});
    }
  }

  Future<void> _performLogout() async {
    await Provider.of<AppAuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const SellerOverviewPage(),
      const SellerListingsPage(),
      const SellerOrdersPage(),
      const SellerProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleVoiceMode,
        backgroundColor: _isVoiceModeActive ? AppColors.primary : AppColors.secondary,
        child: Icon(
          _isVoiceModeActive ? Icons.mic : Icons.mic_none,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textLight.withOpacity(0.4),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.dashboard_outlined),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.dashboard),
                      ),
                      label: AppLocalizations.of(context)!.translate("overview"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.inventory_2),
                      ),
                      label: AppLocalizations.of(context)!.translate("listings"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.receipt_long),
                      ),
                      label: AppLocalizations.of(context)!.translate("orders"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.person_outline),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: const Icon(Icons.person),
                      ),
                      label: AppLocalizations.of(context)!.translate("profile"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
