import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService;

  DashboardProvider({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService();

  int? _userId;
  int _refreshVersion = 0;

  CitizenDashboard? _citizenDashboard;
  OfficerDashboard? _officerDashboard;

  bool _isLoading = false;
  String? _error;

  int? get currentUserId => _userId;
  int get refreshVersion => _refreshVersion;
  CitizenDashboard? get citizenDashboard => _citizenDashboard;
  OfficerDashboard? get officerDashboard => _officerDashboard;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCitizenDashboard({int? userId}) async {
    if (userId != null && userId != _userId) {
      _userId = userId;
      _citizenDashboard = null;
    } else if (userId != null) {
      _userId = userId;
    }

    if (_userId == null) {
      _citizenDashboard = CitizenDashboard(
        totalReports: 0,
        activeReports: 0,
        resolvedReports: 0,
        recentReports: const [],
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _citizenDashboard =
          await _dashboardService.getCitizenDashboard(_userId!);
      _refreshVersion++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOfficerDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _officerDashboard =
          await _dashboardService.getOfficerDashboard();
      _refreshVersion++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }
}
