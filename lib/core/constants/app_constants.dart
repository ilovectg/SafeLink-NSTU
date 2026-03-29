class AppConstants {
  static const int smsDelaySeconds =
      10; // Delay before sending SMS escalation (60 for production)
  static const int callDelaySeconds =
      20; // Delay before call escalation after SMS sent (300 for production = 5 minutes)
  static const int callCountdownSeconds =
      3; // Countdown before initiating calls
  // Add other constants as needed
}
