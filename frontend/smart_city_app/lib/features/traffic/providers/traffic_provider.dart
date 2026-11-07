import 'package:flutter/foundation.dart';

import '../models/traffic_issue_model.dart';
import '../services/traffic_service.dart';

@immutable
class TrafficFilters {
  final String search;
  final String status;
  final String priority;
  final String city;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const TrafficFilters({
    this.search = '',
    this.status = '',
    this.priority = '',
    this.city = '',
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive =>
      status.isNotEmpty || priority.isNotEmpty || city.trim().isNotEmpty ||
      dateFrom != null || dateTo != null;

  TrafficFilters withSearch(String newSearch) => TrafficFilters(
        search: newSearch,
        status: status,
        priority: priority,
        city: city,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
}

class TrafficProvider extends ChangeNotifier {
  final TrafficService service;

  TrafficProvider(this.service);

  static const int pageSize = 20;
  TrafficFilters filters = const TrafficFilters();
  List<TrafficIssue> issues = [];
  int total = 0;
  bool loading = false;
  bool loadingMore = false;
  String? error;
  bool _disposed = false;
  int _requestId = 0;

  bool get hasMore => issues.length < total;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    loading = true;
    loadingMore = false;
    error = null;
    _emit();
    try {
      final page = await service.getIssues(
        search: filters.search,
        status: filters.status,
        priority: filters.priority,
        city: filters.city,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        limit: pageSize,
        offset: 0,
      );
      if (_disposed || requestId != _requestId) return;
      issues = page.items;
      total = page.total;
    } catch (exception) {
      if (_disposed || requestId != _requestId) return;
      error = exception.toString();
      issues = [];
      total = 0;
    } finally {
      if (!_disposed && requestId == _requestId) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final requestId = _requestId;
    loadingMore = true;
    error = null;
    _emit();
    try {
      final page = await service.getIssues(
        search: filters.search,
        status: filters.status,
        priority: filters.priority,
        city: filters.city,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        limit: pageSize,
        offset: issues.length,
      );
      if (_disposed || requestId != _requestId) return;
      issues = [...issues, ...page.items];
      total = page.total;
    } catch (exception) {
      if (_disposed || requestId != _requestId) return;
      error = exception.toString();
    } finally {
      if (!_disposed && requestId == _requestId) {
        loadingMore = false;
        _emit();
      }
    }
  }

  void updateSearch(String value) {
    filters = filters.withSearch(value);
    refresh();
  }

  void applyFilters(TrafficFilters value) {
    filters = value;
    refresh();
  }

  void clearFilters() {
    filters = const TrafficFilters();
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}
