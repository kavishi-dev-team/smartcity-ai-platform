import 'package:flutter/material.dart';

import '../../app.dart';
import '../../features/ai/screens/ai_analysis_results_screen.dart';
import '../../features/ai/screens/ai_assistant_chat_screen.dart';
import '../../features/ai/screens/ai_prioritized_issues_screen.dart';
import '../../features/ai/screens/complaint_clusters_screen.dart';
import '../../features/analytics/screens/analytics_statistics_screen.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/dashboard/screens/citizen_dashboard_screen.dart';
import '../../features/dashboard/screens/officer_dashboard_screen.dart';
import '../../features/energy_water/screens/energy_problems_screen.dart';
import '../../features/energy_water/screens/energy_water_report_screen.dart';
import '../../features/energy_water/screens/energy_water_statistics_screen.dart';
import '../../features/energy_water/screens/water_leakage_map_screen.dart';
import '../../features/energy_water/screens/water_leakage_reports_screen.dart';
import '../../features/energy_water/screens/water_problems_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reporting/screens/my_reports_screen.dart';
import '../../features/reporting/screens/report_problem_screen.dart';
import '../../features/safety/screens/air_quality_screen.dart';
import '../../features/safety/screens/complaint_history_screen.dart';
import '../../features/safety/screens/safety_alerts_screen.dart';
import '../../features/safety/screens/safety_problems_screen.dart';
import '../../features/traffic/screens/department_information_screen.dart';
import '../../features/traffic/screens/traffic_incident_map_screen.dart';
import '../../features/traffic/screens/traffic_problems_screen.dart';
import '../../features/waste/screens/collection_information_screen.dart';
import '../../features/waste/screens/recycling_information_screen.dart';
import '../../features/waste/screens/waste_problems_screen.dart';
import '../../features/waste/screens/waste_separation_guide_screen.dart';
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
    final email =
        settings.arguments is String ? settings.arguments as String : '';

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
      case AppRoutes.citizenDashboard:
        page = const CitizenDashboardScreen();
        break;
      case AppRoutes.officerDashboard:
        page = const OfficerDashboardScreen();
        break;
      case AppRoutes.reportProblem:
        page = const ReportProblemScreen();
        break;
      case AppRoutes.myReports:
        page = const MyReportsScreen();
        break;
      case AppRoutes.waste:
        page = const WasteProblemsScreen();
        break;
      case AppRoutes.wasteCollection:
        page = const CollectionInformationScreen();
        break;
      case AppRoutes.wasteSeparation:
        page = const WasteSeparationGuideScreen();
        break;
      case AppRoutes.wasteRecycling:
        page = const RecyclingInformationScreen();
        break;
      case AppRoutes.energyWaterHub:
        page = const EnergyWaterDashboardMenu();
        break;
      case AppRoutes.energyProblems:
        page = const EnergyProblemsScreen();
        break;
      case AppRoutes.waterProblems:
        page = const WaterProblemsScreen();
        break;
      case AppRoutes.waterLeakage:
        page = const WaterLeakageReportsScreen();
        break;
      case AppRoutes.waterLeakageMap:
        page = const WaterLeakageMapScreen();
        break;
      case AppRoutes.energyWaterStats:
        page = const EnergyWaterStatisticsScreen();
        break;
      case AppRoutes.energyWaterReport:
        page = const EnergyWaterReportScreen();
        break;
      case AppRoutes.traffic:
        page = const TrafficProblemsScreen();
        break;
      case AppRoutes.trafficMap:
        page = const TrafficIncidentMapScreen();
        break;
      case AppRoutes.departments:
        page = const DepartmentInformationScreen();
        break;
      case AppRoutes.safety:
        page = const SafetyProblemsScreen();
        break;
      case AppRoutes.safetyAlerts:
        page = const SafetyAlertsScreen();
        break;
      case AppRoutes.complaints:
        page = const ComplaintHistoryScreen();
        break;
      case AppRoutes.airQuality:
        page = const AirQualityScreen();
        break;
      case AppRoutes.aiChat:
        page = const AIAssistantChatScreen();
        break;
      case AppRoutes.aiPrioritizedIssues:
        page = const AIPrioritizedIssuesScreen();
        break;
      case AppRoutes.aiClusters:
        page = const ComplaintClustersScreen();
        break;
      case AppRoutes.aiAnalysis:
        page = const AIAnalysisResultsScreen();
        break;
      case AppRoutes.analytics:
        page = const AnalyticsStatisticsScreen();
        break;
      case AppRoutes.notifications:
        page = const NotificationsScreen();
        break;
      case AppRoutes.profile:
        page = const ProfileScreen();
        break;
      default:
        page = const SplashScreen();
    }

    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
