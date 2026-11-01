class ApiConstants {
  ApiConstants._();

  // Authentication
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Current user
  static const String me = '/users/me';
  static const String changePassword = '/users/me/password';
  static const String preferences = '/users/me/preferences';
}