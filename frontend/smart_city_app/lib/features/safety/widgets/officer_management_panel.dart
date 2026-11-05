import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_issue_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/safety_formatters.dart';
import 'safety_issue_card.dart';

/// "Officer management" card on the complaint details screen:
/// assign department / officer, update status, add a public update, add an internal note.
/// Only show this to officers. The backend refuses everyone else anyway.
class OfficerManagementPanel extends StatefulWidget {
  final SafetyIssueDetail detail;

  const OfficerManagementPanel({super.key, required this.detail});

  @override
  State<OfficerManagementPanel> createState() => _OfficerManagementPanelState();
}

class _OfficerManagementPanelState extends State<OfficerManagementPanel> {
  int? _departmentId;
  int? _officerId;
  late String _status;
  final TextEditingController _publicUpdate = TextEditingController();
  final TextEditingController _internalNote = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintProvider>().loadOfficerData(
            widget.detail.issue.id,
            departmentId: _departmentId,
          );
    });
  }

  void _syncFromDetail() {
    final d = widget.detail;
    _departmentId = d.department?.id;
    _officerId = d.assignment?.assignedTo;
    _status = d.issue.status;
  }

  @override
  void didUpdateWidget(covariant OfficerManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // After a save the screen gets a fresh detail: show what the server now says.
    if (!identical(oldWidget.detail, widget.detail)) {
      _syncFromDetail();
    }
  }

  @override
  void dispose() {
    _publicUpdate.dispose();
    _internalNote.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final provider = context.read<ComplaintProvider>();
    final d = widget.detail;

    final deptChanged = _departmentId != null && _departmentId != d.department?.id;
    final officerChosen = _officerId != null && _officerId != d.assignment?.assignedTo;
    final status = _status != d.issue.status ? _status : null;
    final publicText = _publicUpdate.text.trim();
    final noteText = _internalNote.text.trim();

    if (!deptChanged &&
        !officerChosen &&
        status == null &&
        publicText.isEmpty &&
        noteText.isEmpty) {
      _snack('Nothing to save.');
      return;
    }

    final ok = await provider.saveOfficerChanges(
      issueId: d.issue.id,
      departmentId: (deptChanged || officerChosen) ? _departmentId : null,
      officerId: officerChosen ? _officerId : null,
      status: status,
      publicUpdate: publicText,
      internalNote: noteText,
    );
    if (!mounted) return;
    if (ok) {
      _publicUpdate.clear();
      _internalNote.clear();
      _snack('Changes saved.');
    } else {
      _snack(provider.actionError ?? 'Could not save the changes.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ComplaintProvider>();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Officer management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OFFICERS ONLY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (p.officerAccessDenied)
              const Text(
                'Officer tools are only available when you are logged in as an officer.',
                style: TextStyle(color: AppColors.muted),
              )
            else ...[
              if (p.officerError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    p.officerError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              _departmentField(p),
              const SizedBox(height: 12),
              _officerField(p),
              const SizedBox(height: 12),
              _statusField(),
              const SizedBox(height: 12),
              TextField(
                controller: _publicUpdate,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Update for the citizen',
                  helperText: 'Shown in the status timeline. Sent with a status change.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _internalNote,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Internal note',
                  helperText: 'Staff only. Citizens cannot see this.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: p.isSaving ? null : _save,
                  icon: p.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(p.isSaving ? 'Saving...' : 'Save changes'),
                ),
              ),
              if (p.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Internal notes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                for (final note in p.notes.take(5))
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.note, style: const TextStyle(color: AppColors.text)),
                        const SizedBox(height: 4),
                        Text(
                          '${note.authorName ?? 'Officer'} \u2022 ${formatRelative(note.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _departmentField(ComplaintProvider p) {
    final ids = p.departments.map((d) => d.id).toList();
    final value = ids.contains(_departmentId) ? _departmentId : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('dept-$value-${ids.length}'),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Responsible department',
        prefixIcon: Icon(Icons.apartment_outlined),
      ),
      items: [
        for (final d in p.departments)
          DropdownMenuItem(value: d.id, child: Text(d.name)),
      ],
      onChanged: (id) {
        setState(() {
          _departmentId = id;
          _officerId = null; // officers belong to one department
        });
        if (id != null) p.loadOfficers(id);
      },
    );
  }

  Widget _officerField(ComplaintProvider p) {
    final officers = p.officersFor(_departmentId);
    final ids = officers.map((o) => o.id).toList();
    final value = ids.contains(_officerId) ? _officerId : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('officer-$_departmentId-$value-${ids.length}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Assigned officer',
        prefixIcon: const Icon(Icons.person_outline),
        helperText: _departmentId == null
            ? 'Choose a department first.'
            : (officers.isEmpty ? 'No officers in this department yet.' : null),
      ),
      items: [
        for (final o in officers)
          DropdownMenuItem(
            value: o.id,
            child: Text(
              o.position == null ? o.fullName : '${o.fullName} (${o.position})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: officers.isEmpty ? null : (id) => setState(() => _officerId = id),
    );
  }

  Widget _statusField() {
    return DropdownButtonFormField<String>(
      key: ValueKey('status-${widget.detail.issue.status}'),
      initialValue: _status,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      items: [
        for (final s in safetyStatuses)
          DropdownMenuItem(value: s, child: Text(statusLabel(s))),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _status = value);
      },
    );
  }
}
