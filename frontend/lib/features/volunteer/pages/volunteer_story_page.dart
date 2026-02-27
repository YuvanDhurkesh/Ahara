import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class VolunteerStoryPage extends StatefulWidget {
  final String restaurantName;
  final int mealsCount;

  const VolunteerStoryPage({
    super.key,
    required this.restaurantName,
    required this.mealsCount,
  });

  @override
  State<VolunteerStoryPage> createState() => _VolunteerStoryPageState();
}

class _VolunteerStoryPageState extends State<VolunteerStoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616), // Dark premium background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Header
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                    Text(
                      "Your Impact Story",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for close button
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // The Story Card - Wrapped in Flexible+Center to prevent overflow!
            Flexible(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCD7F55).withOpacity(0.2),
                            blurRadius: 50,
                            spreadRadius: 10,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Base color - Vibrant Orange/Gold Gradient
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFB03A), // Bright Sunrise Yellow/Orange
                                  Color(0xFFE56A15), // Deep Sunset Orange
                                ],
                              ),
                            ),
                          ),
                          
                          // Food Pattern Overlay
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15,
                              child: CustomPaint(
                                painter: _FoodPatternPainter(),
                              ),
                            ),
                          ),
                          
                          // Subtle gradient vignette to darken edges
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.15),
                                  ],
                                  center: Alignment.center,
                                  radius: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // Inner border for premium glass feel
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFFF3E6C7).withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(),
                                
                                // Basket Icon
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB69766).withOpacity(0.3),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                        ),
                                      ],
                                      border: Border.all(color: const Color(0xFFF3E6C7).withOpacity(0.2)),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_basket_rounded, 
                                      color: Color(0xFFF3E6C7), 
                                      size: 32,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    "AHARA BADGE",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFE5D3B3),
                                      letterSpacing: 4.0,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    "${widget.mealsCount}",
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 100,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF6E9C9),
                                      height: 0.9,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    widget.mealsCount == 1 ? "MEAL RESCUED" : "MEALS RESCUED",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF6E9C9),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    "Small actions. Big impact.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE5D3B3).withOpacity(1.0),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B452B).withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF8B6C43).withOpacity(0.4)),
                                    ),
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: const Color(0xFFE5D3B3),
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                        children: [
                                          const TextSpan(text: "From\n"),
                                          TextSpan(
                                            text: widget.restaurantName,
                                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const Spacer(flex: 2),
                                
                                // Brand logo at bottom
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.eco_rounded, color: Color(0xFFF6E9C9), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Ahara App",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF6E9C9),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Date
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFE5D3B3).withOpacity(0.7),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Bottom Instructions
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Instagram Share Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        onPressed: () {
                          // In a full mobile app, you would use a social share plugin here.
                          // Since we're in Flutter Web right now, we can open a new tab to IG.
                          html.window.open('https://www.instagram.com/create/story/', '_blank');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF953553), // Deep Maroon/Pink
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        label: Text(
                          "Share on Instagram",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home_rounded, size: 18),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF161616),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        label: Text(
                          "Back to Dashboard",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom safe margin
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for food outline pattern
class _FoodPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 65.0; // Space between icons
    
    final icons = [
      Icons.apple,
      Icons.eco_rounded,
      Icons.local_pizza_rounded,
      Icons.restaurant_rounded,
      Icons.cake_rounded,
      Icons.emoji_nature_rounded,
      Icons.ramen_dining_rounded,
      Icons.set_meal_rounded,
    ];
    
    int iconIndex = 0;
    
    for (double x = -20; x < size.width + 40; x += spacing) {
      for (double y = -20; y < size.height + 40; y += spacing) {
        // Offset alternate rows to create staggering
        double offsetX = x + ((y / spacing) % 2 == 0 ? spacing / 2 : 0);
        
        final icon = icons[iconIndex % icons.length];
        iconIndex++;
        
        TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
        textPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            color: Colors.black, // Opaque black, will be faded by parent Opacity
            fontSize: 32.0, // Scale up icon
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
          ),
        );
        textPainter.layout();
        
        canvas.save();
        // Translate to icon center to rotate
        canvas.translate(offsetX + 16, y + 16);
        // Vary rotation based on position
        canvas.rotate((offsetX + y) % 0.8 - 0.4);
        canvas.translate(-(offsetX + 16), -(y + 16));
        
        textPainter.paint(canvas, Offset(offsetX, y));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
