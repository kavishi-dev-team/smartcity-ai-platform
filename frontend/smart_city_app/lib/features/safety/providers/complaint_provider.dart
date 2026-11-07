import 'package:flutter/foundation.dart';

import '../models/safety_issue_model.dart';
import '../services/safety_service.dart';

const _connectionMessage =
    'Could not load data. Check your connection and that the server is running.';

/// The tabs of the complaint history screen.
class ComplaintTab {
  final String key;
  final String label;
  final String? status; // value sent to the API (comma separated = several statuses)

  const ComplaintTab(this.key, this.label, this.status);
}

const List<ComplaintTab> complaintTabs = [
  ComplaintTab('all', 'All', null),
  ComplaintTab('reported', 'Submitted', 'reported'),
  ComplaintTab('under_review', 'Under review', 'under_review'),
  ComplaintTab('in_progress', 'In progress', 'assigned,in_progress'),
  ComplaintTab('resolved', 'Resolved', 'resolved'),
  ComplaintTab('rejected', 'Rejected', 'rejected'),
];

class ComplaintProvider extends ChangeNotifier {
  final SafetyService _service;

  ComplaintProvider({SafetyService? service})
      : _service = service ?? SafetyService();

  bool _disposed = false;

  // ================= History: counts + list =================
  static const int pageSize = 10;

  IssueCounts counts = const IssueCounts();
  List<SafetyIssue> complaints = [];
  int total = 0;
  int page = 1;
  int totalPages = 1;
  String tabKey = 'all';
  String search = '';
  DateTime? dateFrom;
  DateTime? dateTo;
  bool isLoading = false;
  String? error;
  int _listRequest = 0;

  ComplaintTab get currentTab =>
      complaintTabs.firstWhere((t) => t.key == tabKey, orElse: () => complaintTabs.first);

  int countFor(String key) {
    switch (key) {
      case 'reported':
        return counts.reported;
      case 'under_review':
        return counts.underReview;
      case 'in_progress':
        return counts.assigned + counts.inProgress;
      case 'resolved':
        return counts.resolved;
      case 'rejected':
        return counts.rejected;
      default:
        return counts.total;
    }
  }

  bool get hasDateFilter => dateFrom != null && dateTo != null;

  Future<void> loadScreen() async {
    await Future.wait([loadCounts(), loadComplaints()]);
  }

  Future<void> loadCounts() async {
    try {
      counts = await _service.fetchIssueCounts(category: 'complaint');
    } catch (e) {
      debugPrint('COMPLAINT COUNTS ERROR: $e'); // tabs just show no numbers
    }
    _notify();
  }

  Future<void> loadComplaints() async {
    final request = ++_listRequest;
    isLoading = true;
    error = null;
    _notify();

    try {
      final result = await _service.fetchSafetyIssues(
        category: 'complaint',
        search: search,
        status: currentTab.status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        pageSize: pageSize,
      );
      if (request != _listRequest) return;
      complaints = result.items;
      total = result.total;
      page = result.page;
      totalPages = result.totalPages;
    } on ApiException catch (e) {
      if (request != _listRequest) return;
      complaints = [];
      error = e.message;
    } catch (e) {
      if (request != _listRequest) return;
      debugPrint('COMPLAINTS ERROR: $e');
      complaints = [];
      error = _connectionMessage;
    }

    isLoading = false;
    _notify();
  }

  void setTab(String key) {
    if (key == tabKey) return;
    tabKey = key;
    page = 1;
    complaints = [];
    loadComplaints();
  }

  void setSearch(String value) {
    final text = value.trim();
    if (text == search) return;
    search = text;
    page = 1;
    loadComplaints();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    dateFrom = from;
    dateTo = to;
    page = 1;
    loadComplaints();
  }

  void goToPage(int newPage) {
    if (newPage < 1 || newPage > totalPages || newPage == page) return;
    page = newPage;
    loadComplaints();
  }

  // ================= Detail =================
  SafetyIssueDetail? detail;
  bool isLoadingDetail = false;
  String? detailError;
  int _detailRequest = 0;

  Future<void> loadDetail(int id) async {
    final request = ++_detailRequest;
    isLoadingDetail = true;
    detailError = null;
    detail = null;
    _notify();

    try {
      final result = await _service.fetchSafetyIssueDetail(id);
      if (request != _detailRequest) return;
      detail = result;
    } on ApiException catch (e) {
      if (request != _detailRequest) return;
      detailError = e.message;
    } catch (e) {
      if (request != _detailRequest) return;
      debugPrint('COMPLAINT DETAIL ERROR: $e');
      detailError = _connectionMessage;
    }

    isLoadingDetail = false;
    _notify();
  }

  // ================= Officer management =================
  List<SafetyDepartment> departments = [];
  final Map<int, List<SafetyOfficer>> _officers = {};
  List<InternalNote> notes = [];
  bool isSaving = false;
  bool officerAccessDenied = false;
  String? officerError; // loading departments / officers / notes
  String? actionError; // saving

  List<SafetyOfficer> officersFor(int? departmentId) =>
      departmentId == null ? const [] : (_officers[departmentId] ?? const []);

  Future<void> loadOfficerData(int issueId, {int? departmentId}) async {
    officerError = null;
    officerAccessDenied = false;
    try {
      departments = await _service.fetchDepartments();
      notes = await _service.fetchInternalNotes(issueId);
      if (departmentId != null) {
        _officers[departmentId] = await _service.fetchOfficers(departmentId);
      }
    } on ApiException catch (e) {
      officerError = e.message;
      officerAccessDenied = e.message.contains('Only officers');
    } catch (e) {
      debugPrint('OFFICER DATA ERROR: $e');
      officerError = _connectionMessage;
    }
    _notify();
  }

  Future<void> loadOfficers(int departmentId) async {
    try {
      _officers[departmentId] = await _service.fetchOfficers(departmentId);
    } catch (e) {
      debugPrint('OFFICERS ERROR: $e');
      _officers[departmentId] = [];
    }
    _notify();
  }

  /// Runs the requested officer actions in order and stops at the first error.
  /// Returns true when everything succeeded. Check [actionError] when it returns false.
  Future<bool> saveOfficerChanges({
    required int issueId,
    int? departmentId,
    int? officerId,
    String? status,
    String? publicUpdate,
    String? internalNote,
  }) async {
    isSaving = true;
    actionError = null;
    _notify();

    var ok = true;
    try {
      if (departmentId != null) {
        detail = await _service.assignIssue(
          issueId,
          departmentId: departmentId,
          officerId: officerId,
        );
      }

      // Assigning an officer can already move the report to "assigned".
      final currentStatus = detail?.issue.status;
      final wantsStatus = status != null && status.isNotEmpty && status != currentStatus;
      final update = (publicUpdate ?? '').trim();

      if (wantsStatus) {
        detail = await _service.updateIssueStatus(
          issueId,
          status, // wantsStatus already checked it is not null
          note: update.isEmpty ? null : update, // the note rides along with the status change
        );
      } else if (update.isNotEmpty) {
        detail = await _service.addPublicUpdate(issueId, update);
      }

      final note = (internalNote ?? '').trim();
      if (note.isNotEmpty) {
        final created = await _service.addInternalNote(issueId, note);
        notes = [created, ...notes];
      }
    } on ApiException catch (e) {
      ok = false;
      actionError = e.message;
    } catch (e) {
      ok = false;
      debugPrint('OFFICER SAVE ERROR: $e');
      actionError = _connectionMessage;
    }

    isSaving = false;
    _notify();
    if (ok) {
      loadCounts(); // statuses may have moved between tabs
    }
    return ok;
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
