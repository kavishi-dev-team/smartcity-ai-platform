class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static const citizenDashboard = '/dashboard/citizen';
  static const officerDashboard = '/dashboard/officer';

  // Service Hub & Reporting
  static const reportProblem = '/report-issues';
  static const myReports = '/my-reports';

  // City Domain Dashboards
  static const waste = '/waste';
  static const wasteCollection = '/waste/collection';
  static const wasteSeparation = '/waste/separation';
  static const wasteRecycling = '/waste/recycling';

  static const energyWaterHub = '/energy-water';
  static const energyProblems = '/energy/problems';
  static const waterProblems = '/water/problems';
  static const waterLeakage = '/water/leakage';
  static const waterLeakageMap = '/water/leakage-map';
  static const energyWaterStats = '/energy-water/statistics';
  static const energyWaterReport = '/energy-water/report';

  static const traffic = '/traffic';
  static const trafficMap = '/traffic/map';
  static const departments = '/departments';

  static const safety = '/safety';
  static const safetyAlerts = '/safety/alerts';
  static const complaints = '/safety/complaints';
  static const airQuality = '/air-quality';

  // AI, Analytics, Notifications & Profile
  static const aiChat = '/ai/chat';
  static const aiPrioritizedIssues = '/ai/prioritized-issues';
  static const aiClusters = '/ai/clusters';
  static const aiAnalysis = '/ai/analysis';
  static const analytics = '/analytics';
  static const notifications = '/notifications';
  static const profile = '/profile';
}
