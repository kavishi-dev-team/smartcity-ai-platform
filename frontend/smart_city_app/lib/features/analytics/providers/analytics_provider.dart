import 'package:flutter/foundation.dart';

import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  AnalyticsOverview? overview;
  IssueAnalytics? issueAnalytics;
  DepartmentAnalyticsResponse? departmentAnalytics;

  bool isLoading = false;
  String? error;

  Future<void> loadAnalytics() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _analyticsService.getOverview(),
        _analyticsService.getIssueAnalytics(),
        _analyticsService.getDepartmentAnalytics(),
      ]);

      overview = results[0] as AnalyticsOverview;
      issueAnalytics = results[1] as IssueAnalytics;
      departmentAnalytics = results[2] as DepartmentAnalyticsResponse;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
