enum AlertStatus { pending, accepted, rejected }

class AlertModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentEmail;
  final double latitude;
  final double longitude;
  final String location;
  final String? department;
  final String? session;
  final DateTime timestamp;
  final AlertStatus status;
  final String? respondedByName;
  final DateTime? respondedAt;
  final String? forwardedTo; // null, 'security', or 'proctorial'
  final String? forwardedByName; // Name of the proctor who forwarded the alert
  final DateTime? forwardedAt;
  final bool
  securityAccepted; // Whether Security Body accepted the forwarded alert
  final String?
  securityAcceptedByName; // Name of the security person who accepted
  final DateTime? securityAcceptedAt; // When security accepted the alert
  final bool smsEscalated; // Whether SMS has been sent
  final DateTime? smsEscalatedAt; // When SMS was sent
  final bool callEscalated; // Whether call has been initiated
  final DateTime? callEscalatedAt; // When call was initiated
  final String? pulseBuilding; // Student's saved pulse location building
  final String? pulseFloor; // Student's saved pulse location floor
  final String? pulseRoom; // Student's saved pulse location room
  final String? pulseMessage; // Student's optional message with pulse location

  AlertModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentEmail,
    required this.latitude,
    required this.longitude,
    required this.location,
    this.department,
    this.session,
    required this.timestamp,
    this.status = AlertStatus.pending,
    this.respondedByName,
    this.respondedAt,
    this.forwardedTo,
    this.forwardedByName,
    this.forwardedAt,
    this.securityAccepted = false,
    this.securityAcceptedByName,
    this.securityAcceptedAt,
    this.smsEscalated = false,
    this.smsEscalatedAt,
    this.callEscalated = false,
    this.callEscalatedAt,
    this.pulseBuilding,
    this.pulseFloor,
    this.pulseRoom,
    this.pulseMessage,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] ?? '',
    studentId: json['studentId'] ?? '',
    studentName: json['studentName'] ?? '',
    studentPhone: json['studentPhone'] ?? '',
    studentEmail: json['studentEmail'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    location: json['location'] ?? '',
    department: json['department'],
    session: json['session'],
    timestamp: _parseDateTime(json['timestamp']),
    status: _parseStatus(json['status']),
    respondedByName: json['respondedByName'],
    respondedAt: _parseDateTimeNullable(json['respondedAt']),
    forwardedTo: json['forwardedTo'],
    forwardedByName: json['forwardedByName'],
    forwardedAt: _parseDateTimeNullable(json['forwardedAt']),
    securityAccepted: json['securityAccepted'] ?? false,
    securityAcceptedByName: json['securityAcceptedByName'],
    securityAcceptedAt: _parseDateTimeNullable(json['securityAcceptedAt']),
    smsEscalated: json['smsEscalated'] ?? false,
    smsEscalatedAt: _parseDateTimeNullable(json['smsEscalatedAt']),
    callEscalated: json['callEscalated'] ?? false,
    callEscalatedAt: _parseDateTimeNullable(json['callEscalatedAt']),
    pulseBuilding: json['pulseBuilding'],
    pulseFloor: json['pulseFloor'],
    pulseRoom: json['pulseRoom'],
    pulseMessage: json['pulseMessage'],
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Handle Firestore Timestamp
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Handle Firestore Timestamp
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return null;
    }
  }

  static AlertStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return AlertStatus.accepted;
      case 'rejected':
        return AlertStatus.rejected;
      default:
        return AlertStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentPhone': studentPhone,
    'studentEmail': studentEmail,
    'latitude': latitude,
    'longitude': longitude,
    'location': location,
    'department': department,
    'session': session,
    'timestamp': timestamp.toIso8601String(),
    'status': status.toString().split('.').last,
    'respondedByName': respondedByName,
    'respondedAt': respondedAt?.toIso8601String(),
    'forwardedTo': forwardedTo,
    'forwardedByName': forwardedByName,
    'forwardedAt': forwardedAt?.toIso8601String(),
    'securityAccepted': securityAccepted,
    'securityAcceptedByName': securityAcceptedByName,
    'securityAcceptedAt': securityAcceptedAt?.toIso8601String(),
    'smsEscalated': smsEscalated,
    'smsEscalatedAt': smsEscalatedAt?.toIso8601String(),
    'callEscalated': callEscalated,
    'callEscalatedAt': callEscalatedAt?.toIso8601String(),
    'pulseBuilding': pulseBuilding,
    'pulseFloor': pulseFloor,
    'pulseRoom': pulseRoom,
    'pulseMessage': pulseMessage,
  };

  AlertModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentPhone,
    String? studentEmail,
    double? latitude,
    double? longitude,
    String? location,
    String? department,
    String? session,
    DateTime? timestamp,
    AlertStatus? status,
    String? respondedByName,
    DateTime? respondedAt,
    String? forwardedTo,
    String? forwardedByName,
    DateTime? forwardedAt,
    bool? securityAccepted,
    String? securityAcceptedByName,
    DateTime? securityAcceptedAt,
    bool? smsEscalated,
    DateTime? smsEscalatedAt,
    bool? callEscalated,
    DateTime? callEscalatedAt,
    String? pulseBuilding,
    String? pulseFloor,
    String? pulseRoom,
    String? pulseMessage,
  }) {
    return AlertModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhone: studentPhone ?? this.studentPhone,
      studentEmail: studentEmail ?? this.studentEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      department: department ?? this.department,
      session: session ?? this.session,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      respondedByName: respondedByName ?? this.respondedByName,
      respondedAt: respondedAt ?? this.respondedAt,
      forwardedTo: forwardedTo ?? this.forwardedTo,
      forwardedByName: forwardedByName ?? this.forwardedByName,
      forwardedAt: forwardedAt ?? this.forwardedAt,
      securityAccepted: securityAccepted ?? this.securityAccepted,
      securityAcceptedByName:
          securityAcceptedByName ?? this.securityAcceptedByName,
      securityAcceptedAt: securityAcceptedAt ?? this.securityAcceptedAt,
      smsEscalated: smsEscalated ?? this.smsEscalated,
      smsEscalatedAt: smsEscalatedAt ?? this.smsEscalatedAt,
      callEscalated: callEscalated ?? this.callEscalated,
      callEscalatedAt: callEscalatedAt ?? this.callEscalatedAt,
      pulseBuilding: pulseBuilding ?? this.pulseBuilding,
      pulseFloor: pulseFloor ?? this.pulseFloor,
      pulseRoom: pulseRoom ?? this.pulseRoom,
      pulseMessage: pulseMessage ?? this.pulseMessage,
    );
  }
}
