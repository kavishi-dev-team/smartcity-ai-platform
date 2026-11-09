import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum LoginOutcome { success, emailNotVerified, failure }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service, ApiClient api) {
    // If the refresh token is rejected anywhere in the app, drop to login.
    api.onSessionExpired = _handleSessionExpired;
  }

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationCode;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationCode => _verificationCode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleSessionExpired() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by the splash screen: reuse a saved login if there is one.
  Future<void> restoreSession() async {
    try {
      if (await _service.hasStoredSession()) {
        _user = await _service.fetchCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<LoginOutcome> login(String email, String password) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final response = await _service.login(email: email, password: password);
      _user = response.user;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return LoginOutcome.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return e.code == 'email_not_verified'
          ? LoginOutcome.emailNotVerified
          : LoginOutcome.failure;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) {
    return _run(() async {
      _verificationCode = await _service.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        password: password,
        confirmPassword: confirmPassword,
        acceptTerms: acceptTerms,
      );
    });
  }

  Future<bool> verifyEmail(String email, String code) => _run(() async {
        await _service.verifyEmail(email: email, code: code);
        _verificationCode = null;
      });

  Future<bool> resendVerification(String email) => _run(() async {
        _verificationCode = await _service.resendVerification(email);
      });

  Future<bool> forgotPassword(String email) => _run(() async {
        _verificationCode = await _service.forgotPassword(email);
      });

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _run(() async {
      await _service.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _verificationCode = null;
    });
  }

  Future<void> refreshCurrentUser() async {
    try {
      _user = await _service.fetchCurrentUser();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    _setLoading(true);
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  /// Runs an API call, storing the error message when it fails.
  Future<bool> _run(Future<void> Function() action) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await action();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }
}
