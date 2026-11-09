import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reporting/widgets/issue_location_tracker_card.dart';
import '../../reporting/widgets/quick_issue_report_sheet.dart';
import '../models/safety_issue_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/complaint_card.dart';
import '../widgets/safety_message_view.dart';
import 'complaint_details_screen.dart';

/// Complaint history with status tabs, search and a date filter.
class ComplaintHistoryScreen extends StatelessWidget {
  final bool isOfficer;

  const ComplaintHistoryScreen({super.key, this.isOfficer = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userIsStaff = user?.isStaff ?? false;
    final effectiveOfficer = isOfficer || userIsStaff;
    final reportedBy = (!effectiveOfficer && user != null) ? user.id : null;
    return ChangeNotifierProvider(
      key: ValueKey('complaints-$reportedBy-$effectiveOfficer'),
      create: (_) => ComplaintProvider(reportedBy: reportedBy)..loadScreen(),
      child: _HistoryView(isOfficer: effectiveOfficer),
    );
  }
}

class _HistoryView extends StatefulWidget {
  final bool isOfficer;
  const _HistoryView({required this.isOfficer});

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear (x) button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<ComplaintProvider>().setSearch(value);
    });
  }

  Future<void> _pickDates(ComplaintProvider p) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: p.hasDateFilter
          ? DateTimeRange(start: p.dateFrom!, end: p.dateTo!)
          : null,
    );
    if (picked != null) p.setDateRange(picked.start, picked.end);
  }

  Future<void> _open(SafetyIssue issue) async {
    final provider = context.read<ComplaintProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ComplaintDetailsScreen(issue: issue, isOfficer: widget.isOfficer),
        ),
      ),
    );
    // An officer may have changed the status while the details were open.
    if (mounted) {
      provider.loadComplaints();
      provider.loadCounts();
    }
  }

  void _openComplaintSheet(ComplaintProvider p) {
    QuickIssueReportSheet.show(
      context,
      initialCategory: 'complaint',
      onSubmitted: p.loadScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ComplaintProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complaints'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            tooltip: 'Track Complaint Locations on Map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const DomainLocationTrackerScreen(category: 'complaint'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Submit Complaint',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openComplaintSheet(p),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => p.loadScreen(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openComplaintSheet(p),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Complaint',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          _debounce?.cancel();
                          p.setSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search complaints...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                    p.setSearch('');
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _pickDates(p),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Badge(
                          isLabelVisible: p.hasDateFilter,
                          child: const Icon(
                            Icons.date_range,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.hasDateFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text(
                        '${formatShortDate(p.dateFrom!)} - ${formatShortDate(p.dateTo!)}',
                      ),
                      onDeleted: () => p.setDateRange(null, null),
                    ),
                  ),
                ),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.88, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: complaintTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = complaintTabs[index];
                      final isSelected = p.tabKey == tab.key;
                      return InkWell(
                        onTap: () => p.setTab(tab.key),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.lightBlue.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '${tab.label} (${p.countFor(tab.key)})',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 3,
                child: p.isLoading ? const LinearProgressIndicator() : null,
              ),
              Expanded(child: _buildList(p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ComplaintProvider p) {
    if (p.isLoading && p.complaints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null) {
      return SafetyMessageView(
        icon: Icons.cloud_off,
        message: p.error!,
        actionLabel: 'Try again',
        onAction: () => p.loadScreen(),
      );
    }
    if (p.complaints.isEmpty) {
      return SafetyMessageView(
        icon: Icons.inbox_outlined,
        message: 'No complaints found.',
        actionLabel: 'Submit New Complaint',
        onAction: () => _openComplaintSheet(p),
      );
    }

    return RefreshIndicator(
      onRefresh: p.loadScreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: p.complaints.length + 1,
        itemBuilder: (context, index) {
          if (index == p.complaints.length) return _buildFooter(p);
          final complaint = p.complaints[index];
          return ComplaintCard(issue: complaint, onTap: () => _open(complaint));
        },
      ),
    );
  }

  Widget _buildFooter(ComplaintProvider p) {
    Widget pageButton(String label, bool enabled, VoidCallback onTap) {
      return OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Text(
            'Showing ${p.complaints.length} of ${p.total} complaints',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton('Previous', p.page > 1, () => p.goToPage(p.page - 1)),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${p.page}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              pageButton('Next', p.page < p.totalPages, () => p.goToPage(p.page + 1)),
            ],
          ),
        ],
      ),
    );
  }
}
