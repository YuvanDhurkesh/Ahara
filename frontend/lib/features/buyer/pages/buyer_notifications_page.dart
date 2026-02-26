import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';

class BuyerNotificationsPage extends StatefulWidget {
  const BuyerNotificationsPage({super.key});

  @override
  State<BuyerNotificationsPage> createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
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
                  "title": notification['title'] ?? "Notification",
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
    if (createdAt == null) return "Just now";
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return "Just now";
    }
  }

  String _getNotificationType(String? type) {
    switch (type) {
      case "order_update":
        return "Order";
      case "deal":
        return "Deal";
      case "alert":
        return "Alert";
      case "favorite_added":
        return "Favorite";
      default:
        return "Info";
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case "order_update":
        return Icons.shopping_cart_rounded;
      case "deal":
        return Icons.local_offer_rounded;
      case "alert":
        return Icons.notifications_active_rounded;
      case "favorite_added":
        return Icons.favorite_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case "order_update":
        return AppColors.primary;
      case "deal":
        return Colors.orange;
      case "alert":
        return const Color(0xFF3D3028); // Deep Charcoal (App's TextDark)
      case "favorite_added":
        return const Color(0xFFD81B60); // Vibrant Pinkish-Red (matches favorites)
      default:
        return const Color(0xFF8C8E64); // Olive (App's Secondary)
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No notifications yet",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
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
        // TODO: Handle navigation based on notification data
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notification['color'] as Color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (notification['color'] as Color).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: Colors.white,
                size: 20,
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
                        notification['type'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: notification['color'] as Color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            notification['time'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textLight.withOpacity(0.8),
                      height: 1.4,
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
