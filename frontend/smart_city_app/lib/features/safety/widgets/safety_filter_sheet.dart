import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import 'safety_issue_card.dart';

/// Bottom sheet with status / priority / date range filters.
/// The provider is passed in because a bottom sheet is not under the screen's Provider.
Future<void> showSafetyFilterSheet(BuildContext context, SafetyProvider provider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    builder: (_) => _FilterSheet(provider: provider),
  );
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class _FilterSheet extends StatefulWidget {
  final SafetyProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _status;
  String? _priority;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _status = p.problemStatus;
    _priority = p.problemPriority;
    if (p.problemDateFrom != null && p.problemDateTo != null) {
      _range = DateTimeRange(start: p.problemDateFrom!, end: p.problemDateTo!);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in safetyStatuses)
                  ChoiceChip(
                    label: Text(statusLabel(s)),
                    selected: _status == s,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    onSelected: (selected) =>
                        setState(() => _status = selected ? s : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Priority', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in safetyPriorities)
                  ChoiceChip(
                    label: Text(_capitalize(s)),
                    selected: _priority == s,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    onSelected: (selected) =>
                        setState(() => _priority = selected ? s : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Date reported', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _range == null
                          ? 'Any date'
                          : '${formatShortDate(_range!.start)} - ${formatShortDate(_range!.end)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_range != null)
                  IconButton(
                    tooltip: 'Clear date',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _range = null),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.provider.clearProblemFilters();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.provider.applyProblemFilters(
                        status: _status,
                        priority: _priority,
                        dateFrom: _range?.start,
                        dateTo: _range?.end,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
