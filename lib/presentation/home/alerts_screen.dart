import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/back_button_widget.dart';
import 'alert_details_page.dart';

class AlertsScreen extends StatefulWidget {
  final String initialFilter;
  final bool isSecurity;
  const AlertsScreen({
    Key? key,
    this.initialFilter = 'All',
    this.isSecurity = false,
  }) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  void _openDetail(String alertId, Map<String, dynamic> alertData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AlertDetailsPage(alertId: alertId, alertData: alertData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true,
        elevation: 0,
        leading: const AppBarBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.shield,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SafeLink - NSTU',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tabs: different tabs for Security Body vs Proctorial Body
            Builder(
              builder: (ctx) {
                if (widget.isSecurity) {
                  // Security Body tabs: All, Pending, Accepted
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab('All'),
                        const SizedBox(width: 8),
                        _buildTab('Pending'),
                        const SizedBox(width: 8),
                        _buildTab('Accepted'),
                      ],
                    ),
                  );
                }

                final showTabs = widget.initialFilter != 'Forwarded';
                if (!showTabs) {
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Forwarded Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTab('All'),
                      const SizedBox(width: 8),
                      _buildTab('Pending'),
                      const SizedBox(width: 8),
                      _buildTab('Resolved'),
                      const SizedBox(width: 8),
                      _buildTab('Forwarded'),
                      const SizedBox(width: 8),
                      _buildTab('Accepted'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('proctorial_alerts')
                    .orderBy('receivedAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            'No alerts found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var alerts = snapshot.data!.docs;

                  // Filter alerts based on view (Security vs Proctorial)
                  if (widget.isSecurity) {
                    // Security Body: only show forwarded alerts
                    alerts = alerts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'forwarded';
                    }).toList();

                    // Apply security-specific filters
                    if (_filter == 'Pending') {
                      alerts = alerts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['securityAccepted'] != true;
                      }).toList();
                    } else if (_filter == 'Accepted') {
                      alerts = alerts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['securityAccepted'] == true;
                      }).toList();
                    }
                    // 'All' shows both pending and accepted
                  } else {
                    // Proctorial Body: apply status filters
                    if (_filter == 'Accepted') {
                      // Show forwarded alerts that have been accepted by Security Body
                      alerts = alerts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'forwarded' &&
                            data['securityAccepted'] == true;
                      }).toList();
                    } else if (_filter != 'All') {
                      String statusFilter = _filter.toLowerCase();
                      alerts = alerts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = _normalizedStatus(data['status']);
                        return status == statusFilter;
                      }).toList();
                    }
                  }

                  if (alerts.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_filter alerts',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alertDoc = alerts[index];
                      final alertData = alertDoc.data() as Map<String, dynamic>;
                      alertData['status'] = _normalizedStatus(
                        alertData['status'],
                      );
                      return _AlertTile(
                        alertId: alertDoc.id,
                        alert: alertData,
                        onTap: () => _openDetail(alertDoc.id, alertData),
                        isSecurity: widget.isSecurity,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizedStatus(dynamic raw) {
    final status = (raw ?? 'pending').toString().toLowerCase();
    if (status == 'resolved' || status == 'forwarded' || status == 'pending') {
      return status;
    }
    // Any unexpected or legacy status (like 'accepted') will be treated as pending
    return 'pending';
  }

  Widget _buildTab(String label) => GestureDetector(
    onTap: () => setState(() => _filter = label),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _filter == label ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _filter == label ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _AlertTile extends StatelessWidget {
  final String alertId;
  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  final bool isSecurity;
  const _AlertTile({
    required this.alertId,
    required this.alert,
    required this.onTap,
    this.isSecurity = false,
  });

  Color _statusColor(String s) {
    final status = s.toLowerCase();
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'forwarded':
        // Check if security accepted for blue color
        if (alert['securityAccepted'] == true) {
          return Colors.blue;
        }
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Unknown';
      }
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = alert['status'] ?? 'pending';
    final location = alert['location'] ?? 'Unknown Location';
    final studentName =
        alert['studentName'] ?? alert['name'] ?? 'Unknown Student';
    final timestamp = alert['timestamp'] ?? alert['receivedAt'];
    final formattedTime = _formatTime(timestamp);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timer, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    // Show who resolved or forwarded
                    if (status == 'resolved' &&
                        alert['respondedByName'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Resolved by ${alert['respondedByName']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (status == 'forwarded') ...[
                      if (alert['forwardedByName'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Forwarded by ${alert['forwardedByName']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (alert['securityAccepted'] == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Accepted by Security Body',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status badge - different logic for Security Body
              if (isSecurity)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (alert['securityAccepted'] == true
                                ? Colors.blue
                                : Colors.orange)
                            .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    alert['securityAccepted'] == true ? 'ACCEPTED' : 'PENDING',
                    style: TextStyle(
                      color: alert['securityAccepted'] == true
                          ? Colors.blue
                          : Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    // Show ACCEPTED if forwarded and security accepted
                    (status == 'forwarded' && alert['securityAccepted'] == true)
                        ? 'ACCEPTED'
                        : status.toString().toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
