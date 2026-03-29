import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertDetailsPage extends StatefulWidget {
  final String alertId;
  final Map<String, dynamic> alertData;

  const AlertDetailsPage({
    required this.alertId,
    required this.alertData,
    super.key,
  });

  @override
  State<AlertDetailsPage> createState() => _AlertDetailsPageState();
}

class _AlertDetailsPageState extends State<AlertDetailsPage> {
  Future<void> _openLatestLocationOnMaps() async {
    try {
      // Get the latest location from Firestore in case the student moved after sending the alert.
      final doc = await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(widget.alertId)
          .get();

      final latest = doc.data() ?? widget.alertData;
      final lat = latest['liveLatitude'] ?? latest['latitude'];
      final lon = latest['liveLongitude'] ?? latest['longitude'];

      if (lat == null || lon == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available for this alert')),
        );
        return;
      }

      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(widget.alertId)
          .snapshots(),
      builder: (context, snapshot) {
        final merged = <String, dynamic>{...widget.alertData};
        final liveData = snapshot.data?.data() as Map<String, dynamic>?;
        if (liveData != null) {
          merged.addAll(liveData);
        }

        final data = merged;
        final currentLat = data['liveLatitude'] ?? data['latitude'];
        final currentLon = data['liveLongitude'] ?? data['longitude'];
        final locationName =
            data['liveLocationName'] ?? data['location'] ?? 'N/A';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Alert Details',
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
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // Status Banner with Gradient
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(data['status']).withOpacity(0.15),
                        _getStatusColor(data['status']).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(data['status']).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(data['status']).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['studentName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ID: ${data['studentId'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  // If forwarded and security accepted, use blue
                                  (data['status'] == 'forwarded' &&
                                          data['securityAccepted'] == true)
                                      ? Colors.blue
                                      : _getStatusColor(data['status']),
                                  (data['status'] == 'forwarded' &&
                                          data['securityAccepted'] == true)
                                      ? Colors.blue.withOpacity(0.8)
                                      : _getStatusColor(
                                          data['status'],
                                        ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (data['status'] == 'forwarded' &&
                                          data['securityAccepted'] == true)
                                      ? Colors.blue.withOpacity(0.4)
                                      : _getStatusColor(
                                          data['status'],
                                        ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              // Show ACCEPTED if forwarded and security accepted
                              (data['status'] == 'forwarded' &&
                                      data['securityAccepted'] == true)
                                  ? 'ACCEPTED'
                                  : (data['status'] ?? 'pending').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Student Information Section
                _buildSection('Student Information', [
                  _buildDetailRow('Name', data['studentName'] ?? 'N/A'),
                  _buildDetailRow('Student ID', data['studentId'] ?? 'N/A'),
                  _buildDetailRow('Phone', data['studentPhone'] ?? 'N/A'),
                  _buildDetailRow('Email', data['studentEmail'] ?? 'N/A'),
                  _buildDetailRow('Department', data['department'] ?? 'N/A'),
                  _buildDetailRow('Session', data['session'] ?? 'N/A'),
                ]),

                // Location Information
                _buildSection('Location Information', [
                  _buildDetailRow('Location Name', locationName),
                  if (currentLat != null && currentLon != null)
                    _buildDetailRow(
                      'GPS Coordinates',
                      '$currentLat, $currentLon',
                    ),
                  if (currentLat != null && currentLon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF2563EB)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4285F4).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openLatestLocationOnMaps,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.map_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'View Location on Google Maps',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),

                // Alert Metadata
                _buildSection('Alert Information', [
                  _buildDetailRow(
                    'Alert Time',
                    _formatTime(data['timestamp'] ?? data['receivedAt']),
                  ),
                  _buildDetailRow('Alert ID', widget.alertId),
                  if (data['respondedByName'] != null)
                    _buildDetailRow('Resolved By', data['respondedByName']),
                  if (data['forwardedByName'] != null)
                    _buildDetailRow('Forwarded By', data['forwardedByName']),
                  if (data['respondedAt'] != null)
                    _buildDetailRow(
                      'Response Time',
                      _formatTime(data['respondedAt']),
                    ),
                  if (data['forwardedAt'] != null)
                    _buildDetailRow(
                      'Forwarded Time',
                      _formatTime(data['forwardedAt']),
                    ),
                  if (data['securityAcceptedByName'] != null)
                    _buildDetailRow(
                      'Accepted By (Security)',
                      data['securityAcceptedByName'],
                    ),
                  if (data['securityAcceptedAt'] != null)
                    _buildDetailRow(
                      'Security Accepted Time',
                      _formatTime(data['securityAcceptedAt']),
                    ),
                  if (data['rejectionReason'] != null)
                    _buildDetailRow(
                      'Rejection Reason',
                      data['rejectionReason'],
                    ),
                ]),

                // Action Buttons
                if (data['status'] == 'pending') ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _resolveAlert(),
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _forwardToSecurityBody(),
                            icon: const Icon(Icons.send),
                            label: const Text('Forward to Security Body'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (data['status'] == 'forwarded' &&
                    data['securityAccepted'] != true) ...[
                  // Security Body Accept Button for forwarded alerts
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptBySecurityBody(),
                        icon: const Icon(Icons.verified),
                        label: const Text('Accept (Security Body)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Status: ${(data['status'] ?? 'unknown').toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2386DC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6EB9F9), Color(0xFF2386DC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6EB9F9).withOpacity(0.05),
                    const Color(0xFF2386DC).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2386DC).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    if (title.contains('Student')) return Icons.person_rounded;
    if (title.contains('Location')) return Icons.location_on_rounded;
    if (title.contains('Alert')) return Icons.warning_rounded;
    return Icons.info_rounded;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2386DC),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'forwarded':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'N/A';
      }
    } else {
      return 'N/A';
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolveAlert() async {
    final proctorName = await _getProctorName();
    if (proctorName == null || proctorName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get proctor information'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(widget.alertId)
          .update({
            'status': 'resolved',
            'respondedByName': proctorName,
            'respondedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert resolved!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _forwardToSecurityBody() async {
    final proctorName = await _getProctorName();
    if (proctorName == null || proctorName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get proctor information'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(widget.alertId)
          .update({
            'status': 'forwarded',
            'forwardedByName': proctorName,
            'forwardedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert forwarded to Security Body!'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _acceptBySecurityBody() async {
    final securityName = await _getSecurityPersonName();
    if (securityName == null || securityName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get security personnel information'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(widget.alertId)
          .update({
            'securityAccepted': true,
            'securityAcceptedByName': securityName,
            'securityAcceptedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert accepted by Security Body!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
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

  Future<String?> _getSecurityPersonName() async {
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
      print('Error getting security person name: $e');
      return null;
    }
  }
}
