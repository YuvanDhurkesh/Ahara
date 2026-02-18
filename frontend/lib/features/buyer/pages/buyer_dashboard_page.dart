/// File: buyer_dashboard_page.dart
/// Purpose: Main navigation shell for the buyer experience.
/// 
/// Responsibilities:
/// - Manages top-level navigation state ([BottomNavigationBar])
/// - Orchestrates Voice-Activated commands via [VoiceService]
/// - Global logout coordination
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_home_page.dart';
import 'buyer_browse_page.dart';
import 'buyer_favourites_page.dart';
import 'buyer_orders_page.dart';
import 'buyer_profile_page.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../common/pages/landing_page.dart';
import 'package:provider/provider.dart';

/// Root scaffolding for the buyer-facing application.
/// 
/// Features:
/// - Persisted navigation index
/// - Voice-enabled navigation and actions
/// - Centrally managed favourite state
class BuyerDashboardPage extends StatefulWidget {
  final int initialIndex;
  const BuyerDashboardPage({super.key, this.initialIndex = 0});

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

/// Manages UI selection, voice-command logic, and bottom navigation lifecycle.
class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  late int _selectedIndex;
  bool _isVoiceModeActive = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final Set<String> _favouriteIds = {};

  /// Toggles the persistence of a listing in the user's favourite set.
  void _toggleFavourite(String id) {
    setState(() {
      if (_favouriteIds.contains(id)) {
        _favouriteIds.remove(id);
      } else {
        _favouriteIds.add(id);
      }
    });
  }

  /// Activates or deactivates the hands-free voice control mode.
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

  /// Processes natural language input to trigger application navigation or actions.
  /// 
  /// Recognized Keywords: help, logout, profile, discover, browse, order, favour, refresh.
  void _handleVoiceCommand(String words) {
    debugPrint("Recognized words: $words");
    final lowerWords = words.toLowerCase();
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    if (lowerWords.contains("help")) {
      voiceService.speak("You can say: Logout, Profile, Discover, Browse, Orders, Favourites, or Refresh.");
    } else if (lowerWords.contains("logout")) {
      voiceService.speak("Logging out...");
      _performLogout();
    } else if (lowerWords.contains("profile")) {
      voiceService.speak("Opening profile");
      setState(() => _selectedIndex = 4);
    } else if (lowerWords.contains("discover")) {
      voiceService.speak("Opening discover");
      setState(() => _selectedIndex = 0);
    } else if (lowerWords.contains("browse")) {
      voiceService.speak("Opening browse");
      setState(() => _selectedIndex = 1);
    } else if (lowerWords.contains("order")) {
      voiceService.speak("Opening orders");
      setState(() => _selectedIndex = 2);
    } else if (lowerWords.contains("favour")) {
      voiceService.speak("Opening favourites");
      setState(() => _selectedIndex = 3);
    } else if (lowerWords.contains("refresh")) {
      voiceService.speak("Refreshing dashboard.");
      setState(() {});
    }
  }

  /// Invalidates the local session and redirects to the landing experience.
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
      BuyerHomePage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Discover
      BuyerBrowsePage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Browse
      const BuyerOrdersPage(), // Orders
      BuyerFavouritesPage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Favourites
      const BuyerProfilePage(), // Profile
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
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.explore_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.explore),
                      ),
                      label: AppLocalizations.of(context)!.translate("discover"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.location_on),
                      ),
                      label: AppLocalizations.of(context)!.translate("browse"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.shopping_bag_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.shopping_bag),
                      ),
                      label: AppLocalizations.of(context)!.translate("orders"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.favorite_outline),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.favorite),
                      ),
                      label: AppLocalizations.of(context)!.translate("favourites"),
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_outline),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person),
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
