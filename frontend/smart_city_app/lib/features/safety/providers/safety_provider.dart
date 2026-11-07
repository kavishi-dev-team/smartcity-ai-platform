import 'package:flutter/foundation.dart';

import '../models/air_quality_model.dart';
import '../models/safety_alert_model.dart';
import '../models/safety_issue_model.dart';
import '../services/safety_service.dart';

const _connectionMessage =
    'Could not load data. Check your connection and that the server is running.';

class SafetyProvider extends ChangeNotifier {
  final SafetyService _service;

  SafetyProvider({SafetyService? service})
      : _service = service ?? SafetyService();

  bool _disposed = false;

  // ================= Air quality: latest readings =================
  List<AirQualityReading> readings = [];
  String? _selectedArea;
  bool isLoadingAir = false;
  String? airError;

  AirQualityReading? get selectedReading {
    for (final r in readings) {
      if (r.area == _selectedArea) return r;
    }
    return readings.isEmpty ? null : readings.first;
  }

  // ================= Air quality: history =================
  AirQualityHistory? history;
  String historyPeriod = 'daily';
  bool isLoadingHistory = false;
  String? historyError;
  int _historyRequest = 0;

  Future<void> loadAirQuality() async {
    isLoadingAir = true;
    airError = null;
    _notify();

    try {
      readings = await _service.fetchLatestAirQuality();
      final stillExists = readings.any((r) => r.area == _selectedArea);
      if (!stillExists) {
        _selectedArea = readings.isEmpty ? null : readings.first.area;
      }
    } on ApiException catch (e) {
      airError = e.message;
    } catch (e) {
      debugPrint('AIR QUALITY ERROR: $e');
      airError = _connectionMessage;
    }

    isLoadingAir = false;
    _notify();
  }

  void selectArea(String area) {
    if (area == _selectedArea) return;
    _selectedArea = area;
    history = null;
    historyError = null;
    _notify();
  }

  Future<void> loadHistory({String? period}) async {
    final area = selectedReading?.area;
    if (period != null) historyPeriod = period;

    if (area == null) {
      historyError = 'Select an area first.';
      _notify();
      return;
    }

    final request = ++_historyRequest; // ignore out-of-order responses
    isLoadingHistory = true;
    historyError = null;
    _notify();

    try {
      final result = await _service.fetchAirQualityHistory(area, historyPeriod);
      if (request != _historyRequest) return;
      history = result;
    } on ApiException catch (e) {
      if (request != _historyRequest) return;
      history = null;
      historyError = e.message;
    } catch (e) {
      if (request != _historyRequest) return;
      debugPrint('AIR QUALITY HISTORY ERROR: $e');
      history = null;
      historyError = _connectionMessage;
    }

    isLoadingHistory = false;
    _notify();
  }

  // ================= Safety alerts: list =================
  List<SafetyAlert> alerts = [];
  bool showActiveAlerts = true; // true = Active tab, false = Previous tab
  String? severityFilter; // null = all severities
  bool isLoadingAlerts = false;
  String? alertsError;
  int _alertsRequest = 0;

  Future<void> loadAlerts() async {
    final request = ++_alertsRequest;
    isLoadingAlerts = true;
    alertsError = null;
    _notify();

    try {
      final result = await _service.fetchAlerts(
        isActive: showActiveAlerts,
        severity: severityFilter,
      );
      if (request != _alertsRequest) return;
      alerts = result;
    } on ApiException catch (e) {
      if (request != _alertsRequest) return;
      alerts = [];
      alertsError = e.message;
    } catch (e) {
      if (request != _alertsRequest) return;
      debugPrint('SAFETY ALERTS ERROR: $e');
      alerts = [];
      alertsError = _connectionMessage;
    }

    isLoadingAlerts = false;
    _notify();
  }

  void setAlertsTab(bool active) {
    if (active == showActiveAlerts) return;
    showActiveAlerts = active;
    alerts = [];
    loadAlerts();
  }

  void setSeverityFilter(String? severity) {
    if (severity == severityFilter) return;
    severityFilter = severity;
    alerts = [];
    loadAlerts();
  }

  // ================= Safety alerts: detail =================
  SafetyAlert? alertDetail;
  bool isLoadingDetail = false;
  String? detailError;
  int _detailRequest = 0;

