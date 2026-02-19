import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import 'volunteer_order_detail_page.dart';

class VolunteerOrdersPage extends StatefulWidget {
  const VolunteerOrdersPage({super.key});

  @override
  State<VolunteerOrdersPage> createState() => _VolunteerOrdersPageState();
}

class _VolunteerOrdersPageState extends State<VolunteerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final activeOrders = _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      return status == 'volunteer_assigned' ||
          status == 'volunteer_accepted' ||
          status == 'picked_up' ||
          status == 'in_transit';
    }).toList();

    final completedOrders = _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      return status == 'delivered';
    }).toList();

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
                  count: _requests.length,
                ),
                _TabLabel(
                  title: localizations.translate('active'),
                  count: activeOrders.length,
                ),
                _TabLabel(
                  title: localizations.translate('completed'),
                  count: completedOrders.length,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _newRequestsTab(localizations),
                    _activeTab(localizations, activeOrders),
                    _completedTab(localizations, completedOrders),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------- TABS ----------------

  Widget _newRequestsTab(AppLocalizations localizations) {
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          'No requests',
          style: const TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._requests.map(
          (request) => _RequestCard(
            request: request,
            localizations: localizations,
            onAccept: _acceptRequest,
          ),
        ),
      ],
    );
  }

  Widget _activeTab(
    AppLocalizations localizations,
    List<Map<String, dynamic>> orders,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No active deliveries',
          style: const TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...orders.map(
          (order) => _DeliveryCard(
            order: order,
            status: localizations.translate('active'),
            localizations: localizations,
          ),
        ),
      ],
    );
  }

  Widget _completedTab(
    AppLocalizations localizations,
    List<Map<String, dynamic>> orders,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No completed deliveries',
          style: const TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...orders.map(
          (order) => _DeliveryCard(
            order: order,
            status: localizations.translate('completed'),
            localizations: localizations,
            showAction: false,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      if (auth.mongoUser == null && auth.currentUser != null) {
        await auth.refreshMongoUser();
      }
      final volunteerId = auth.mongoUser?['_id'];
      if (volunteerId == null) {
        throw Exception('Volunteer not logged in');
      }

      final requests = await BackendService.getVolunteerRescueRequests(
        volunteerId,
      );
      final orders = await BackendService.getVolunteerOrders(volunteerId);

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String? orderId, String volunteerId) async {
    if (orderId == null) return;
    try {
      await BackendService.acceptRescueRequest(orderId, volunteerId);
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
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
  final Map<String, dynamic> order;
  final String? status;
  final bool showAction;
  final AppLocalizations localizations;

  const _DeliveryCard({
    required this.order,
    required this.localizations,
    this.status,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final listing = order['listingId'] as Map<String, dynamic>?;
    final buyer = order['buyerId'] as Map<String, dynamic>?;
    final seller = order['sellerId'] as Map<String, dynamic>?;

    final title = listing?['foodName'] ?? 'Delivery';
    final pickup =
        order['pickup']?['addressText'] ?? listing?['pickupAddressText'];
    final drop =
        order['drop']?['addressText'] ?? buyer?['name'] ?? 'Delivery address';

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

          if (showAction) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VolunteerOrderDetailPage(order: order),
                        ),
                      );
                    },
                    child: Text(localizations.translate('view_details')),
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

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final AppLocalizations localizations;
  final Future<void> Function(String? orderId, String volunteerId) onAccept;

  const _RequestCard({
    required this.request,
    required this.localizations,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final volunteerId = auth.mongoUser?['_id']?.toString();
    final title = request['title'] ?? localizations.translate('new_requests');
    final message = request['message'] ?? '';
    final orderId = request['data']?['orderId']?.toString();

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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: AppColors.textLight)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: volunteerId == null
                  ? null
                  : () => onAccept(orderId, volunteerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(localizations.translate('accept_delivery')),
            ),
          ),
        ],
      ),
    );
  }
}
