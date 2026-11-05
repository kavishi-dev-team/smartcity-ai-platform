import 'package:flutter/material.dart';

import '../models/priority_issue_model.dart';
import '../services/priority_issue_service.dart';

class PriorityIssueProvider extends ChangeNotifier {
  final PriorityIssueService _service = PriorityIssueService();

  List<PriorityIssue> issues = [];

  bool isLoading = false;
  String? error;

  String? selectedPriority;
  String? selectedCategory;
  String? selectedStatus;

  Future<void> loadIssues() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      issues = await _service.getPrioritizedIssues(
        priority: selectedPriority,
        category: selectedCategory,
        status: selectedStatus,
      );
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> applyFilters({
    String? priority,
    String? category,
    String? status,
  }) async {
    selectedPriority = priority;
    selectedCategory = category;
    selectedStatus = status;

    await loadIssues();
  }

  Future<void> clearFilters() async {
    selectedPriority = null;
    selectedCategory = null;
    selectedStatus = null;

    await loadIssues();
  }
}
