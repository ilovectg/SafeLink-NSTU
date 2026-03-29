import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/alert_model.dart';
import '../../core/constants/app_colors.dart';

/// Screen to display all student alerts with pulse locations
class SeePulseScreen extends StatefulWidget {
  const SeePulseScreen({Key? key}) : super(key: key);

  @override
  State<SeePulseScreen> createState() => _SeePulseScreenState();
}

class _SeePulseScreenState extends State<SeePulseScreen> {
  String _filter = 'all'; // all, today, thisWeek

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
        title: Text(
          'Student Pulse Locations',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.white, size: 24),
              onPressed: () => _showDeleteAllConfirmation(context),
              tooltip: 'Delete All Pulse Locations',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.background],
            stops: [0.0, 0.3],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getAlertsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error loading alerts',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No pulse locations found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Students will appear here after setting their pulse location and sending alerts',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Filter alerts with pulse location
            final alertsWithPulse = snapshot.data!.docs
                .map((doc) {
                  try {
                    return AlertModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                    );
                  } catch (e) {
                    print('Error parsing alert: $e');
                    return null;
                  }
                })
                .where(
                  (alert) =>
                      alert != null &&
                      alert.pulseBuilding != null &&
                      alert.pulseBuilding!.isNotEmpty,
                )
                .cast<AlertModel>()
                .toList();

            // Apply time filter
            final filteredAlerts = _applyTimeFilter(alertsWithPulse);

            if (filteredAlerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No pulse locations for $_filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try changing the filter',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            // Sort by most recent first
            filteredAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = filteredAlerts[index];
                return _buildPulseCard(alert);
              },
            );
          },
        ),
      ),
    );
  }

  /// Get alerts stream from proctorial_alerts collection
  Stream<QuerySnapshot> _getAlertsStream() {
    return FirebaseFirestore.instance
        .collection('proctorial_alerts')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots();
  }

  /// Apply time filter to alerts
  List<AlertModel> _applyTimeFilter(List<AlertModel> alerts) {
    final now = DateTime.now();

    switch (_filter) {
      case 'today':
        final todayStart = DateTime(now.year, now.month, now.day);
        return alerts
            .where((alert) => alert.timestamp.isAfter(todayStart))
            .toList();

      case 'thisWeek':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        return alerts
            .where((alert) => alert.timestamp.isAfter(weekStartDate))
            .toList();

      case 'all':
      default:
        return alerts;
    }
  }

  /// Build individual pulse location card
  Widget _buildPulseCard(AlertModel alert) {
    final date =
        '${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year}';
    final time =
        '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAlertDetails(alert),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with student name and status
              Row(
                children: [
                  // Building icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(alert.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: _getStatusColor(alert.status),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Student info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.studentName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${alert.department ?? 'N/A'} • ${alert.session ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 16),

              // Pulse location info
              Row(
                children: [
                  Icon(Icons.business, color: Color(0xFF2D7BF2), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Building',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          alert.pulseBuilding ?? 'N/A',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D7BF2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  // Floor
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.layers, color: Color(0xFF4CAF50), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Floor',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                alert.pulseFloor ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Room
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                alert.pulseRoom ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Message (if available)
              if (alert.pulseMessage != null &&
                  alert.pulseMessage!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF9C27B0).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.message, color: Color(0xFF9C27B0), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9C27B0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              alert.pulseMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 12),

              // Timestamp and GPS location
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '$date at $time',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'GPS: ${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.accepted:
        return Colors.green;
      case AlertStatus.rejected:
        return Colors.red;
      case AlertStatus.pending:
        return Colors.orange;
    }
  }

  /// Show detailed alert information
  void _showAlertDetails(AlertModel alert) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.favorite, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Alert Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Student Name', alert.studentName),
                _buildDetailRow('Phone', alert.studentPhone),
                _buildDetailRow('Email', alert.studentEmail),
                _buildDetailRow('Department', alert.department ?? 'N/A'),
                _buildDetailRow('Session', alert.session ?? 'N/A'),

                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 12),

                Text(
                  'Pulse Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),

                _buildDetailRow('Building', alert.pulseBuilding ?? 'N/A'),
                _buildDetailRow('Floor', alert.pulseFloor ?? 'N/A'),
                _buildDetailRow('Room', alert.pulseRoom ?? 'N/A'),
                if (alert.pulseMessage != null &&
                    alert.pulseMessage!.isNotEmpty)
                  _buildDetailRow('Message', alert.pulseMessage!),

                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 12),

                Text(
                  'GPS Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),

                _buildDetailRow('Latitude', alert.latitude.toString()),
                _buildDetailRow('Longitude', alert.longitude.toString()),
                _buildDetailRow('Address', alert.location),

                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 12),

                _buildDetailRow(
                  'Alert Time',
                  '${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year} ${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                ),
                if (alert.respondedByName != null)
                  _buildDetailRow('Responded By', alert.respondedByName!),
                if (alert.respondedAt != null)
                  _buildDetailRow(
                    'Responded At',
                    '${alert.respondedAt!.day}/${alert.respondedAt!.month}/${alert.respondedAt!.year} ${alert.respondedAt!.hour}:${alert.respondedAt!.minute.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog for deleting all pulse locations
  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Text('Delete All Pulse Locations?'),
            ],
          ),
          content: Text(
            'This will clear all saved pulse location data from alerts. This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAllPulseLocations(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  /// Delete all pulse locations from alerts
  Future<void> _deleteAllPulseLocations(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting pulse locations...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get all alerts with pulse locations
      final alertsSnapshot = await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .get();

      int deletedCount = 0;
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data();
        if (data['pulseBuilding'] != null) {
          await doc.reference.update({
            'pulseBuilding': FieldValue.delete(),
            'pulseFloor': FieldValue.delete(),
            'pulseRoom': FieldValue.delete(),
          });
          deletedCount++;
        }
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount pulse locations deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting pulse locations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
