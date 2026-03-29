import 'alert_controller.dart';
import '../../../data/models/alert_model.dart';

/// Service to handle alert responses from proctors/security
/// This would typically be called from a backend API webhook or real-time listener
class AlertResponseService {
  static Future<void> acceptAlert({
    required String alertId,
    required String respondedByName,
  }) async {
    await AlertController.instance.updateAlertStatus(
      alertId: alertId,
      status: AlertStatus.accepted,
      respondedByName: respondedByName,
    );
  }

  static Future<void> rejectAlert({
    required String alertId,
    required String respondedByName,
  }) async {
    await AlertController.instance.updateAlertStatus(
      alertId: alertId,
      status: AlertStatus.rejected,
      respondedByName: respondedByName,
    );
  }

  /// Simulates receiving a notification from backend about alert acceptance
  /// In a real app, this would be called from a WebSocket, Firebase Cloud Messaging, or other real-time service
  static Future<void> simulateAlertAcceptance({
    required String alertId,
    required String respondedByName,
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    await acceptAlert(alertId: alertId, respondedByName: respondedByName);
  }

  /// Simulates receiving a notification from backend about alert rejection
  static Future<void> simulateAlertRejection({
    required String alertId,
    required String respondedByName,
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    await rejectAlert(alertId: alertId, respondedByName: respondedByName);
  }
}
