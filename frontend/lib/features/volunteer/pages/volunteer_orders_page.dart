import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/order_service.dart';
import 'volunteer_order_detail_page.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Deliveries',
          style: TextStyle(
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
              tabs: const [
                _TabLabel(title: 'New Requests', count: 1),
                _TabLabel(title: 'Active', count: 1),
                _TabLabel(title: 'Completed', count: 1),
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
            children: [_newRequestsTab(), _activeTab(), _completedTab()],
          ),
        ),
      ),
    );
  }

  // ---------------- TABS ----------------

  // ---------------- TABS ----------------

  Widget _newRequestsTab() {
    return FutureBuilder<List<dynamic>>(
      future: OrderService().getOpenOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('No new requests'));
        }
        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _DeliveryCard(
                title: 'Order #${order['_id'].substring(0, 6)}',
                pickup: 'Store Address (TODO)', // Store address might need to be fetched
                drop: order['deliveryAddress'] ?? 'Unknown',
                actionLabel: 'Accept Delivery',
                showAccept: true,
                onAccept: () async {
                  try {
                    final user = context.read<AppAuthProvider>().currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You need to be logged in')),
                      );
                      return;
                    }
                    await OrderService().acceptOrder(order['_id'], user.uid);
                    setState(() {}); // Refresh list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
              );
            });
      },
    );
  }

  Widget _activeTab() {
    final user = context.read<AppAuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view active orders"));
    }
    return FutureBuilder<List<dynamic>>(
      future: OrderService().getUserOrders(user.uid, 'volunteer'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders =
            (snapshot.data ?? []).where((o) => o['status'] == 'ACCEPTED').toList();
        if (orders.isEmpty) {
          return const Center(child: Text('No active orders'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _DeliveryCard(
              title: 'Order #${order['_id'].substring(0, 6)}',
              status: order['status'],
              pickup: 'Store Address', 
              drop: order['deliveryAddress'],
              actionLabel: 'View Details',
            );
          },
        );
      },
    );
  }

  Widget _completedTab() {
    final user = context.read<AppAuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view completed orders"));
    }
    return FutureBuilder<List<dynamic>>(
      future: OrderService().getUserOrders(user.uid, 'volunteer'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders =
            (snapshot.data ?? []).where((o) => o['status'] == 'COMPLETED').toList();
        if (orders.isEmpty) {
          return const Center(child: Text('No completed orders'));
        }
         return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _DeliveryCard(
              title: 'Order #${order['_id'].substring(0, 6)}',
              status: order['status'],
              // pickup: 'Store Address', // Optional for completed
              // drop: order['deliveryAddress'],
            );
          },
        );
      },
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
  final VoidCallback? onAccept; // New callback

  const _DeliveryCard({
    required this.title,
    this.pickup,
    this.drop,
    this.status,
    this.actionLabel,
    this.showAccept = false,
    this.onAccept,
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
            Text('Pickup: $pickup'),
            Text('Delivery: $drop'),
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
                      child: const Text('View Details'),
                    ),
                  ),
                if (showAccept)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
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
