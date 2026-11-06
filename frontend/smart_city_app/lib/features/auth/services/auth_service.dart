import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  String get _deviceName {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    await _api.post(
      ApiConstants.register,
      auth: false,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'confirm_password': confirmPassword,
        'accept_terms': acceptTerms,
      },
    );
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    await _api.post(
      ApiConstants.verifyEmail,
      auth: false,
      body: {'email': email.trim(), 'code': code.trim()},
    );
  }

  Future<void> resendVerification(String email) async {
    await _api.post(
      ApiConstants.resendVerification,
      auth: false,
      body: {'email': email.trim()},
    );
  }

  /// Logs in and stores the tokens. Throws [ApiException] on failure
  /// (`code == 'email_not_verified'` when the email is not verified yet).
  Future<AuthResponse> login({required String email, required String password}) async {
    final data = await _api.post(
      ApiConstants.login,
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
        'device_name': _deviceName,
      },
    );
    final response = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _api.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<void> logout() async {
    final refreshToken = await _api.tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.post(
          ApiConstants.logout,
          auth: false,
          body: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Even if the server cannot be reached we still sign out locally.
      }
    }
    await _api.tokenStorage.clear();
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      ApiConstants.forgotPassword,
      auth: false,
      body: {'email': email.trim()},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      ApiConstants.resetPassword,
      auth: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<UserModel> fetchCurrentUser() async {
    final data = await _api.get(ApiConstants.me);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> hasStoredSession() async {
    return await _api.tokenStorage.readRefreshToken() != null;
  }
}