  Future<void> loadAlertDetail(int id) async {
    final request = ++_detailRequest;
    isLoadingDetail = true;
    detailError = null;
    alertDetail = null;
    _notify();

    try {
      final result = await _service.fetchAlertDetail(id);
      if (request != _detailRequest) return;
      alertDetail = result;
    } on ApiException catch (e) {
      if (request != _detailRequest) return;
      detailError = e.message;
    } catch (e) {
      if (request != _detailRequest) return;
      debugPrint('SAFETY ALERT DETAIL ERROR: $e');
      detailError = _connectionMessage;
    }

    isLoadingDetail = false;
    _notify();
  }

  // ================= Safety problems: summary cards =================
  SafetySummary? summary;

  Future<void> loadSummary() async {
    try {
      summary = await _service.fetchSafetySummary();
    } catch (e) {
      // The cards just show "-" if this fails; the list has its own error state.
      debugPrint('SAFETY SUMMARY ERROR: $e');
    }
    _notify();
  }

  // ================= Safety problems: list =================
  static const int problemsPageSize = 10;

  List<SafetyIssue> problems = [];
  int problemsTotal = 0;
  int problemsPage = 1;
  int problemsTotalPages = 1;
  String problemSearch = '';
  String? problemStatus;
  String? problemPriority;
  DateTime? problemDateFrom;
  DateTime? problemDateTo;
  bool isLoadingProblems = false;
  String? problemsError;
  DateTime? problemsUpdatedAt;
  int _problemsRequest = 0;

  bool get hasProblemFilters =>
      problemStatus != null ||
      problemPriority != null ||
      problemDateFrom != null ||
      problemDateTo != null;

  Future<void> loadProblemsScreen() async {
    await Future.wait([loadSummary(), loadProblems()]);
  }

  Future<void> loadProblems() async {
    final request = ++_problemsRequest;
    isLoadingProblems = true;
    problemsError = null;
    _notify();

    try {
      final result = await _service.fetchSafetyIssues(
        search: problemSearch,
        status: problemStatus,
        priority: problemPriority,
        dateFrom: problemDateFrom,
        dateTo: problemDateTo,
        page: problemsPage,
        pageSize: problemsPageSize,
      );
      if (request != _problemsRequest) return;
      problems = result.items;
      problemsTotal = result.total;
      problemsPage = result.page;
      problemsTotalPages = result.totalPages;
      problemsUpdatedAt = DateTime.now();
    } on ApiException catch (e) {
      if (request != _problemsRequest) return;
      problems = [];
      problemsError = e.message;
    } catch (e) {
      if (request != _problemsRequest) return;
      debugPrint('SAFETY PROBLEMS ERROR: $e');
      problems = [];
      problemsError = _connectionMessage;
    }

    isLoadingProblems = false;
    _notify();
  }

  void setProblemSearch(String value) {
    final text = value.trim();
    if (text == problemSearch) return;
    problemSearch = text;
    problemsPage = 1;
    loadProblems();
  }

  void applyProblemFilters({
    String? status,
    String? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    problemStatus = status;
    problemPriority = priority;
    problemDateFrom = dateFrom;
    problemDateTo = dateTo;
    problemsPage = 1;
    loadProblems();
  }

  void clearProblemFilters() => applyProblemFilters();

  void goToProblemsPage(int page) {
    if (page < 1 || page > problemsTotalPages || page == problemsPage) return;
    problemsPage = page;
    loadProblems();
  }

  // ================= Safety problems: detail =================
  SafetyIssueDetail? problemDetail;
  bool isLoadingProblemDetail = false;
  String? problemDetailError;
  int _problemDetailRequest = 0;

  Future<void> loadProblemDetail(int id) async {
    final request = ++_problemDetailRequest;
    isLoadingProblemDetail = true;
    problemDetailError = null;
    problemDetail = null;
    _notify();

    try {
      final result = await _service.fetchSafetyIssueDetail(id);
      if (request != _problemDetailRequest) return;
      problemDetail = result;
    } on ApiException catch (e) {
      if (request != _problemDetailRequest) return;
      problemDetailError = e.message;
    } catch (e) {
      if (request != _problemDetailRequest) return;
      debugPrint('SAFETY PROBLEM DETAIL ERROR: $e');
      problemDetailError = _connectionMessage;
    }

    isLoadingProblemDetail = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
