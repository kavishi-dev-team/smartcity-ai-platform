import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import 'app_routes.dart';

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

      // TODO(Member 6): replace these two with CitizenDashboardScreen and
      // OfficerDashboardScreen from lib/features/dashboard/screens/.
      case AppRoutes.citizenDashboard:
        page = const _PlaceholderDashboard(title: 'Citizen Dashboard');
        break;
      case AppRoutes.officerDashboard:
        page = const _PlaceholderDashboard(title: 'Officer Dashboard');
        break;

      default:
        page = const SplashScreen();
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}

/// Temporary landing page so the login -> dashboard routing can be tested
/// before the real dashboards (Member 6) exist.
class _PlaceholderDashboard extends StatelessWidget {
  const _PlaceholderDashboard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified_user, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Logged in as ${user?.fullName ?? '-'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Role: ${user?.role.displayName ?? '-'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Sign out',
              outlined: true,
              icon: Icons.logout,
              isLoading: auth.isLoading,
              onPressed: () => auth.logout(),
            ),
          ],
        ),
      ),
    );
  }
}