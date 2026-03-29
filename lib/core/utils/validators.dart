class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}").hasMatch(email);
  }

  /// At least 6 characters, with at least one lowercase, one uppercase and one digit.
  static bool isSixDigitPassword(String pwd) {
    if (pwd.length < 6) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasDigit = RegExp(r'\d').hasMatch(pwd);
    return hasLower && hasUpper && hasDigit;
  }
}
