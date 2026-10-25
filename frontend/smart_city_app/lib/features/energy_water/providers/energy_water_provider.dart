import 'package:flutter/foundation.dart';

import '../models/energy_issue_model.dart';
import '../models/water_issue_model.dart';
import '../services/energy_water_service.dart';

class EnergyWaterProvider extends ChangeNotifier {
  final EnergyWaterService _service;

  EnergyWaterProvider({EnergyWaterService? service})
      : _service = service ?? EnergyWaterService();

  List<EnergyIssue> _energyIssues = [];
  bool _isLoading = false;
  String? _error;

  String _search = '';
  String? _status;
  String? _priority;

  List<EnergyIssue> get energyIssues => _energyIssues;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get status => _status;
  String? get priority => _priority;

  Future<void> loadEnergyIssues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _energyIssues = await _service.fetchEnergyIssues(
        search: _search,
        status: _status,
        priority: _priority,
      );
    } catch (e) {
      _error = 'Failed to load energy reports';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    loadEnergyIssues();
  }

  void setStatus(String? value) {
    _status = value;
    loadEnergyIssues();
  }

  void setPriority(String? value) {
    _priority = value;
    loadEnergyIssues();
  }

    // ---------- Water ----------
  List<WaterIssue> _waterIssues = [];
  bool _waterLoading = false;
  String? _waterError;
  String _waterSearch = '';
  String? _waterStatus;
  String? _waterPriority;

  List<WaterIssue> get waterIssues => _waterIssues;
  bool get waterLoading => _waterLoading;
  String? get waterError => _waterError;
  String? get waterStatus => _waterStatus;
  String? get waterPriority => _waterPriority;

  Future<void> loadWaterIssues({bool leakageOnly = false}) async {
    _waterLoading = true;
    _waterError = null;
    notifyListeners();

    try {
      _waterIssues = await _service.fetchWaterIssues(
        search: _waterSearch,
        status: _waterStatus,
        priority: _waterPriority,
        leakageOnly: leakageOnly,
      );
    } catch (e) {
      _waterError = 'Failed to load water reports';
    } finally {
      _waterLoading = false;
      notifyListeners();
    }
  }

  void setWaterSearch(String value) {
    _waterSearch = value;
    loadWaterIssues();
  }

  void setWaterStatus(String? value) {
    _waterStatus = value;
    loadWaterIssues();
  }

  void setWaterPriority(String? value) {
    _waterPriority = value;
    loadWaterIssues();
  }

    // ---------- Leakage ----------
  List<WaterIssue> _leakageIssues = [];
  bool _leakageLoading = false;
  String? _leakageError;
  String _leakageSearch = '';
  String? _leakageStatus;
  String? _leakageSeverity;

  List<WaterIssue> get leakageIssues => _leakageIssues;
  bool get leakageLoading => _leakageLoading;
  String? get leakageError => _leakageError;
  String? get leakageStatus => _leakageStatus;
  String? get leakageSeverity => _leakageSeverity;

  Future<void> loadLeakageIssues() async {
    _leakageLoading = true;
    _leakageError = null;
    notifyListeners();

    try {
      // Severity is mapped to priority for now.
      _leakageIssues = await _service.fetchWaterIssues(
        search: _leakageSearch,
        status: _leakageStatus,
        priority: _leakageSeverity,
        leakageOnly: true,
      );
    } catch (e) {
      _leakageError = 'Failed to load leakage reports';
    } finally {
      _leakageLoading = false;
      notifyListeners();
    }
  }

  void setLeakageSearch(String value) {
    _leakageSearch = value;
    loadLeakageIssues();
  }

  void setLeakageStatus(String? value) {
    _leakageStatus = value;
    loadLeakageIssues();
  }

  void setLeakageSeverity(String? value) {
    _leakageSeverity = value;
    loadLeakageIssues();
  }
}