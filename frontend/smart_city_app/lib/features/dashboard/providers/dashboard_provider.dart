import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService;

  DashboardProvider({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService();

  final int userId = 1; // Temporary test user ID

  CitizenDashboard? _citizenDashboard;
  OfficerDashboard? _officerDashboard;

  bool _isLoading = false;
  String? _error;

  CitizenDashboard? get citizenDashboard => _citizenDashboard;
  OfficerDashboard? get officerDashboard => _officerDashboard;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCitizenDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _citizenDashboard =
          await _dashboardService.getCitizenDashboard(userId);
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
