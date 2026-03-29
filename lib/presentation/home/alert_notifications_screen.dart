import 'package:flutter/material.dart';
import 'controllers/alert_controller.dart';
import 'notification_details_page.dart';
import '../../data/models/alert_model.dart';

class AlertNotificationsScreen extends StatefulWidget {
  const AlertNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AlertNotificationsScreen> createState() => _AlertNotificationsScreenState();
}

class _AlertNotificationsScreenState extends State<AlertNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read after first frame to avoid notify during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlertController.instance.markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Alert Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6EB9F9).withOpacity(0.95),
                const Color(0xFF2386DC).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Clear all notifications',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Notifications'),
                      content: const Text('Are you sure you want to delete all notifications?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await AlertController.instance.clearAllNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications cleared'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AlertController.instance,
        builder: (context, child) {
          final notifications = AlertController.instance.notifications;
          
          if (notifications.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6EB9F9).withOpacity(0.05),
                    const Color(0xFF2386DC).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2386DC).withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'ll be notified when security\nresponds to your alerts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final alert = AlertController.instance.getAlertById(notification.alertId);
              return NotificationCard(
                notification: notification,
                alert: alert,
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AlertNotification notification;
  final AlertModel? alert;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.alert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status color and icon based on notification type
    late Color statusColor;
    late IconData statusIcon;
    late List<Color> statusGradient;
    
    if (notification.respondedByName.contains('SafeLink') == true) {
      // Alert sent notification
      statusColor = const Color(0xFF2196F3); // Blue
      statusIcon = Icons.check_rounded;
      statusGradient = [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
    } else if (notification.status == AlertStatus.accepted) {
      // Proctor accepted
      statusColor = const Color(0xFF4CAF50); // Green
      statusIcon = Icons.check_circle_rounded;
      statusGradient = [const Color(0xFF66BB6A), const Color(0xFF43A047)];
    } else if (notification.status == AlertStatus.rejected) {
      // Proctor rejected
      statusColor = const Color(0xFFFF5252); // Red
      statusIcon = Icons.cancel_rounded;
      statusGradient = [const Color(0xFFFF6B6B), const Color(0xFFEE5A52)];
    } else {
      // Default
      statusColor = const Color(0xFFFF9800); // Orange
      statusIcon = Icons.info_rounded;
      statusGradient = [const Color(0xFFFFB74D), const Color(0xFFFFA726)];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Open simplified notification details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailsPage(
                  notification: notification,
                  alert: alert,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: statusColor,
                    width: 5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: statusGradient),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(statusIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alert sent successfully',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your alert has been sent to the security team',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 18),
                    
                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 18),
                    
                    // Details Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6EB9F9).withOpacity(0.08),
                            const Color(0xFF2386DC).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2386DC).withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.person_rounded,
                            'Responded by',
                            notification.respondedByName,
                            const Color(0xFF2386DC),
                          ),
                          if (alert != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.location_on_rounded,
                              'Location',
                              alert!.location,
                              const Color(0xFFFF6B6B),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time_rounded,
                            'Time',
                            _formatTime(notification.timestamp),
                            const Color(0xFF4CAF50),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
