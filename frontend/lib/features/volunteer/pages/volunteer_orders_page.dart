/// File: volunteer_orders_page.dart
/// Purpose: Management interface for active and historical delivery assignments.
/// 
/// Responsibilities:
/// - Categorizes assignments into New, Active, and Completed states
/// - Displays delivery metadata (Pickup/Drop locations, Distance)
/// - Facilitates navigation to granular route details
import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import 'volunteer_order_detail_page.dart';

/// Tabbed dashboard for tracking the lifecycle of assigned food rescues.
/// 
/// Features:
/// - Multi-stage tab synchronization using [TabController]
/// - Distance-aware delivery cards with integrated action triggers
/// - Localized status and label rendering
class VolunteerOrdersPage extends StatefulWidget {
  const VolunteerOrdersPage({super.key});

  @override
  State<VolunteerOrdersPage> createState() => _VolunteerOrdersPageState();
}

class _VolunteerOrdersPageState extends State<VolunteerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.translate('my_deliveries'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                _TabLabel(
                  title: localizations.translate('new_requests'), 
                  count: 1
                ),
                _TabLabel(
                  title: localizations.translate('active'), 
                  count: 1
                ),
                _TabLabel(
                  title: localizations.translate('completed'), 
                  count: 1
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TabBarView(
            controller: _tabController,
            children: [
              _newRequestsTab(localizations), 
              _activeTab(localizations), 
              _completedTab(localizations)
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- TABS ----------------

  Widget _newRequestsTab(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DeliveryCard(
          title: 'Main Street Bakery → Sarah Johnson',
          pickup: '123 Bakers St',
          drop: '456 Oak Ave',
          actionLabel: '${localizations.translate('accept_delivery')} (2.3 km)',
          showAccept: true,
          localizations: localizations,
        ),
      ],
    );
  }

  Widget _activeTab(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DeliveryCard(
          title: 'Sunshine Delights',
          status: localizations.translate('active'),
          actionLabel: localizations.translate('view_details'),
          localizations: localizations,
        ),
      ],
    );
  }

  Widget _completedTab(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DeliveryCard(
          title: 'Downtown Cafe → Emma Davis', 
          status: localizations.translate('completed'),
          localizations: localizations,
        ),
      ],
    );
  }
}

// ---------------- UI COMPONENTS ----------------

class _TabLabel extends StatelessWidget {
  final String title;
  final int count;

  const _TabLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        children: [
          Text(title),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String title;
  final String? pickup;
  final String? drop;
  final String? status;
  final String? actionLabel;
  final bool showAccept;
  final AppLocalizations localizations;

  const _DeliveryCard({
    required this.title,
    required this.localizations,
    this.pickup,
    this.drop,
    this.status,
    this.actionLabel,
    this.showAccept = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

          if (status != null) ...[
            const SizedBox(height: 6),
            Text(status!, style: const TextStyle(color: AppColors.textLight)),
          ],

          if (pickup != null && drop != null) ...[
            const SizedBox(height: 12),
            Text('${localizations.translate('pickup')}: $pickup'),
            Text('${localizations.translate('delivery_label')}: $drop'),
          ],

          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (!showAccept)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VolunteerOrderDetailPage(),
                          ),
                        );
                      },
                      child: Text(localizations.translate('view_details')),
                    ),
                  ),
                if (showAccept)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
