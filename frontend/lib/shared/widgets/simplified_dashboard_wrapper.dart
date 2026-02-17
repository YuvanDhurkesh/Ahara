import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';

class SimplifiedDashboardWrapper extends StatelessWidget {
  final Widget standardDashboard;
  final Widget simplifiedDashboard;

  const SimplifiedDashboardWrapper({
    super.key,
    required this.standardDashboard,
    required this.simplifiedDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        if (provider.isSimplified) {
          return simplifiedDashboard;
        }
        return standardDashboard;
      },
    );
  }
}
