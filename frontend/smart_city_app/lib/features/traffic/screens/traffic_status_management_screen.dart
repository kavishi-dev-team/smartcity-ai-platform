import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/traffic_issue_model.dart';
import '../models/traffic_officer_model.dart';
import '../services/traffic_service.dart';

/// Officer-only traffic management.
///
/// Until Member 1's shared authentication is connected, a short-lived signed
/// development token is entered manually. All actions are *server-authorized*;
/// opening this page or editing a token field never grants officer permission.
class TrafficStatusManagementScreen extends StatefulWidget {
  final int issueId;
  final TrafficService? service;

  const TrafficStatusManagementScreen({
    super.key,
    required this.issueId,
    this.service,
  });

  @override
  State<TrafficStatusManagementScreen> createState() =>
      _TrafficStatusManagementScreenState();
}

class _TrafficStatusManagementScreenState
    extends State<TrafficStatusManagementScreen> {
  late final TrafficService _service;
  late final bool _ownsService;
  final TextEditingController _tokenInput = TextEditingController();
  final TextEditingController _overrideReason = TextEditingController();
  final TextEditingController _internalNote = TextEditingController();
  final TextEditingController _publicNote = TextEditingController();

  TrafficOfficerIssue? _data;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  int? _departmentId;
  int? _officerId;
  String? _priorityChoice;
  String _reviewDecision = 'keep';
  String _newStatus = 'reported';

  static const _statuses = <String>[
    'reported', 'under_review', 'assigned', 'in_progress', 'resolved', 'rejected',
  ];
  static const _priorities = <String>['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    if (_service.hasOfficerToken) _load();
  }

  @override
  void dispose() {
    _tokenInput.dispose();
    _overrideReason.dispose();
    _internalNote.dispose();
    _publicNote.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getOfficerIssue(widget.issueId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _departmentId = data.departmentId;
        _officerId = data.assignedOfficerId;
        _priorityChoice = data.aiRecommendedPriority ?? data.priority;
        _reviewDecision = data.aiRecommendedPriority == null ? 'override' : 'keep';
        _newStatus = data.status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _submitToken() {
    final value = _tokenInput.text.trim();
    if (value.isEmpty) {
      _showMessage('Enter an officer access token first.');
      return;
    }
    _service.setOfficerToken(value);
    _tokenInput.clear();
    _load();
  }

  void _signOut() {
    _service.clearOfficerToken();
    setState(() {
      _data = null;
      _error = null;
      _departmentId = null;
      _officerId = null;
    });
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String value, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _save(Future<void> Function() operation, String success, {
    bool clearNotes = false,
    bool clearReason = false,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await operation();
      if (!mounted) return;
      if (clearNotes) {
        _internalNote.clear();
        _publicNote.clear();
      }
      if (clearReason) _overrideReason.clear();
      _showMessage(success, isError: false);
      await _load();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignDepartment() async {
    final data = _data;
    final target = _departmentId;
    if (data == null || target == null) return;
    if (target == data.departmentId) {
      _showMessage('This department is already assigned.');
      return;
    }
    final name = data.departments.where((d) => d.id == target).first.name;
    if (!await _confirm('Confirm department assignment',
        'Assign report #${data.id} to $name? The previous officer assignment will be cleared.')) {
      return;
    }
    await _save(() => _service.assignTrafficDepartment(data.id, target),
        'Department assigned successfully.');
  }

  Future<void> _assignOfficer() async {
    final data = _data;
    final target = _officerId;
    if (data == null || target == null) return;
    if (_departmentId != data.departmentId) {
      _showMessage('Confirm the department change before assigning an officer.');
      return;
    }
    if (target == data.assignedOfficerId) {
      _showMessage('This officer is already assigned.');
      return;
    }
    final name = data.officers.where((o) => o.id == target).first.name;
    if (!await _confirm('Confirm officer assignment',
        'Assign $name to report #${data.id}?')) {
      return;
    }
    await _save(() => _service.assignTrafficOfficer(data.id, target),
        'Officer assigned successfully.');
  }

  Future<void> _reviewPriority() async {
    final data = _data;
    if (data == null) return;
    if (_reviewDecision == 'keep' && data.aiRecommendedPriority == null) {
      _showMessage('There is no AI recommendation for this report.');
      return;
    }
    if (_reviewDecision == 'override') {
      if (_priorityChoice == null || _overrideReason.text.trim().isEmpty) {
        _showMessage('Select a new priority and enter an override reason.');
        return;
      }
      if (_priorityChoice == data.priority) {
        _showMessage('Select a priority different from the current value.');
        return;
      }
    }
    final message = _reviewDecision == 'keep'
        ? 'Keep the AI-recommended ${trafficLabel(data.aiRecommendedPriority!)} priority?'
        : 'Override the current priority to ${trafficLabel(_priorityChoice!)}? Your reason will be recorded.';
    if (!await _confirm('Confirm priority review', message)) return;
    await _save(() => _service.reviewTrafficPriority(
          data.id,
          decision: _reviewDecision,
          priority: _reviewDecision == 'override' ? _priorityChoice : null,
          reason: _reviewDecision == 'override' ? _overrideReason.text.trim() : null,
        ), 'Priority review saved.', clearReason: true);
  }

  Future<void> _saveUpdate() async {
    final data = _data;
    if (data == null) return;
    final changed = _newStatus != data.status;
    final internal = _internalNote.text.trim();
    final publicText = _publicNote.text.trim();
    if (!changed && internal.isEmpty && publicText.isEmpty) {
      _showMessage('Choose a different status or write an update.');
      return;
    }
    if (!await _confirm('Save traffic report update',
        'Status: ${_statusLabel(_newStatus)}. '
        '${internal.isNotEmpty ? "Internal note will be officer-only. " : ""}'
        '${publicText.isNotEmpty ? "Public update will be visible to citizens." : ""}')) {
      return;
    }
    await _save(() => _service.saveTrafficOfficerUpdate(
          data.id,
          status: _newStatus,
          internalNote: internal,
          publicUpdate: publicText,
        ), 'Traffic report updated.', clearNotes: true);
  }

  String _statusLabel(String value) =>
      value == 'reported' ? 'Submitted' : trafficLabel(value);

  Widget _card(String title, IconData icon, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700))),
              ]),
              const Divider(height: 22),
              ...children,
            ],
          ),
        ),
      );

  Widget _optionField({
    required String label,
    required int? value,
    required List<OfficerChoice> choices,
    required ValueChanged<int?> onChanged,
    String? hint,
  }) => DropdownButtonFormField<int>(
        key: ValueKey('officer-option-$label-${value ?? 'none'}-${choices.length}'),
        initialValue: choices.any((c) => c.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(),
            helperText: hint),
        items: [for (final c in choices)
          DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: _saving ? null : onChanged,
      );

  Widget _accessScreen() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    color: AppColors.primary, size: 52),
                const SizedBox(height: 12),
                Text('Officer Access', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('Officer permissions are checked by the FastAPI backend and MySQL user role.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text('DEVELOPMENT ONLY: Until shared login is integrated, paste a short-lived signed token from the local test helper. Never paste or store production tokens in source code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('traffic-officer-token'),
                  controller: _tokenInput,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Officer access token',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  onSubmitted: (_) => _submitToken(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('traffic-officer-sign-in'),
                  onPressed: _submitToken,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Verify officer access'),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _content(TrafficOfficerIssue data) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            children: [
              _card('Report overview', Icons.fact_check_outlined, [
                Text(data.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                Text('Report #${data.id}   •   ${data.description}',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 11),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  Chip(label: Text('Status: ${_statusLabel(data.status)}')),
                  Chip(label: Text('Priority: ${trafficLabel(data.priority)}')),
                ]),
              ]),
              _card('Assign department', Icons.apartment_outlined, [
                Text('Current: ${data.departmentName ?? "Not assigned"}',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 13),
                _optionField(label: 'Select department', value: _departmentId,
                    choices: data.departments,
                    onChanged: (value) => setState(() {
                      _departmentId = value;
                      _officerId = null;
                    })),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: FilledButton.icon(
                  key: const Key('traffic-assign-department'),
                  onPressed: _saving || _departmentId == null ? null : _assignDepartment,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm department'),
                )),
              ]),
              _card('Assign officer', Icons.badge_outlined, [
                Text('Current: ${data.assignedOfficerName ?? "No officer assigned"}',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 13),
                _optionField(label: 'Select officer', value: _officerId,
                    choices: data.officers,
                    hint: data.departmentId == null
                        ? 'Assign a department first'
                        : data.officers.isEmpty ? 'No active officer members in this department' : null,
                    onChanged: (value) => setState(() => _officerId = value)),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: FilledButton.icon(
                  key: const Key('traffic-assign-officer'),
                  onPressed: _saving || _officerId == null ? null : _assignOfficer,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Confirm officer'),
                )),
              ]),
              _card('Review AI priority', Icons.auto_awesome_outlined, [
                Text(data.aiRecommendedPriority == null
                    ? 'No AI recommendation available. Manual review is still possible.'
                    : 'AI recommendation: ${trafficLabel(data.aiRecommendedPriority!)}',
                    style: const TextStyle(color: AppColors.muted)),
                if (data.latestPriorityReview != null) ...[
                  const SizedBox(height: 7),
                  Text('Last review: ${trafficLabel(data.latestPriorityReview!.reviewStatus)} '
                      '→ ${trafficLabel(data.latestPriorityReview!.finalPriority)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'keep',
                      enabled: data.aiRecommendedPriority != null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Keep AI'),
                    ),
                    const ButtonSegment<String>(
                      value: 'override',
                      icon: Icon(Icons.tune_outlined),
                      label: Text('Override'),
                    ),
                  ],
                  selected: {_reviewDecision},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) => setState(() => _reviewDecision = selection.first),
                ),
                const SizedBox(height: 12),
                if (_reviewDecision == 'override') ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('officer-priority-${_priorityChoice ?? 'none'}'),
                    initialValue: _priorities.contains(_priorityChoice) ? _priorityChoice : null,
                    decoration: const InputDecoration(
                      labelText: 'New priority', border: OutlineInputBorder()),
                    items: [for (final p in _priorities)
                      DropdownMenuItem(value: p, child: Text(trafficLabel(p)))],
                    onChanged: _saving ? null : (v) => setState(() => _priorityChoice = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('traffic-priority-reason'),
                    controller: _overrideReason,
                    decoration: const InputDecoration(
                      labelText: 'Reason for override (required)',
                      border: OutlineInputBorder()),
                    minLines: 2, maxLines: 3, maxLength: 1000,
                  ),
                ],
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: FilledButton.icon(
                  key: const Key('traffic-review-priority'),
                  onPressed: _saving ? null : _reviewPriority,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Confirm priority review'),
                )),
              ]),
              _card('Update status & notes', Icons.edit_note_outlined, [
                DropdownButtonFormField<String>(
                  key: ValueKey('traffic-new-status-$_newStatus'),
                  initialValue: _statuses.contains(_newStatus) ? _newStatus : 'reported',
                  decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                  items: [for (final s in _statuses)
                    DropdownMenuItem(value: s, child: Text(_statusLabel(s)))],
                  onChanged: _saving ? null : (v) => setState(() => _newStatus = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('traffic-internal-note'),
                  controller: _internalNote,
                  maxLength: 3000, minLines: 2, maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Internal note (officers only)',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    helperText: 'Never displayed to citizens',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('traffic-public-update'),
                  controller: _publicNote,
                  maxLength: 3000, minLines: 2, maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Citizen-visible update',
                    prefixIcon: Icon(Icons.public),
                    border: OutlineInputBorder(),
                    helperText: 'Also appears in the public status timeline',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('traffic-save-status'),
                  onPressed: _saving ? null : _saveUpdate,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save update'),
                ),
              ]),
              _card('Recent officer notes & public updates', Icons.history, [
                if (data.notes.isEmpty)
                  const Text('No updates recorded yet.',
                      style: TextStyle(color: AppColors.muted)),
                for (final note in data.notes) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(note.visibility == 'internal'
                        ? Icons.lock_outline : Icons.public,
                        color: note.visibility == 'internal'
                            ? AppColors.warning : AppColors.success),
                    title: Text(note.comment),
                    subtitle: Text('${note.authorName} • ${trafficLabel(note.visibility)} • '
                        '${trafficDate(note.createdAt)}'),
                  ),
                  const Divider(height: 1),
                ],
              ]),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Traffic Officer Management'),
          actions: [
            if (_service.hasOfficerToken) ...[
              IconButton(
                tooltip: 'Refresh officer data',
                onPressed: _saving ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Sign out of officer tools',
                onPressed: _saving ? null : _signOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ],
        ),
        body: Stack(children: [
          if (!_service.hasOfficerToken)
            _accessScreen()
          else if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 46, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 15),
                Wrap(spacing: 12, children: [
                  OutlinedButton(onPressed: _signOut, child: const Text('Change access token')),
                  FilledButton(onPressed: _load, child: const Text('Try again')),
                ]),
              ]),
            ))
          else if (_data != null)
            _content(_data!),
          if (_saving)
            const Positioned.fill(child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            )),
        ]),
      );
}
