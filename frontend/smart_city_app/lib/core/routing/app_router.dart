import 'package:flutter/material.dart';

import '../../features/auth/models/user_model.dart';

import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';

import 'app_routes.dart';
import '../../features/dashboard/screens/citizen_dashboard_screen.dart';
import '../../features/dashboard/screens/officer_dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  /// Role -> dashboard. Citizens get the citizen dashboard; super admins,
  /// city managers and department officers all get the officer dashboard.
  static String homeRouteFor(UserModel user) {
    return user.isCitizen
        ? AppRoutes.citizenDashboard
        : AppRoutes.officerDashboard;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final email = settings.arguments is String ? settings.arguments as String : '';

    final Widget page;
    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
        break;
      case AppRoutes.welcome:
        page = const WelcomeScreen();
        break;
      case AppRoutes.login:
        page = const LoginScreen();
        break;
      case AppRoutes.register:
        page = const RegisterScreen();
        break;
      case AppRoutes.verifyEmail:
        page = EmailVerificationScreen(email: email);
        break;
      case AppRoutes.forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case AppRoutes.resetPassword:
        page = ResetPasswordScreen(email: email);
        break;

  // Citizen Dashboard
case AppRoutes.citizenDashboard:
  page = const CitizenDashboardScreen();
  break;

// Officer Dashboard
case AppRoutes.officerDashboard:
  page = const OfficerDashboardScreen();
  break;

      default:
        page = const SplashScreen();
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}

