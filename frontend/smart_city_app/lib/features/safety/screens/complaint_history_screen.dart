import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_issue_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/complaint_card.dart';
import '../widgets/safety_message_view.dart';
import 'complaint_details_screen.dart';

/// Complaint history with status tabs, search and a date filter.
///
/// Open it from anywhere:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintHistoryScreen()));
///
/// Pass [isOfficer] = true to show the officer tools on the details screen.
/// TODO: read this from Member 1's logged-in user once auth is merged.
class ComplaintHistoryScreen extends StatelessWidget {
  final bool isOfficer;

  const ComplaintHistoryScreen({super.key, this.isOfficer = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComplaintProvider()..loadScreen(),
      child: _HistoryView(isOfficer: isOfficer),
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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => p.loadScreen(),
          ),
        ],
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
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final tab in complaintTabs)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${tab.label} (${p.countFor(tab.key)})'),
                          selected: p.tabKey == tab.key,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          onSelected: (_) => p.setTab(tab.key),
                        ),
                      ),
                  ],
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
      return const SafetyMessageView(
        icon: Icons.inbox_outlined,
        message: 'No complaints found.',
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
