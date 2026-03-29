import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alert_details_page.dart';

class ProctorialDashboardScreen extends StatefulWidget {
  const ProctorialDashboardScreen({super.key});

  @override
  State<ProctorialDashboardScreen> createState() =>
      _ProctorialDashboardScreenState();
}

class _ProctorialDashboardScreenState extends State<ProctorialDashboardScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _setupFCMToken();
  }

  Future<void> _setupFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Request notification permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get FCM token
      final token = await messaging.getToken();
      if (token != null) {
        // Save token to user's document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});

        print('✅ FCM Token saved for proctor: ${user.email}');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      });
    } catch (e) {
      print('❌ Error setting up FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667EEA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Color(0xFF667EEA), size: 32),
                      SizedBox(width: 10),
                      Text(
                        'SafeLink Proctorial Dashboard',
                        style: TextStyle(
                          color: Color(0xFF667EEA),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Real-time student emergency alerts monitoring',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Statistics Cards
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('proctorial_alerts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final alerts = snapshot.data!.docs;
                final pending = alerts
                    .where((a) => a['status'] == 'pending')
                    .length;
                final accepted = alerts
                    .where((a) => a['status'] == 'accepted')
                    .length;
                final rejected = alerts
                    .where((a) => a['status'] == 'rejected')
                    .length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'PENDING ALERTS',
                          pending.toString(),
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          'ACCEPTED',
                          accepted.toString(),
                          const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          'REJECTED',
                          rejected.toString(),
                          const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          'TOTAL TODAY',
                          alerts.length.toString(),
                          const Color(0xFF667EEA),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Alerts Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with Refresh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Emergency Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Filter Tabs
                    Row(
                      children: [
                        _buildFilterTab('All', 'all'),
                        const SizedBox(width: 10),
                        _buildFilterTab('Pending', 'pending'),
                        const SizedBox(width: 10),
                        _buildFilterTab('Accepted', 'accepted'),
                        const SizedBox(width: 10),
                        _buildFilterTab('Rejected', 'rejected'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Alerts List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('proctorial_alerts')
                            .orderBy('receivedAt', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF667EEA),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
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

                          // Filter alerts
                          if (_filter != 'all') {
                            alerts = alerts.where((doc) {
                              return doc['status'] == _filter;
                            }).toList();
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
                              final data =
                                  alertDoc.data() as Map<String, dynamic>;
                              return _buildAlertCard(alertDoc.id, data);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF667EEA) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? Colors.white : Colors.black,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(String alertId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    Color borderColor;
    Color bgColor;

    switch (status) {
      case 'resolved':
        borderColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFF0FDF4);
        break;
      case 'forwarded':
        borderColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFFBEB);
        break;
      default:
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AlertDetailsPage(alertId: alertId, alertData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['studentName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: ${data['studentId'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${data['department'] ?? 'N/A'} • ${data['session'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.phone,
                    'Phone',
                    data['studentPhone'] ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.email,
                    'Email',
                    data['studentEmail'] ?? 'N/A',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.location_on,
                    'Location',
                    data['location'] ?? 'Unknown',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time,
                    'Time',
                    _formatTime(data['timestamp'] ?? data['receivedAt']),
                  ),
                ),
              ],
            ),

            // Actions
            if (status == 'pending') ...[
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptAlert(alertId, data),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept & Respond'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectAlert(alertId),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openMap(data['latitude'], data['longitude']),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Divider(height: 30),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openMap(data['latitude'], data['longitude']),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (status == 'resolved' && data['respondedByName'] != null)
                    Expanded(
                      child: Text(
                        'Resolved by ${data['respondedByName']}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (status == 'forwarded' &&
                      data['forwardedByName'] != null)
                    Expanded(
                      child: Text(
                        'Forwarded by ${data['forwardedByName']}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (data['respondedByName'] != null)
                    Expanded(
                      child: Text(
                        'Handled by ${data['respondedByName']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
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

  Future<void> _acceptAlert(String alertId, Map<String, dynamic> data) async {
    final proctorName = await _getProctorName();
    if (proctorName == null) return;

    try {
      // Update proctorial_alerts
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .update({
            'status': 'accepted',
            'respondedByName': proctorName,
            'respondedAt': FieldValue.serverTimestamp(),
          });

      // Update student's personal alert
      if (data['userId'] != null) {
        final studentAlertsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .collection('alerts')
            .where('id', isEqualTo: data['id'])
            .limit(1)
            .get();

        if (studentAlertsSnapshot.docs.isNotEmpty) {
          await studentAlertsSnapshot.docs.first.reference.update({
            'status': 'accepted',
            'respondedByName': proctorName,
            'respondedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Create notification in student's Firestore collection
      if (data['userId'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .collection('notifications')
            .add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'alertId': data['id'],
              'status': 'accepted',
              'respondedByName': proctorName,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
        print(
          '✅ Notification created in Firestore for student ${data['userId']}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert accepted! Student will be notified.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectAlert(String alertId) async {
    final proctorName = await _getProctorName();
    if (proctorName == null) return;

    final reason = await _getRejectReason();
    if (reason == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .update({
            'status': 'rejected',
            'respondedByName': proctorName,
            'respondedAt': FieldValue.serverTimestamp(),
            'rejectionReason': reason,
          });

      // Create notification in student's Firestore collection (get userId from alert)
      final alertDoc = await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .get();

      if (alertDoc.exists) {
        final userId = alertDoc.data()?['userId'];
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'alertId': alertDoc.data()?['id'],
                'status': 'rejected',
                'respondedByName': proctorName,
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
          print('✅ Notification created in Firestore for student $userId');
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert rejected.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _getProctorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ??
            data?['displayName'] ??
            user.email?.split('@').first;
      }
      return user.email?.split('@').first;
    } catch (e) {
      print('Error getting proctor name: $e');
      return null;
    }
  }

  Future<String?> _getRejectReason() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Reason for Rejection'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter reason'),
            onChanged: (value) => reason = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, reason),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _openMap(dynamic lat, dynamic lon) async {
    if (lat == null || lon == null) return;

    final url = 'https://www.google.com/maps?q=$lat,$lon';
    // Open map in new tab (web only)
    // ignore: avoid_web_libraries_in_flutter
    // For web: window.open(url, '_blank');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map URL: $url'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // You can add clipboard functionality here
          },
        ),
      ),
    );
  }
}
