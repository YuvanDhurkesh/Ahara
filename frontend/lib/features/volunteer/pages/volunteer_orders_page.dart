import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import 'volunteer_order_detail_page.dart';
import '../../../core/localization/language_provider.dart';

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
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.translate('my_deliveries'),
          style: GoogleFonts.ebGaramond(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
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
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
    );
  }

  // ---------------- TABS ----------------

  Widget _newRequestsTab(AppLocalizations localizations) {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_new_requests') ?? 'No new requests',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_active_deliveries') ?? 'No active deliveries',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_completed_deliveries') ?? 'No completed deliveries',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
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

    final title = listing != null ? Provider.of<LanguageProvider>(context, listen: false).getTranslatedText(context, listing, 'foodName') : 'Delivery';
    final pickup =
        order['pickup']?['addressText'] ?? listing?['pickupAddressText'];
    final drop =
        order['drop']?['addressText'] ?? buyer?['name'] ?? 'Delivery address';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (status != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == localizations.translate('active')
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status!.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: status == localizations.translate('active')
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _AddressRow(
            icon: Icons.location_on_outlined,
            label: localizations.translate('pickup'),
            address: pickup ?? 'N/A',
            color: const Color(0xFFE67E22),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF5F5F5)),
            ),
          ),
          _AddressRow(
            icon: Icons.flag_outlined,
            label: localizations.translate('delivery_label'),
            address: drop ?? 'N/A',
            color: Colors.green,
          ),
          if (showAction) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VolunteerOrderDetailPage(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  localizations.translate('view_details'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final Color color;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE67E22).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFF7ED), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Color(0xFFE67E22), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: volunteerId == null
                  ? null
                  : () => onAccept(orderId, volunteerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                localizations.translate('accept_delivery'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
