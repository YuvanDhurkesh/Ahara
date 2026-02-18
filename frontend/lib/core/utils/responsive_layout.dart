/// File: responsive_layout.dart
/// Purpose: Viewport-aware layout orchestration for multi-platform support.
/// 
/// Responsibilities:
/// - Provides a declarative interface for adaptive UI switching
/// - Visualizes breakpoint thresholds for Mobile, Tablet, and Desktop tiers
import 'package:flutter/material.dart';

/// Declarative layout wrapper for building device-agnostic interfaces.
/// 
/// Logic:
/// - Mobile: < 600px
/// - Tablet: 600px to 1100px
/// - Desktop: >= 1100px
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
