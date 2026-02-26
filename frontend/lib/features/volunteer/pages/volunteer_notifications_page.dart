import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../core/localization/app_localizations.dart';

class VolunteerNotificationsPage extends StatefulWidget {
  const VolunteerNotificationsPage({super.key});

  @override
  State<VolunteerNotificationsPage> createState() => _VolunteerNotificationsPageState();
}

class _VolunteerNotificationsPageState extends State<VolunteerNotificationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = authProvider.mongoUser?['_id'];

      if (userId == null) throw Exception("User ID not found");

      final response = await BackendService.getUserNotifications(userId);

      if (mounted) {
        setState(() {
          _notifications = (response['notifications'] as List)
              .cast<Map<String, dynamic>>()
              .map((notification) {
                // Convert backend notification to frontend format
                return {
                  "id": notification['_id'],
                  "title": notification['title'] ?? (AppLocalizations.of(context)!.translate("notification") ?? "Notification"),
                  "message": notification['message'] ?? "",
                  "time": _formatTime(notification['createdAt']),
                  "type": _getNotificationType(notification['type']),
                  "icon": _getNotificationIcon(notification['type']),
                  "color": _getNotificationColor(notification['type']),
                  "isRead": notification['isRead'] ?? false,
                  "data": notification['data'],
                };
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching notifications: $e");
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return AppLocalizations.of(context)?.translate("just_now") ?? "Just now";
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return "${difference.inDays}${AppLocalizations.of(context)?.translate("d_ago") ?? "d ago"}";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}${AppLocalizations.of(context)?.translate("h_ago") ?? "h ago"}";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}${AppLocalizations.of(context)?.translate("m_ago") ?? "m ago"}";
      } else {
        return AppLocalizations.of(context)?.translate("just_now") ?? "Just now";
      }
    } catch (e) {
      return AppLocalizations.of(context)?.translate("just_now") ?? "Just now";
    }
  }

  String _getNotificationType(String? type) {
    switch (type) {
      case "rescue_request":
        return AppLocalizations.of(context)?.translate("rescue") ?? "Rescue";
      case "order_update":
        return AppLocalizations.of(context)?.translate("order") ?? "Order";
      case "emergency":
        return AppLocalizations.of(context)?.translate("alert") ?? "Alert";
      default:
        return AppLocalizations.of(context)?.translate("info") ?? "Info";
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case "rescue_request":
        return Icons.local_shipping_rounded;
      case "order_update":
        return Icons.assignment_rounded;
      case "emergency":
        return Icons.warning_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case "rescue_request":
        return AppColors.primary;
      case "order_update":
        return Colors.blue;
      case "emergency":
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = authProvider.mongoUser?['_id'];

      if (userId != null) {
        await BackendService.markNotificationAsRead(notificationId, userId);
        // Update local state
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
          AppLocalizations.of(context)!.translate("notifications") ?? "Notifications",
          style: GoogleFonts.ebGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.primary,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: const Color(0xFFE67E22).withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppLocalizations.of(context)!.translate("no_notifications_yet") ?? "No notifications yet",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final note = _notifications[index];
                        return _NotificationTile(
                          notification: note,
                          onMarkAsRead: () => _markAsRead(note['id']),
                        );
                      },
                    ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onMarkAsRead;

  const _NotificationTile({
    required this.notification,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] ?? false;

    return GestureDetector(
      onTap: () {
        if (!isRead && onMarkAsRead != null) {
          onMarkAsRead!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: notification['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (notification['type'] as String).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: notification['color'] as Color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        notification['time'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification['title'] as String,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
